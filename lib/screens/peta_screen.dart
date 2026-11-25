import 'package:flutter/material.dart';
import 'tahapan_screen.dart';
import '../models/data_models.dart';

class PetaScreen extends StatelessWidget {
  const PetaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pulau = [
      PulauData(1, 'Pondasi Islam', true, false, 3, Colors.teal[600]!, Colors.teal[400]!),
      PulauData(2, 'Thaharah', true, true, 2, Colors.lime[400]!, Colors.green[600]!),
      PulauData(3, 'Ibadah Shalat', false, false, 0, Colors.teal[400]!, Colors.green[600]!),
      PulauData(4, 'Ibadah Puasa', false, false, 0, Colors.teal[400]!, Colors.green[600]!),
      PulauData(5, 'Doa & Adab', false, false, 0, Colors.teal[400]!, Colors.green[600]!),
      PulauData(6, 'Istana Ujian Akhir', false, false, 0, Colors.grey[300]!, Colors.grey[600]!),
    ];

    final positions = <Map<String, Object?>>[
      {'left': 24.0, 'bottom': 40.0},
      {'right': 24.0, 'bottom': 160.0},
      {'left': 32.0, 'bottom': 280.0},
      {'right': 32.0, 'bottom': 380.0},
      {'left': 24.0, 'bottom': 500.0},
      {'center': true, 'top': 40.0},
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF56CFE1), Color(0xFF48BFE3), Color(0xFF38A3A5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              ...List.generate(7, (i) => Positioned(
                top: [80.0, 140.0, 300.0, 390.0, 580.0, 700.0, 800.0][i],
                left: [20.0, 280.0, 30.0, 260.0, 40.0, 270.0, 140.0][i],
                child: CustomPaint(size: const Size(120, 20), painter: _WavePainter()),
              )),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                      child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.teal[800]), onPressed: () => Navigator.pop(context)),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withOpacity(0.6)), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                      child: Text('Peta Petualangan', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal[900], fontSize: 13)),
                    ),
                  ],
                ),
              ),
              ...pulau.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                final pos = positions[i];
                final isLast = i == 5;
                return Positioned(
                  left: pos['left'] as double?,
                  right: pos['right'] as double?,
                  top: pos['top'] as double?,
                  bottom: pos['bottom'] as double?,
                  child: _PulauWidget(data: p, isCastle: isLast, onTap: () {
                    if (p.unlocked) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TahapanScreen(pulauNo: p.no, pulauNama: p.nama)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.nama} masih terkunci! Selesaikan pulau sebelumnya dulu.'), backgroundColor: Colors.grey[800]));
                    }
                  }),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulauWidget extends StatelessWidget {
  final PulauData data;
  final bool isCastle;
  final VoidCallback onTap;
  const _PulauWidget({required this.data, required this.isCastle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isCastle) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 128, height: 96, child: CustomPaint(painter: _CastlePainter())),
            const SizedBox(height: -16),
            Container(
              width: 160,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.lime[400]!, Colors.green[600]!], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(100),
                border: Border(bottom: BorderSide(color: Colors.amber[800]!, width: 6)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber[900]!.withOpacity(0.85), borderRadius: BorderRadius.circular(999)),
                child: Text('Pulau 6: ${data.nama}', style: TextStyle(color: Colors.amber[100], fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (!data.unlocked)
            Positioned(
              top: -28,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: Colors.grey[700]!.withOpacity(0.9), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: Icon(Icons.lock, size: 16, color: Colors.grey[200]),
              ),
            ),
          AnimatedScale(
            scale: data.active ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.no == 2 && data.active)
                  Padding(padding: const EdgeInsets.only(bottom: 16), child: CustomPaint(size: const Size(64, 80), painter: _ZaidPainter())),
                if (data.no == 1 && data.completed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 20, color: Colors.amber[400]),
                        Icon(Icons.star, size: 24, color: Colors.amber[400]),
                        Icon(Icons.star, size: 20, color: Colors.amber[400]),
                      ],
                    ),
                  ),
                Container(
                  width: data.no == 1 ? 140 : 120,
                  height: data.no == 1 ? 44 : 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [data.gradientStart, data.gradientEnd], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(100),
                    border: data.active
                        ? Border.all(color: Colors.amber[300]!.withOpacity(0.8), width: 4)
                        : Border(bottom: BorderSide(color: Colors.amber[800]!.withOpacity(0.8), width: data.no == 1 ? 6 : 5)),
                    boxShadow: [BoxShadow(color: const Color(0xFF0F4C5C).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 8))],
                  ),
                  padding: EdgeInsets.only(top: data.no == 1 ? 10 : 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data.no == 1)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), decoration: BoxDecoration(color: Colors.green[900]!.withOpacity(0.75), borderRadius: BorderRadius.circular(999)), child: Text('Pulau 1: ${data.nama}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9))),
                      Text('Pulau ${data.no}: ${data.nama}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                ),
                if (data.active)
                  Container(
                    margin: const EdgeInsets.only(top: -12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.teal[500]!, Colors.green[600]!]),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 8)],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Text('MULAI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.3, size.width * 0.5, size.height / 2);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.7, size.width, size.height / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CastlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = Colors.grey[200]!;
    canvas.drawRect(Rect.fromLTWH(20, 38, 22, 48), paint);
    canvas.drawPath(Path()..moveTo(16, 38)..lineTo(31, 18)..lineTo(46, 38)..close(), Paint()..color = Colors.amber[700]!);
    canvas.drawRect(Rect.fromLTWH(98, 38, 22, 48), paint);
    canvas.drawPath(Path()..moveTo(94, 38)..lineTo(109, 18)..lineTo(124, 38)..close(), Paint()..color = Colors.amber[700]!);
    paint.color = Colors.grey[50]!;
    canvas.drawRect(Rect.fromLTWH(42, 28, 56, 58), paint);
    canvas.drawPath(Path()..moveTo(38, 28)..lineTo(70, 4)..lineTo(102, 28)..close(), Paint()..color = Colors.teal[700]!);
    paint.color = Colors.brown[800]!;
    canvas.drawPath(Path()..moveTo(58, 86)..lineTo(58, 64)..arcToPoint(const Offset(82, 64), radius: Radius.circular(12))..lineTo(82, 86)..close(), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ZaidPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(Path()..moveTo(18, 24)..quadraticBezierTo(18, 12, 32, 12)..quadraticBezierTo(46, 12, 46, 24)..close(), Paint()..color = Colors.white..style = PaintingStyle.fill..strokeWidth = 1.5);
    canvas.drawCircle(const Offset(32, 30), 13, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawCircle(const Offset(27, 29), 2, Paint()..color = Colors.grey[900]!);
    canvas.drawCircle(const Offset(37, 29), 2, Paint()..color = Colors.grey[900]!);
    canvas.drawPath(Path()..moveTo(28, 34)..quadraticBezierTo(32, 38, 36, 34), Paint()..color = Colors.brown[900]!..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.round);
    canvas.drawPath(Path()..moveTo(20, 43)..quadraticBezierTo(32, 40, 44, 43)..lineTo(47, 62)..quadraticBezierTo(32, 65, 17, 62)..close(), Paint()..color = Colors.green[700]!);
    canvas.drawPath(Path()..moveTo(27, 42)..lineTo(32, 48)..lineTo(37, 42), Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawPath(Path()..moveTo(20, 45)..lineTo(13, 55), Paint()..color = Colors.green[700]!..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round);
    canvas.drawPath(Path()..moveTo(44, 45)..lineTo(51, 55), Paint()..color = Colors.green[700]!..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round);
    canvas.drawOval(Rect.fromCenter(center: const Offset(26, 66), width: 8, height: 5), Paint()..color = Colors.brown[900]!);
    canvas.drawOval(Rect.fromCenter(center: const Offset(38, 66), width: 8, height: 5), Paint()..color = Colors.brown[900]!);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}