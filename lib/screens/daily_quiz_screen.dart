import 'dart:async';
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
  int _nyawa = 1;
  bool _answered = false;
  String? _selected;
  bool _correct = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final all = BankSoal.bank;
    final shuffled = FisherYatesShuffler.shuffle(all);
    final q = FisherYatesShuffler.acakSoalDanOpsi(Map<String, dynamic>.from(shuffled.first));
    setState(() => _soal = q);
  }

  void _jawab(String opsi) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selected = opsi;
      _correct = opsi == (_soal!['opsi'] as List)[_soal!['jawabanBenar'] as int];
    });
    if (_correct) {
      _storage.getTotalPoin().then((p) => _storage.setTotalPoin(p + 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_soal == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final opsi = (_soal!['opsi'] as List).cast<String>();
    final jawabanBenar = _soal!['jawabanBenar'] as int;
    return Scaffold(
      backgroundColor: const Color(0xFFDDF5E8),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Misi Harian', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_soal!['pertanyaan'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      ...opsi.asMap().entries.map((e) {
                        final i = e.key;
                        final o = e.value;
                        Color? bg;
                        if (_answered) {
                          if (i == jawabanBenar) bg = Colors.green[100];
                          else if (_selected == o) bg = Colors.red[100];
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ElevatedButton(
                            onPressed: _answered ? null : () => _jawab(o),
                            style: ElevatedButton.styleFrom(backgroundColor: bg ?? Colors.white, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: Text(o),
                          ),
                        );
                      }),
                      if (_answered)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(_correct ? 'Benar! +50 Poin' : 'Salah', style: TextStyle(fontWeight: FontWeight.bold, color: _correct ? Colors.green : Colors.red, fontSize: 16)),
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