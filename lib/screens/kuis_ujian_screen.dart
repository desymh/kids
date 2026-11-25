import 'dart:async';
import 'package:flutter/material.dart';
import '../data/bank_soal.dart';
import '../core/fisher_yates_shuffle.dart';
import '../core/storage_service.dart';

class KuisUjianScreen extends StatefulWidget {
  final int pulauId;
  final int tahap;
  const KuisUjianScreen({super.key, required this.pulauId, required this.tahap});

  @override
  State<KuisUjianScreen> createState() => _KuisUjianScreenState();
}

class _KuisUjianScreenState extends State<KuisUjianScreen> {
  final StorageService _storage = StorageService();
  List<Map<String, dynamic>> _soal = [];
  int _index = 0;
  int _nyawa = 3;
  int _benar = 0;
  Timer? _timer;
  int _sisaWaktu = 30;
  bool _answered = false;
  String? _selectedOpsi;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _loadSoal();
  }

  void _loadSoal() {
    final raw = BankSoal.getSoalTahap(widget.pulauId, widget.tahap);
    final shuffled = FisherYatesShuffler.shuffle(raw);
    final processed = shuffled.map((s) => FisherYatesShuffler.acakSoalDanOpsi(Map<String, dynamic>.from(s))).toList();
    setState(() => _soal = processed);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _sisaWaktu = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sisaWaktu <= 0) {
        t.cancel();
        _jawab(null);
      } else {
        setState(() => _sisaWaktu--);
      }
    });
  }

  void _jawab(String? jawaban) {
    if (_answered) return;
    _timer?.cancel();
    setState(() => _answered = true);

    final q = _soal[_index];
    final jawabanBenar = q['jawabanBenar'] as int;
    final opsi = (q['opsi'] as List).cast<String>();

    String? selectedJawaban = jawaban;
    int selectedIndex = -1;
    if (jawaban != null) {
      selectedIndex = opsi.indexOf(jawaban);
    }

    if (selectedIndex == jawabanBenar) {
      _benar++;
    } else {
      _nyawa--;
    }

    setState(() => _selectedOpsi = jawaban);

    Future.delayed(const Duration(seconds: 1), () {
      if (_index < _soal.length - 1 && _nyawa > 0) {
        setState(() {
          _index++;
          _answered = false;
          _selectedOpsi = null;
        });
        _startTimer();
      } else {
        _selesai();
      }
    });
  }

  Future<void> _selesai() async {
    final total = _soal.length;
    final skor = (total > 0) ? (_benar / total * 100).round() : 0;
    final lulus = skor >= 60 && _nyawa > 0;

    int bintang = 0;
    if (lulus) {
      if (skor >= 90) bintang = 3;
      else if (skor >= 75) bintang = 2;
      else bintang = 1;
    }

    if (lulus) {
      final poin = _benar * 10;
      final currentPoin = await _storage.getTotalPoin();
      await _storage.setTotalPoin(currentPoin + poin);
      final currentBintang = await _storage.getTotalBintang();
      await _storage.setTotalBintang(currentBintang + bintang);

      // Save completed status for current tahap
      await _storage.setProgres('pulau_${widget.pulauId}_tahap_${widget.tahap}_completed', true);

      String notifText = '';
      if (widget.tahap < 4) {
        await _storage.setProgres('pulau_${widget.pulauId}_tahap_${widget.tahap + 1}_unlocked', true);
        notifText = 'Hebat! Tahap ${widget.tahap + 1} telah terbuka!';
      } else {
        if (widget.pulauId < 6) {
          await _storage.setProgres('pulau_${widget.pulauId}_completed', true);
          await _storage.setProgres('pulau_${widget.pulauId + 1}_unlocked', true);
          await _storage.setProgres('pulau_${widget.pulauId + 1}_tahap_1_unlocked', true);
          await _storage.setProgres('lencana_${widget.pulauId}', true);
          notifText = '🎉 SELAMAT! Pulau ${widget.pulauId + 1} & Lencana Pulau ${widget.pulauId} Telah Terbuka!';
        }
      }

      setState(() => _showResult = true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(lulus ? 'LULUS!' : 'BELUM LULUS'),
          content: Text('Skor: $skor\nBenar: $_benar/$total\nNyawa: $_nyawa\nBintang: $bintang\n\n$notifText'),
          actions: [
            if (!lulus)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reset();
                },
                child: const Text('Coba Lagi'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _showResult = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('BELUM LULUS'),
        content: Text('Skor: $skor\nBenar: $_benar/$total\nNyawa: $_nyawa'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reset();
            },
            child: const Text('Coba Lagi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _index = 0;
      _nyawa = 3;
      _benar = 0;
      _answered = false;
      _selectedOpsi = null;
      _showResult = false;
    });
    _loadSoal();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.teal[700]), onPressed: () => Navigator.pop(context)),
        title: Text('Kuis Pulau ${widget.pulauId} - Tahap ${widget.tahap}', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal[900], fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Nyawa & Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: List.generate(3, (i) => Icon(Icons.favorite, size: 28, color: i < _nyawa ? Colors.red[500] : Colors.grey[300]))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.teal[100], borderRadius: BorderRadius.circular(999)),
                    child: Text('$_sisaWaktu s', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[900])),
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
              // Soal
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(q['pertanyaan'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      ...opsi.asMap().entries.map((entry) {
                        final i = entry.key;
                        final o = entry.value;
                        final isCorrect = i == jawabanBenar;
                        final isSelected = _selectedOpsi == o;
                        Color? bg;
                        if (_answered) {
                          if (isCorrect) bg = Colors.green[100];
                          else if (isSelected) bg = Colors.red[100];
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ElevatedButton(
                            onPressed: _answered ? null : () => _jawab(o),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bg ?? Colors.white,
                              foregroundColor: Colors.grey[800],
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: BorderSide(color: _answered && isCorrect ? Colors.green : Colors.grey[300]!),
                            ),
                            child: Text(o, style: const TextStyle(fontSize: 14)),
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
    );
  }
}