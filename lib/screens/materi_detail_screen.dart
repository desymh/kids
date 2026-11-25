import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/data_models.dart';

class MateriDetailScreen extends StatefulWidget {
  final BabData bab;
  const MateriDetailScreen({super.key, required this.bab});

  @override
  State<MateriDetailScreen> createState() => _MateriDetailScreenState();
}

class _MateriDetailScreenState extends State<MateriDetailScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('id-ID');
    _tts.setSpeechRate(0.95);
  }

  Future<void> _toggleAudio() async {
    if (_playing) {
      await _tts.stop();
      setState(() => _playing = false);
    } else {
      setState(() => _playing = true);
      await _tts.speak(_getStoryText());
      setState(() => _playing = false);
    }
  }

  String _getStoryText() {
    switch (widget.bab.no) {
      case 1:
        return 'Pondasi Islam mencakup Dua Kalimat Syahadat, enam Rukun Iman, dan lima Rukun Islam. Inilah fondasi keimanan seorang muslim.';
      case 2:
        return 'Ini adalah cara membasuh tangan sampai siku. Kita harus membersihkannya dengan air suci. Thaharah artinya bersuci dari hadas dan najis.';
      case 3:
        return 'Shalat fardhu memiliki syarat sah, urutan gerakan dan bacaan yang benar, serta hal-hal yang membatalkan shalat.';
      case 4:
        return 'Puasa bermula dari niat, diikuti doa berbuka, mengamalkan sunnah, dan menjauhi pembatal puasa.';
      case 5:
        return 'Doa harian meliputi doa makan, tidur, kedua orang tua, masuk keluar masjid, serta adab sehari-hari anak muslim.';
      default:
        return 'Materi pelajaran Islam.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9F4E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.grey[700]), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Isi Materi Belajar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey[600])),
            Text('Bab ${widget.bab.no}: ${widget.bab.judul}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.grey[800])),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF149E53).withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10)),
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('Story', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      const SizedBox(height: 16),
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7F0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.teal[100]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/materi_wudhu_step2.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/avatar_zaid.jpeg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_getStoryText(), style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[700], fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _toggleAudio,
                          icon: Icon(_playing ? Icons.stop : Icons.volume_up, color: Colors.white),
                          label: Text(_playing ? 'Memutar...' : 'Putar Suara', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF149E53),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            elevation: 4,
                            shadowColor: const Color(0xFF149E53).withOpacity(0.25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text('Sebelumnya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF149E53),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        elevation: 4,
                        shadowColor: const Color(0xFF149E53).withOpacity(0.25),
                      ),
                      child: const Text('Selanjutnya', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}