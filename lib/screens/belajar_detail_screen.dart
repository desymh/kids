import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/materi_data.dart';
import '../core/storage_service.dart';

class BelajarDetailScreen extends StatefulWidget {
  final int babIndex;
  final Map<String, dynamic> bab;
  const BelajarDetailScreen({super.key, required this.babIndex, required this.bab});

  @override
  State<BelajarDetailScreen> createState() => _BelajarDetailScreenState();
}

class _BelajarDetailScreenState extends State<BelajarDetailScreen> {
  final FlutterTts _tts = FlutterTts();
  final StorageService _storage = StorageService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _playing = false;

  List<Map<String, dynamic>> get _items => (widget.bab['items'] as List).cast<Map<String, dynamic>>();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('id-ID');
    _tts.setSpeechRate(0.95);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _markSelesai() async {
    final key = 'bab_${widget.bab['bab']}_selesai';
    await _storage.setProgres(key, true);
  }

  Future<void> _toggleAudio(String text) async {
    if (_playing) {
      await _tts.stop();
      setState(() => _playing = false);
    } else {
      setState(() => _playing = true);
      await _tts.speak(text);
      setState(() => _playing = false);
    }
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _markSelesai();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selesai dibaca!')));
      Navigator.pop(context);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDF5E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.teal[700]), onPressed: () => Navigator.pop(context)),
        title: Text(widget.bab['judul'], style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal[900], fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: _MateriCard(item: item, playing: _playing, onPlay: () => _toggleAudio(item['penjelasanAnak'] as String)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentPage > 0 ? _prevPage : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        side: BorderSide(color: Colors.teal[200]!),
                      ),
                      child: Text('Sebelumnya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[700])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text(_currentPage == _items.length - 1 ? 'Selesai' : 'Lanjut', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MateriCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool playing;
  final VoidCallback onPlay;
  const _MateriCard({required this.item, required this.playing, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item['judulKartu'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.teal[900])),
            const SizedBox(height: 16),
            // Teks Arab
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(16)),
              child: Text(
                item['teksArab'] as String,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 12),
            // Latin
            Text('Bacaan Latin:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
            const SizedBox(height: 4),
            Text(item['teksLatin'] as String, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            // Arti
            Text('Arti:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
            const SizedBox(height: 4),
            Text(item['arti'] as String, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            // Penjelasan
            Text('Penjelasan:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
            const SizedBox(height: 4),
            Text(item['penjelasanAnak'] as String, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            // Audio button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPlay,
                icon: Icon(playing ? Icons.stop : Icons.volume_up, color: Colors.white),
                label: Text(playing ? 'Memutar...' : 'Dengarkan Suara', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}