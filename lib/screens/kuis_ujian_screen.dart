import 'dart:async';
import 'package:flutter/material.dart';
import '../data/bank_soal.dart';
import '../core/fsm_controller.dart';
import '../core/storage_service.dart';

class KuisUjianScreen extends StatefulWidget {
  final int pulauId;
  final int tahap;
  const KuisUjianScreen(
      {super.key, required this.pulauId, required this.tahap});

  @override
  State<KuisUjianScreen> createState() => _KuisUjianScreenState();
}

class _KuisUjianScreenState extends State<KuisUjianScreen> {
  final StorageService _storage = StorageService();
  List<Map<String, dynamic>> _soal = [];
  int _index = 0;
  int _nyawa = StorageService.defaultNyawa;
  int _benar = 0;
  String? _feedbackMessage;
  bool _feedbackCorrect = false;
  Timer? _timer;
  Timer? _feedbackTimer;
  int _sisaWaktu = 30;
  bool _answered = false;
  String? _selectedOpsi;
  String? _soalError;
  bool _showResult = false;

  static const _pesanNyawaHabis =
      'Nyawamu habis (0 ❤️)! Yuk baca materi di Menu Belajar atau selesaikan Simulasi Praktik untuk menambah nyawa.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prepareQuiz();
    });
  }

  Future<void> _prepareQuiz() async {
    final nyawa = await _storage.getNyawa();
    if (!mounted) return;
    if (nyawa <= 0) {
      await _showNyawaHabisDialog();
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _nyawa = nyawa);
    _loadSoal();
  }

  Future<void> _showNyawaHabisDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('❤️ Nyawa Habis'),
        content: const Text(_pesanNyawaHabis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _loadSoal() {
    _timer?.cancel();
    _feedbackTimer?.cancel();
    try {
      final questions = BankSoal.getSoalTahap(widget.pulauId, widget.tahap);
      setState(() {
        _soal = questions;
        _soalError =
            questions.isEmpty ? 'Soal untuk tahap ini belum tersedia.' : null;
      });
    } catch (_) {
      setState(() {
        _soal = [];
        _soalError = 'Soal tidak dapat dimuat. Silakan coba lagi.';
      });
    }
    if (_soal.isNotEmpty && _soalError == null) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _sisaWaktu = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_sisaWaktu <= 0) {
        timer.cancel();
        _jawab(null);
      } else {
        setState(() => _sisaWaktu--);
      }
    });
  }

  Future<void> _jawab(String? jawaban) async {
    if (_answered || _showResult || _soal.isEmpty || !mounted) return;
    _timer?.cancel();
    setState(() {
      _answered = true;
      _selectedOpsi = jawaban;
    });

    final question = _soal[_index];
    final jawabanBenar = question['jawabanBenar'] as int;
    final opsi = (question['opsi'] as List).cast<String>();
    final selectedIndex = jawaban == null ? -1 : opsi.indexOf(jawaban);
    final isCorrect = selectedIndex == jawabanBenar;

    final sisaNyawa = isCorrect
        ? await _storage.tambahNyawa(1)
        : await _storage.kurangiNyawa(1);
    if (!mounted) return;
    setState(() {
      _nyawa = sisaNyawa;
      if (isCorrect) {
        _benar++;
        _feedbackMessage = '✨ MasyaAllah, Benar! +1 ❤️ Nyawa';
        _feedbackCorrect = true;
      } else {
        _feedbackMessage = '❌ Kurang Tepat! -1 ❤️ Nyawa';
        _feedbackCorrect = false;
      }
    });
    _feedbackTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_index < _soal.length - 1 && _nyawa > 0) {
        setState(() {
          _index++;
          _answered = false;
          _selectedOpsi = null;
          _feedbackMessage = null;
          _feedbackCorrect = false;
        });
        _startTimer();
      } else {
        _selesai();
      }
    });
  }

  Future<void> _selesai() async {
    if (_showResult) return;
    _timer?.cancel();
    setState(() {
      _showResult = true;
      _feedbackMessage = null;
      _feedbackCorrect = false;
    });

    final total = _soal.length;
    final skor = total > 0 ? (_benar / total * 100).round() : 0;
    final lulus = skor >= ProgressionFSM.passScore && _nyawa > 0;
    var bintang = 0;
    if (lulus) {
      if (skor >= 90) {
        bintang = 3;
      } else if (skor >= 75) {
        bintang = 2;
      } else {
        bintang = 1;
      }
    }

    var progression = const StageProgressionResult(passed: false);
    if (lulus) {
      final fsm = ProgressionFSM(initialStates: await _storage.getFsmStates());
      progression = fsm.completeStage(
        pulauId: widget.pulauId,
        tahap: widget.tahap,
        skor: skor,
        nyawa: _nyawa,
      );
      await _storage.saveFsmStates(fsm.states);

      final bestStars =
          await _storage.getStageStars(widget.pulauId, widget.tahap);
      if (bintang > bestStars) {
        await _storage.setStageStars(widget.pulauId, widget.tahap, bintang);
      }
      await _storage.recalculateTotalStars();
    }

    if (!mounted) return;
    final retry = await _showResultDialog(
      skor: skor,
      total: total,
      lulus: lulus,
      progression: progression,
    );
    if (!mounted) return;
    if (retry) {
      await _reset();
      return;
    }

    if (progression.badgeUnlocked) {
      await _showBadgeCelebrationDialog();
    } else if (progression.nextStageUnlocked ||
        progression.nextIslandUnlocked) {
      await _showUnlockDialog(progression);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<bool> _showResultDialog({
    required int skor,
    required int total,
    required bool lulus,
    required StageProgressionResult progression,
  }) async {
    final hasUnlock = progression.nextStageUnlocked ||
        progression.nextIslandUnlocked ||
        progression.badgeUnlocked;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(lulus ? 'LULUS!' : 'BELUM LULUS'),
            content: Text(
              'Skor: $skor\n'
              'Benar: $_benar/$total\n'
              'Nyawa: $_nyawa'
              '${_nyawa <= 0 ? '\n$_pesanNyawaHabis' : ''}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(lulus ? 'Main Lagi' : 'Coba Lagi'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child:
                    Text(hasUnlock ? 'Lihat Pembukaan' : 'Kembali ke Tahapan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showBadgeCelebrationDialog() async {
    final badgeName = BankSoal.badgeName(widget.pulauId).replaceAll('\n', ' ');
    final description = widget.pulauId < StorageService.totalIslands
        ? 'Hebat! Kamu telah menamatkan Pulau ${widget.pulauId} dan membuka Pulau ${widget.pulauId + 1}!'
        : 'Hebat! Kamu telah menamatkan Pulau ${widget.pulauId} dan menyelesaikan seluruh petualangan!';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        title: const Text(
          '🎉 SELAMAT! LENCANA BARU TERBUKA! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF8A5A00),
          ),
        ),
        content: SingleChildScrollView(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 164,
                        height: 164,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFE08A),
                              Color(0xFFFFC107),
                              Color(0xFFFFE08A),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFFF3C4),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.45),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/icon_trophy.png',
                        width: 126,
                        height: 126,
                        fit: BoxFit.contain,
                      ),
                      const Positioned(
                        left: 0,
                        top: 14,
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.amber,
                          size: 30,
                        ),
                      ),
                      const Positioned(
                        right: 0,
                        top: 22,
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 28,
                        ),
                      ),
                      const Positioned(
                        right: 6,
                        bottom: 8,
                        child: Icon(
                          Icons.celebration_rounded,
                          color: Colors.deepOrange,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  badgeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              elevation: 6,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Klaim Lencana & Lanjut',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUnlockDialog(StageProgressionResult progression) async {
    final messages = <String>[];
    if (progression.nextStageUnlocked) {
      messages.add('Tahap ${widget.tahap + 1} telah terbuka.');
    }
    if (progression.islandCompleted) {
      messages.add('Pulau ${widget.pulauId} telah selesai.');
    }
    if (progression.nextIslandUnlocked) {
      messages.add(
        'Pulau ${widget.pulauId + 1} (${BankSoal.islandName(widget.pulauId + 1)}) telah terbuka.',
      );
    }
    if (progression.badgeUnlocked) {
      messages.add(
        'Lencana ${BankSoal.badgeName(widget.pulauId).replaceAll('\n', ' ')} telah terbuka.',
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pembukaan Baru!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: messages
              .map((message) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(message),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kembali ke Tahapan'),
          ),
        ],
      ),
    );
  }

  Future<void> _reset() async {
    _timer?.cancel();
    _feedbackTimer?.cancel();
    final nyawa = await _storage.getNyawa();
    if (!mounted) return;
    if (nyawa <= 0) {
      await _showNyawaHabisDialog();
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() {
      _index = 0;
      _nyawa = nyawa;
      _benar = 0;
      _feedbackMessage = null;
      _feedbackCorrect = false;
      _answered = false;
      _selectedOpsi = null;
      _soalError = null;
      _showResult = false;
    });
    _loadSoal();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_soalError != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.teal[900],
          title: const Text('Kuis Tidak Tersedia'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_soalError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_soal.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = _soal[_index];
    final opsi = (q['opsi'] as List).cast<String>();
    final jawabanBenar = q['jawabanBenar'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFFDDF5E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.teal[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kuis Pulau ${widget.pulauId} - Tahap ${widget.tahap}',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.teal[900],
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        key: const ValueKey('quiz-lives'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              size: 20,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_nyawa',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal[100],
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$_sisaWaktu s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_index + 1) / _soal.length,
                    backgroundColor: Colors.teal[100],
                    valueColor: AlwaysStoppedAnimation(Colors.teal[600]),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            q['pertanyaan'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...opsi.asMap().entries.map((entry) {
                            final i = entry.key;
                            final o = entry.value;
                            final isCorrect = i == jawabanBenar;
                            final isSelected = _selectedOpsi == o;
                            Color? bg;
                            if (_answered) {
                              if (isCorrect) {
                                bg = Colors.green[100];
                              } else if (isSelected) {
                                bg = Colors.red[100];
                              }
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ElevatedButton(
                                onPressed: _answered ? null : () => _jawab(o),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: bg ?? Colors.white,
                                  foregroundColor: Colors.grey[800],
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(
                                    color: _answered && isCorrect
                                        ? Colors.green
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  o,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_feedbackMessage != null)
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Material(
                key: const ValueKey('quiz-feedback-banner'),
                elevation: 8,
                color: _feedbackCorrect
                    ? Colors.green[600]
                    : Colors.deepOrange[400],
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _feedbackCorrect
                            ? Icons.star_rounded
                            : Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _feedbackMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
