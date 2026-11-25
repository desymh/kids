import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/fisher_yates_shuffle.dart';

class QuizScreen extends StatefulWidget {
  final String idPulau;
  final int tahap;
  const QuizScreen({super.key, this.idPulau = 'pulau1', this.tahap = 1});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> soal = [];
  int index = 0;
  int nyawa = 3;
  int poin = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/bank_soal.json');
    final bank = jsonDecode(raw) as List;
    final filtered = bank.where((e) {
      final m = e as Map;
      return m['id_pulau'] == widget.idPulau && m['tahap_kesulitan'] == widget.tahap;
    }).toList();
    final shuffled = FisherYatesShuffler.shuffle(filtered);
    setState(() => soal = shuffled);
  }

  void _jawab(String jawaban) {
    if (soal.isEmpty) return;
    final q = soal[index] as Map;
    if (jawaban == q['jawaban']) {
      poin += 20;
    } else {
      nyawa -= 1;
    }
    if (index < soal.length - 1) {
      setState(() => index++);
    } else {
      _selesai();
    }
  }

  void _selesai() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Selesai'),
        content: Text('Poin: $poin  Nyawa: $nyawa'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (soal.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final q = soal[index] as Map;
    final opsi = (q['opsi'] as List).cast<String>();
    return Scaffold(
      appBar: AppBar(title: Text('Kuis ${widget.idPulau} T${widget.tahap}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nyawa: $nyawa  Poin: $poin'),
            const SizedBox(height: 16),
            Text(q['soal'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...opsi.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(onPressed: () => _jawab(o), child: Text(o)),
            )),
          ],
        ),
      ),
    );
  }
}