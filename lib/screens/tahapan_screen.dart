import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class TahapanScreen extends StatelessWidget {
  final int pulauNo;
  final String pulauNama;
  const TahapanScreen({super.key, required this.pulauNo, required this.pulauNama});

  @override
  Widget build(BuildContext context) {
    final stages = _getStages(pulauNo);
    return Scaffold(
      backgroundColor: const Color(0xFFDCF5E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.grey[600]), onPressed: () => Navigator.pop(context)),
        title: Text('Tahapan Pulau $pulauNo: $pulauNama', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey[800], fontSize: 18)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListView.separated(
            itemCount: stages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _StageCard(data: stages[i], onStart: () {
              if (stages[i].unlocked && !stages[i].completed) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(idPulau: 'pulau$pulauNo', tahap: i + 1)));
              }
            }),
          ),
        ),
      ),
    );
  }

  List<_StageData> _getStages(int pulauNo) {
    if (pulauNo == 2) {
      return [
        _StageData(1, 'Pengenalan Najis', 'assets/images/stage_najis.png', true, true, 3, 'Easy', Colors.teal[500]!),
        _StageData(2, 'Simulasi Wudhu', 'assets/images/stage_wudhu.png', true, true, 2, 'Medium', Colors.teal[500]!),
        _StageData(3, 'Studi Kasus Najis', 'assets/images/stage_kasus.png', true, false, 0, 'Hard', Colors.amber[700]!),
        _StageData(4, 'Ujian Akhir Pulau 2', '', false, false, 0, 'Expert', Colors.grey[400]!),
      ];
    }
    return List.generate(4, (i) => _StageData(
      i + 1,
      'Tahap ${i + 1}',
      '',
      i == 0,
      false,
      0,
      ['Easy', 'Medium', 'Hard', 'Expert'][i],
      i == 0 ? Colors.teal[500]! : Colors.grey[400]!,
    ));
  }
}

class _StageCard extends StatelessWidget {
  final _StageData data;
  final VoidCallback onStart;
  const _StageCard({required this.data, required this.onStart});

  @override
  Widget build(BuildContext context) {
    if (data.locked) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[200]!.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[300]!.withOpacity(0.8)),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.lock, color: Colors.grey[500], size: 36),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tahap ${data.no}:\n${data.title}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey[600], height: 1.3)),
                  const SizedBox(height: 8),
                  Text(data.difficulty, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: data.completed ? Colors.teal[500]!.withOpacity(0.8) : (data.active ? Colors.amber[700]!.withOpacity(0.6) : Colors.transparent), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: data.completed ? Colors.blue[50] : (data.active ? Colors.amber[50] : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: data.completed ? Colors.blue[100]! : (data.active ? Colors.amber[100]! : Colors.transparent)),
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(14), child: data.imageUrl.isNotEmpty
                    ? Image.asset(data.imageUrl, fit: BoxFit.cover, width: 64, height: 64, errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey[400], size: 32))
                    : Icon(Icons.lock, color: Colors.grey[500], size: 36)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tahap ${data.no}:\n${data.title}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey[800], height: 1.3)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ...List.generate(3, (i) => Icon(Icons.star, size: 18, color: i < data.stars ? Colors.amber[400] : Colors.grey[300])),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: data.difficultyColor.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                          child: Text(data.difficulty, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: data.difficultyColor)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.completed ? Colors.teal[500] : (data.active ? Colors.red[500] : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Icon(data.completed ? Icons.check : Icons.remove, size: 16, color: Colors.white),
              ),
            ],
          ),
          if (data.active && !data.completed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  elevation: 2,
                ),
                child: Text('MULAI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StageData {
  final int no;
  final String title;
  final String imageUrl;
  final bool unlocked;
  final bool completed;
  final int stars;
  final String difficulty;
  final Color difficultyColor;
  bool get active => unlocked && !completed;
  bool get locked => !unlocked;
  const _StageData(this.no, this.title, this.imageUrl, this.unlocked, this.completed, this.stars, this.difficulty, this.difficultyColor);
}