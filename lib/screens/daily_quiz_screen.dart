import 'package:flutter/material.dart';
import '../data/bank_soal.dart';
import '../core/fisher_yates_shuffle.dart';
import '../core/storage_service.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  final StorageService _storage = StorageService();
  Map<String, dynamic>? _soal;
  bool _answered = false;
  String? _selected;
  bool _correct = false;
  int _nyawa = StorageService.defaultNyawa;

  static const _pesanNyawaHabis =
      'Nyawamu habis (0 ❤️)! Yuk baca materi di Menu Belajar atau selesaikan Simulasi Praktik untuk menambah nyawa.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prepareMission();
    });
  }

  Future<void> _prepareMission() async {
    final nyawa = await _storage.getNyawa();
    if (!mounted) return;
    if (nyawa <= 0) {
      await _showNyawaHabisDialog();
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _nyawa = nyawa);
    _load();
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

  void _load() {
    final all = BankSoal.bank;
    final shuffled = FisherYatesShuffler.shuffle(all);
    final q = FisherYatesShuffler.acakSoalDanOpsi(
        Map<String, dynamic>.from(shuffled.first));
    setState(() => _soal = q);
  }

  Future<void> _jawab(String opsi) async {
    if (_answered || _soal == null || !mounted) return;
    final isCorrect =
        opsi == (_soal!['opsi'] as List)[_soal!['jawabanBenar'] as int];
    setState(() {
      _answered = true;
      _selected = opsi;
      _correct = isCorrect;
    });
    final sisaNyawa = isCorrect
        ? await _storage.tambahNyawa(3)
        : await _storage.kurangiNyawa(1);
    if (!mounted) return;
    setState(() => _nyawa = sisaNyawa);
  }

  @override
  Widget build(BuildContext context) {
    if (_soal == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final opsi = (_soal!['opsi'] as List).cast<String>();
    final jawabanBenar = _soal!['jawabanBenar'] as int;
    return Scaffold(
      backgroundColor: const Color(0xFFDDF5E8),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Misi Harian',
              style:
                  TextStyle(fontWeight: FontWeight.w900, color: Colors.teal))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                key: const ValueKey('daily-lives'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 24,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_nyawa',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.teal[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_soal!['pertanyaan'] as String,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      ...opsi.asMap().entries.map((e) {
                        final i = e.key;
                        final o = e.value;
                        Color? bg;
                        if (_answered) {
                          if (i == jawabanBenar) {
                            bg = Colors.green[100];
                          } else if (_selected == o) {
                            bg = Colors.red[100];
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ElevatedButton(
                            onPressed: _answered ? null : () => _jawab(o),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: bg ?? Colors.white,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16))),
                            child: Text(o),
                          ),
                        );
                      }),
                      if (_answered)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _correct
                                ? '🎉 Misi Harian Berhasil! +3 ❤️ Nyawa'
                                : '❌ Jawaban kurang tepat! -1 ❤️ Nyawa',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _correct ? Colors.green : Colors.red,
                                fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
}
