import 'package:flutter/material.dart';
import 'kuis_ujian_screen.dart';
import '../core/fsm_controller.dart';
import '../core/storage_service.dart';

class TahapanPulauScreen extends StatefulWidget {
  final int pulauId;
  final String namaPulau;
  const TahapanPulauScreen({super.key, required this.pulauId, required this.namaPulau});

  @override
  State<TahapanPulauScreen> createState() => _TahapanPulauScreenState();
}

class _TahapanPulauScreenState extends State<TahapanPulauScreen> {
  final StorageService _storage = StorageService();
  final List<String> _tahapLabels = ['Tahap 1: Pemula', 'Tahap 2: Dasar', 'Tahap 3: Lanjutan', 'Tahap 4: Ujian Pulau'];
  final Map<int, LevelState> _status = {};
  final Map<int, int> _stars = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final states = await _storage.getFsmStates();
    for (var tahap = 1; tahap <= StorageService.stagesPerIsland; tahap++) {
      final key = ProgressionFSM.stageKey(widget.pulauId, tahap);
      _status[tahap] = states[key] ?? LevelState.locked;
      _stars[tahap] = await _storage.getStageStars(widget.pulauId, tahap);
    }
    if (!mounted) return;
    setState(() {});
  }

  void _onTahapTap(int tahap) async {
    if ((_status[tahap] ?? LevelState.locked) == LevelState.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selesaikan tahap sebelumnya dengan skor minimal 60!'), backgroundColor: Colors.red),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KuisUjianScreen(pulauId: widget.pulauId, tahap: tahap)),
    );
    if (mounted) await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDF5E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.teal[700]), onPressed: () => Navigator.pop(context)),
        title: Text(widget.namaPulau, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal[900], fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, i) {
            final tahap = i + 1;
            final state = _status[tahap] ?? LevelState.locked;
            final unlocked = state != LevelState.locked;
            final completed = state == LevelState.completed;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _onTahapTap(tahap),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: unlocked ? Colors.white : Colors.grey[200],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: unlocked ? Colors.teal[200]! : Colors.grey[300]!, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: unlocked ? Colors.teal[50] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(completed ? Icons.check_circle : (unlocked ? Icons.play_arrow : Icons.lock), color: unlocked ? Colors.teal[700] : Colors.grey[500], size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_tahapLabels[i], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: unlocked ? Colors.teal[900] : Colors.grey[500])),
                            if (completed)
                              Text(
                                'Selesai · ${_stars[tahap] ?? 0}/3 bintang',
                                style: TextStyle(fontSize: 12, color: Colors.teal[700]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}