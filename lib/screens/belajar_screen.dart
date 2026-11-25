import 'package:flutter/material.dart';
import 'belajar_detail_screen.dart';
import '../data/materi_data.dart';
import '../core/storage_service.dart';

class BelajarScreen extends StatefulWidget {
  const BelajarScreen({super.key});

  @override
  State<BelajarScreen> createState() => _BelajarScreenState();
}

class _BelajarScreenState extends State<BelajarScreen> {
  final StorageService _storage = StorageService();
  final Map<int, bool> _selesai = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    for (int i = 0; i < MateriData.dataBabBelajar.length; i++) {
      final bab = MateriData.dataBabBelajar[i];
      final key = 'bab_${bab['bab']}_selesai';
      final done = await _storage.getProgres(key);
      setState(() => _selesai[i] = done);
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
        title: Text('Menu Belajar', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal[900], fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: MateriData.dataBabBelajar.length,
          itemBuilder: (_, i) {
            final bab = MateriData.dataBabBelajar[i];
            final items = bab['items'] as List;
            final done = _selesai[i] ?? false;
            return _BabCard(
              bab: bab,
              itemCount: items.length,
              selesai: done,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BelajarDetailScreen(babIndex: i, bab: bab)),
                );
                _loadStatus();
              },
            );
          },
        ),
      ),
    );
  }
}

class _BabCard extends StatelessWidget {
  final Map<String, dynamic> bab;
  final int itemCount;
  final bool selesai;
  final VoidCallback onTap;
  const _BabCard({required this.bab, required this.itemCount, required this.selesai, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.teal[200]!, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text('${bab['bab']}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.teal[700]))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bab['judul'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.teal[900])),
                  Text(bab['subjudul'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text('$itemCount kartu materi', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            if (selesai)
              Icon(Icons.check_circle, color: Colors.teal[600], size: 28),
          ],
        ),
      ),
    );
  }
}