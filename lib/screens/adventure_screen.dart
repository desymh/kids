import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/fsm/adventure_fsm.dart';
import '../core/fsm_controller.dart';
import '../core/storage_service.dart';
import '../data/bank_soal.dart';
import '../game/qalbukids_adventure_game.dart';

Future<void> unlockAdventureIslandProgress({
  required StorageService storage,
  required int pulauId,
  required int skor,
  required int nyawa,
}) async {
  if (skor < ProgressionFSM.passScore || nyawa <= 0) return;
  final fsm = ProgressionFSM(initialStates: await storage.getFsmStates());
  fsm.complete(ProgressionFSM.islandKey(pulauId), skor, nyawa);
  fsm.unlock(ProgressionFSM.badgeKey(pulauId));
  if (pulauId < StorageService.totalIslands) {
    fsm.unlock(ProgressionFSM.islandKey(pulauId + 1));
    fsm.unlock(ProgressionFSM.stageKey(pulauId + 1, 1));
  }
  await storage.saveFsmStates(fsm.states);
}

class AdventureScreen extends StatefulWidget {
  final int pulauId;
  final String namaPulau;

  const AdventureScreen({
    super.key,
    required this.pulauId,
    required this.namaPulau,
  });

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  static const _pesanNyawaHabis =
      'Nyawamu habis (0 ❤️)! Yuk baca materi di Menu Belajar atau selesaikan Simulasi Praktik untuk menambah nyawa.';

  final StorageService _storage = StorageService();
  late final QalbuKidsAdventureGame _game;
  int _nyawa = StorageService.defaultNyawa;
  bool _showingQuiz = false;
  bool _returningToMap = false;
  bool _gateOpened = false;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
    _game = QalbuKidsAdventureGame(
      onGateTriggered: _handleGateTriggered,
      onGateOpened: _handleGateOpened,
    );
    unawaited(_loadNyawa());
  }

  @override
  void dispose() {
    _game.stopMoving();
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]));
    super.dispose();
  }

  Future<void> _loadNyawa() async {
    final nyawa = await _storage.getNyawa();
    if (!mounted) return;
    setState(() => _nyawa = nyawa);
  }

  void _handleGateTriggered() {
    if (_showingQuiz || _returningToMap) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showExam());
    });
  }

  void _handleGateOpened() {
    if (!mounted || _returningToMap) return;
    setState(() => _gateOpened = true);
  }

  Future<void> _showExam() async {
    if (_showingQuiz || _returningToMap) return;
    _showingQuiz = true;
    final nyawa = await _storage.getNyawa();
    if (!mounted) {
      _showingQuiz = false;
      return;
    }
    setState(() => _nyawa = nyawa);

    if (nyawa <= 0) {
      await _showNyawaHabisDialog();
      if (!mounted) return;
      _showingQuiz = false;
      _game.cancelQuiz();
      return;
    }

    _game.pauseEngine();
    final result = await showDialog<AdventureQuizResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdventureQuizDialog(
        pulauId: widget.pulauId,
        namaPulau: widget.namaPulau,
        initialNyawa: nyawa,
      ),
    );
    if (!mounted) return;
    if (result?.passed != true) _game.resumeEngine();
    _showingQuiz = false;

    if (result == null) {
      _game.cancelQuiz();
      return;
    }

    _game.completeQuiz(result.skor);
    if (!result.passed) {
      await _loadNyawa();
      return;
    }

    _returningToMap = true;
    await _unlockProgression(result.skor, result.nyawa);
    if (!mounted) return;
    final continueToNextIsland = await _showBadgeCelebration();
    if (!mounted) return;
    if (continueToNextIsland && widget.pulauId < StorageService.totalIslands) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdventureScreen(
            pulauId: widget.pulauId + 1,
            namaPulau: BankSoal.islandName(widget.pulauId + 1),
          ),
        ),
      );
      return;
    }
    if (mounted) Navigator.pop(context);
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

  Future<void> _unlockProgression(int skor, int nyawa) async {
    await unlockAdventureIslandProgress(
      storage: _storage,
      pulauId: widget.pulauId,
      skor: skor,
      nyawa: nyawa,
    );
  }

  Future<bool> _showBadgeCelebration() async {
    final badgeName = BankSoal.badgeName(widget.pulauId).replaceAll('\n', ' ');
    final hasNextIsland = widget.pulauId < StorageService.totalIslands;
    final nextIsland =
        hasNextIsland ? '\nPulau ${widget.pulauId + 1} juga terbuka!' : '';
    final gateNotification = _gateOpened
        ? hasNextIsland
            ? 'Gerbang terbuka! Lanjut ke pulau berikutnya.'
            : 'Gerbang terbuka! Seluruh pulau telah diselesaikan.'
        : null;
    final continueToNextIsland = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lencana Terbuka!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/icon_trophy.png', height: 88),
            const SizedBox(height: 12),
            Text(
              badgeName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Hebat! Kamu lulus ujian Pulau ${widget.pulauId}.$nextIsland',
              textAlign: TextAlign.center,
            ),
            if (gateNotification != null) ...[
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('adventure-gate-open-notification'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  gateNotification,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_gateOpened && hasNextIsland)
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Lanjut ke Pulau ${widget.pulauId + 1}'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kembali ke Peta'),
          ),
        ],
      ),
    );
    return continueToNextIsland ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          Positioned(
            top: padding.top + 12,
            left: padding.left + 12,
            child: _HudButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: padding.top + 12,
            right: padding.right + 12,
            child: Container(
              key: const ValueKey('adventure-lives'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Colors.red, size: 25),
                  const SizedBox(width: 7),
                  Text(
                    '$_nyawa',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: padding.bottom + 18,
            left: padding.left + 18,
            child: Row(
              children: [
                _HoldControl(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onStart: () => _game.setMoveLeft(true),
                  onStop: () => _game.setMoveLeft(false),
                ),
                const SizedBox(width: 14),
                _HoldControl(
                  icon: Icons.arrow_forward_ios_rounded,
                  onStart: () => _game.setMoveRight(true),
                  onStop: () => _game.setMoveRight(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HudButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: Colors.teal[800]),
        ),
      ),
    );
  }
}

class _HoldControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _HoldControl({
    required this.icon,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onStart(),
      onPointerUp: (_) => onStop(),
      onPointerCancel: (_) => onStop(),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.teal[700]!, width: 3),
        ),
        child: Icon(icon, color: Colors.teal[800], size: 34),
      ),
    );
  }
}

class AdventureQuizResult {
  final bool passed;
  final int skor;
  final int nyawa;

  const AdventureQuizResult({
    required this.passed,
    required this.skor,
    required this.nyawa,
  });
}

class AdventureQuizDialog extends StatefulWidget {
  final int pulauId;
  final String namaPulau;
  final int initialNyawa;

  const AdventureQuizDialog({
    super.key,
    required this.pulauId,
    required this.namaPulau,
    required this.initialNyawa,
  });

  @override
  State<AdventureQuizDialog> createState() => _AdventureQuizDialogState();
}

class _AdventureQuizDialogState extends State<AdventureQuizDialog> {
  final StorageService _storage = StorageService();
  List<Map<String, dynamic>> _questions = [];
  int _index = 0;
  int _benar = 0;
  int _nyawa = StorageService.defaultNyawa;
  int? _selectedIndex;
  bool _answered = false;
  bool _finished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nyawa = widget.initialNyawa;
    _loadQuestions();
  }

  void _loadQuestions() {
    try {
      _questions = BankSoal.getSoalPulau(widget.pulauId);
      _error =
          _questions.isEmpty ? 'Soal untuk pulau ini belum tersedia.' : null;
    } catch (_) {
      _questions = [];
      _error = 'Soal tidak dapat dimuat. Silakan coba lagi.';
    }
    _index = 0;
    _benar = 0;
    _selectedIndex = null;
    _answered = false;
    _finished = false;
    if (mounted) setState(() {});
  }

  Future<void> _answer(int index) async {
    if (_answered || _finished || _questions.isEmpty) return;
    final question = _questions[_index];
    final isCorrect = index == question['jawabanBenar'] as int;
    setState(() {
      _answered = true;
      _selectedIndex = index;
      if (isCorrect) _benar++;
    });

    final nyawa = isCorrect
        ? await _storage.tambahNyawa(1)
        : await _storage.kurangiNyawa(1);
    if (!mounted) return;
    setState(() => _nyawa = nyawa);
    if (_nyawa <= 0) _finish();
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selectedIndex = null;
        _answered = false;
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    final skor = _score;
    final passed = skor >= AdventureFSM.passScore && _nyawa > 0;
    setState(() => _finished = true);
    if (passed) {
      Navigator.pop(
        context,
        AdventureQuizResult(passed: true, skor: skor, nyawa: _nyawa),
      );
    }
  }

  void _retry() {
    if (_nyawa <= 0) {
      Navigator.pop(
        context,
        AdventureQuizResult(passed: false, skor: _score, nyawa: _nyawa),
      );
    } else {
      _loadQuestions();
    }
  }

  int get _score =>
      _questions.isEmpty ? 0 : (_benar / _questions.length * 100).round();

  @override
  Widget build(BuildContext context) {
    final question = _questions.isEmpty ? null : _questions[_index];
    final options = question == null
        ? <String>[]
        : (question['opsi'] as List).cast<String>();
    final correctIndex = question?['jawabanBenar'] as int?;
    final isCorrect =
        _answered && _selectedIndex != null && _selectedIndex == correctIndex;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    ),
                  ],
                )
              : _finished
                  ? _buildResult()
                  : _buildQuestion(options, correctIndex, isCorrect),
        ),
      ),
    );
  }

  Widget _buildQuestion(
    List<String> options,
    int? correctIndex,
    bool isCorrect,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ujian ${widget.namaPulau}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Colors.red, size: 21),
                  const SizedBox(width: 5),
                  Text('$_nyawa',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Soal ${_index + 1}/${_questions.length}'),
        const SizedBox(height: 12),
        Text(
          _questions[_index]['pertanyaan'] as String,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                Color? background;
                if (_answered) {
                  if (index == correctIndex) {
                    background = Colors.green[100];
                  } else if (index == _selectedIndex) {
                    background = Colors.red[100];
                  }
                }
                return SizedBox(
                  width: width,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _answered ? null : () => _answer(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: background ?? Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      option,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (_answered) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isCorrect
                  ? '✨ MasyaAllah, Benar! +1 ❤️ Nyawa'
                  : '❌ Kurang Tepat! -1 ❤️ Nyawa',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCorrect ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _next,
            child: Text(
              _index == _questions.length - 1 ? 'Lihat Hasil' : 'Lanjut',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResult() {
    final passed = _score >= AdventureFSM.passScore && _nyawa > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed
              ? Icons.emoji_events_rounded
              : Icons.sentiment_dissatisfied_rounded,
          size: 72,
          color: passed ? Colors.amber[700] : Colors.red[400],
        ),
        const SizedBox(height: 12),
        Text(
          passed ? 'LULUS!' : 'BELUM LULUS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: passed ? Colors.green[800] : Colors.red[800],
          ),
        ),
        const SizedBox(height: 10),
        Text('Skor: $_score'),
        Text('Benar: $_benar/${_questions.length}'),
        Text('Nyawa: $_nyawa'),
        if (_nyawa <= 0) ...[
          const SizedBox(height: 10),
          const Text(
            _AdventureScreenState._pesanNyawaHabis,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 18),
        if (!passed && _nyawa > 0)
          ElevatedButton(
            onPressed: _retry,
            child: const Text('Coba Lagi'),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            AdventureQuizResult(passed: false, skor: _score, nyawa: _nyawa),
          ),
          child: Text(passed ? 'Kembali' : 'Keluar dari Ujian'),
        ),
      ],
    );
  }
}
