import 'package:flutter/material.dart';
import 'materi_detail_screen.dart';
import '../models/data_models.dart';

class BelajarScreen extends StatelessWidget {
  const BelajarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final babs = [
      BabData(1, 'Pondasi Islam', 'Dua Kalimat Syahadat, 6 Rukun Iman, 5 Rukun Islam', 1.0, const Color(0xFF22A45D), 'assets/images/bab1_icon.png'),
      BabData(2, 'Thaharah', 'Macam air suci, 3 jenis najis, Rukun & pembatal wudhu', 0.8, const Color(0xFF0EA5E9), 'assets/images/bab2_icon.png'),
      BabData(3, 'Ibadah Shalat', 'Syarat sah, Urutan gerakan & bacaan, Pembatal shalat', 0.4, const Color(0xFFF59E0B), 'assets/images/bab3_icon.png'),
      BabData(4, 'Ibadah Puasa', 'Niat puasa, Doa berbuka, Sunnah & pembatal puasa', 0.0, const Color(0xFFEF4444), 'assets/images/bab4_icon.png'),
      BabData(5, 'Doa Harian & Adab', 'Doa makan, Doa tidur, Adab anak muslim', 0.0, const Color(0xFFA855F7), 'assets/images/bab5_icon.png'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFDDF5E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.teal[700]), onPressed: () => Navigator.pop(context)),
        title: Text('Menu Belajar', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal[900], fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Menu Belajar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.teal[900])),
                      Text('5 Bab Materi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.teal[900])),
                    ],
                  ),
                  Image.asset('assets/images/avatar_aisyah.jpeg', height: 96),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: babs.length,
                itemBuilder: (_, i) {
                  final b = babs[i];
                  return _ChapterCard(data: b, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MateriDetailScreen(bab: b))));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final BabData data;
  final VoidCallback onTap;
  const _ChapterCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = data.progress;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: data.color.withOpacity(0.5), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: data.color.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(data.iconUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.menu_book, color: data.color, size: 28)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey[800], height: 1.3),
                      children: [
                        TextSpan(text: 'Bab ${data.no}:\n'),
                        TextSpan(text: data.judul),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(data.color),
                    ),
                  ),
                  Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: progress > 0 ? data.color : Colors.grey[400])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}