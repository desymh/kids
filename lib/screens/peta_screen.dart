import 'dart:math';
import 'package:flutter/material.dart';
import 'tahapan_screen.dart';
import 'quiz_screen.dart';
import 'simulasi_screen.dart';

enum IslandState { locked, unlocked, completed }

class IslandInfo {
  final int number;
  final String label;
  final String subtitle;
  final String imagePath;
  final IslandState state;
  final int stars;

  const IslandInfo({
    required this.number,
    required this.label,
    required this.subtitle,
    required this.imagePath,
    required this.state,
    this.stars = 0,
  });

  bool get isLocked => state == IslandState.locked;
  bool get isUnlocked => state == IslandState.unlocked;
  bool get isCompleted => state == IslandState.completed;
}

class PetaScreen extends StatefulWidget {
  const PetaScreen({super.key});

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> {
  late final ScrollController _scrollController;

  static const double _canvasHeight = 1350.0;
  static const double _horizonY = 260.0;

  final List<IslandInfo> _islands = const [
    IslandInfo(
      number: 1,
      label: 'Pulau 1: Pondasi Islam',
      subtitle: 'Dua Kalimat Syahadat & Rukun Islam',
      imagePath: 'assets/images/pulau_1_islam.png',
      state: IslandState.completed,
      stars: 3,
    ),
    IslandInfo(
      number: 2,
      label: 'Pulau 2: Thaharah',
      subtitle: 'Macam Air, Najis & Rukun Wudhu',
      imagePath: 'assets/images/pulau_2_thaharah.png',
      state: IslandState.unlocked,
      stars: 2,
    ),
    IslandInfo(
      number: 3,
      label: 'Pulau 3: Ibadah Shalat',
      subtitle: 'Urutan Gerakan & Bacaan Shalat',
      imagePath: 'assets/images/pulau_3_shalat.png',
      state: IslandState.locked,
    ),
    IslandInfo(
      number: 4,
      label: 'Pulau 4: Ibadah Puasa',
      subtitle: 'Niat, Sunnah & Pembatal Puasa',
      imagePath: 'assets/images/pulau_4_puasa.png',
      state: IslandState.locked,
    ),
    IslandInfo(
      number: 5,
      label: 'Pulau 5: Doa & Adab',
      subtitle: 'Doa Harian & Kasus Adab Muslim',
      imagePath: 'assets/images/pulau_5_adab.png',
      state: IslandState.locked,
    ),
    IslandInfo(
      number: 6,
      label: 'Pulau 6: Ujian Akhir',
      subtitle: 'Evaluasi Komprehensif Bab 1–5',
      imagePath: 'assets/images/pulau_6_istana.png',
      state: IslandState.locked,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Otomatis ter-scroll ke paling bawah (Pulau 1 & 2) saat layar pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onIslandTap(IslandInfo island) {
    if (island.isLocked) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Selesaikan pulau sebelumnya untuk membuka pulau ini!',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _showStageBottomSheet(island);
    }
  }

  void _showStageBottomSheet(IslandInfo island) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StageSelectionSheet(island: island),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    // Titik tengah setiap pulau dari Pulau 1 (bawah) menuju Pulau 6 (atas) untuk alur kurva lengkung S
    final islandCenters = <Offset>[
      Offset(16.0 + 82.5, 1040.0 + 62.0), // Pulau 1 (Bawah Kiri)
      Offset(screenW - 16.0 - 82.5, 860.0 + 62.0), // Pulau 2 (Kanan)
      Offset(20.0 + 82.5, 680.0 + 62.0), // Pulau 3 (Kiri)
      Offset(screenW - 16.0 - 82.5, 500.0 + 62.0), // Pulau 4 (Kanan)
      Offset(16.0 + 82.5, 320.0 + 62.0), // Pulau 5 (Kiri)
      Offset(screenW / 2, 130.0 + 115.0), // Pulau 6 (Atas Tengah, tepat di pangkal Istana)
    ];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Layer Peta Scrollable
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: screenW,
              height: _canvasHeight,
              child: Stack(
                children: [
                  // Latar Belakang Laut Hijau-Tosca di Bawah Horizon
                  Positioned(
                    top: _horizonY,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF72C5C1), // Hijau tosca cerah di batas horizon
                            Color(0xFF53AEA9), // Lebih dalam di bagian bawah
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Latar Langit Biru Cerah, Awan Lembut & Garis Horizon (y = 260)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SkyAndCloudPainter(horizonY: _horizonY),
                    ),
                  ),

                  // Garis Ombak Air Putih Tipis Transparan
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SeaWavePainter(horizonY: _horizonY),
                    ),
                  ),

                  // Jalur Titik-Titik Melengkung Alami (Curved Dotted Path) Menghubungkan Pulau 1 s/d 6
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CurvedPathPainter(centers: islandCenters),
                    ),
                  ),

                  // Pulau 6: Ujian Akhir (Paling Atas Tengah, Ukuran Gagah Lebar 215)
                  Positioned(
                    top: 130.0,
                    left: (screenW - 215.0) / 2,
                    child: _IslandWidget(
                      island: _islands[5],
                      width: 215.0,
                      height: 160.0,
                      onTap: () => _onIslandTap(_islands[5]),
                    ),
                  ),

                  // Pulau 5: Doa & Adab (Kiri, Lebar 165)
                  Positioned(
                    top: 320.0,
                    left: 16.0,
                    child: _IslandWidget(
                      island: _islands[4],
                      width: 165.0,
                      height: 123.0,
                      onTap: () => _onIslandTap(_islands[4]),
                    ),
                  ),

                  // Pulau 4: Ibadah Puasa (Kanan, Lebar 165)
                  Positioned(
                    top: 500.0,
                    right: 16.0,
                    child: _IslandWidget(
                      island: _islands[3],
                      width: 165.0,
                      height: 123.0,
                      onTap: () => _onIslandTap(_islands[3]),
                    ),
                  ),

                  // Pulau 3: Ibadah Shalat (Kiri, Lebar 165)
                  Positioned(
                    top: 680.0,
                    left: 20.0,
                    child: _IslandWidget(
                      island: _islands[2],
                      width: 165.0,
                      height: 123.0,
                      onTap: () => _onIslandTap(_islands[2]),
                    ),
                  ),

                  // Pulau 2: Thaharah (Kanan, Lebar 165 - Karakter Menjorok di Atas Pulau + Tombol Mulai)
                  Positioned(
                    top: 860.0,
                    right: 16.0,
                    child: _IslandWidget(
                      island: _islands[1],
                      width: 165.0,
                      height: 123.0,
                      hasStandingMascot: true,
                      hasStartButton: true,
                      onTap: () => _onIslandTap(_islands[1]),
                    ),
                  ),

                  // Pulau 1: Pondasi Islam (Bawah Kiri, Lebar 165 - Tampil Penuh Bersama Bintang Emas)
                  Positioned(
                    top: 1040.0,
                    left: 16.0,
                    child: _IslandWidget(
                      island: _islands[0],
                      width: 165.0,
                      height: 123.0,
                      hasStars: true,
                      onTap: () => _onIslandTap(_islands[0]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Header Melayang di Bagian Atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Tombol Kembali Bulat Putih
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E6F68), size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Banner Judul Membulat "PETA PETUALANGAN" di Tengah
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF2F8F83), width: 1.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.explore_rounded, color: Color(0xFF2E8B57), size: 18),
                              SizedBox(width: 6),
                              Text(
                                'PETA PETUALANGAN',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E6F68),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Indikator Bintang Emas Pemain
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF2F8F83), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                          SizedBox(width: 4),
                          Text(
                            '12',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF1E4E48)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter: Jalur Titik-Titik Melengkung Halus S-Curve (Curved Dotted Path)
class CurvedPathPainter extends CustomPainter {
  final List<Offset> centers;

  CurvedPathPainter({required this.centers});

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    // Membentuk path kurva melengkung halus menghubungkan Pulau 1 s/d Pulau 6
    final path = Path();
    path.moveTo(centers[0].dx, centers[0].dy);

    for (int i = 0; i < centers.length - 1; i++) {
      final p1 = centers[i];
      final p2 = centers[i + 1];

      // Titik kontrol kurva S yang luwes dan dinamis
      final double midY = (p1.dy + p2.dy) / 2;
      final cp1 = Offset(p1.dx, midY);
      final cp2 = Offset(p2.dx, midY);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    final dotFillPaint = Paint()
      ..color = const Color(0xFFFDF8EE) // Krem putih bersih
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = const Color(0xFF4CA6A2) // Border hijau tosca tipis
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final dotShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.14)
      ..style = PaintingStyle.fill;

    const double spacing = 19.0; // Jarak antar titik
    const double dotRadius = 6.0; // Ukuran titik batu bulat

    for (final metric in path.computeMetrics()) {
      final double totalLen = metric.length;
      // Membatasi awal dan akhir agar titik tidak menumpuk di pusat pulau
      const double startOffset = 55.0;
      final double endOffset = totalLen - 65.0;

      for (double d = startOffset; d <= endOffset; d += spacing) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) {
          final pos = tangent.position;
          // Bayangan lembut di bawah titik
          canvas.drawCircle(Offset(pos.dx, pos.dy + 1.8), dotRadius, dotShadowPaint);
          // Isi krem putih
          canvas.drawCircle(pos, dotRadius, dotFillPaint);
          // Garis tepi tosca
          canvas.drawCircle(pos, dotRadius, dotBorderPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// CustomPainter: Langit Biru Cerah, Awan Lembut & Garis Horizon Pemisah Laut
class SkyAndCloudPainter extends CustomPainter {
  final double horizonY;

  SkyAndCloudPainter({required this.horizonY});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Langit biru-putih cerah di atas horizon
    final skyPaint = Paint()..color = const Color(0xFFE6F7FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

    // 2. Awan putih lembut di langit
    final cloudPaint1 = Paint()..color = Colors.white.withOpacity(0.88);
    final cloudPaint2 = Paint()..color = Colors.white.withOpacity(0.68);

    // Awan Kiri
    _drawCloud(canvas, Offset(size.width * 0.16, 75), 34, cloudPaint1);
    // Awan Kanan
    _drawCloud(canvas, Offset(size.width * 0.82, 88), 38, cloudPaint1);
    // Awan Tengah Belakang Istana
    _drawCloud(canvas, Offset(size.width * 0.50, 65), 30, cloudPaint2);

    // 3. Garis batas horizon tipis Color(0xFF4CA6A2)
    final horizonPaint = Paint()
      ..color = const Color(0xFF4CA6A2)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), horizonPaint);
  }

  void _drawCloud(Canvas canvas, Offset center, double baseR, Paint paint) {
    canvas.drawCircle(center, baseR, paint);
    canvas.drawCircle(Offset(center.dx - baseR * 0.7, center.dy + baseR * 0.2), baseR * 0.65, paint);
    canvas.drawCircle(Offset(center.dx + baseR * 0.7, center.dy + baseR * 0.2), baseR * 0.7, paint);
    canvas.drawCircle(Offset(center.dx + baseR * 0.35, center.dy - baseR * 0.2), baseR * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// CustomPainter: Garis Ombak Air Tipis Putih Transparan di Laut
class SeaWavePainter extends CustomPainter {
  final double horizonY;

  SeaWavePainter({required this.horizonY});

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final positions = [
      Offset(size.width * 0.16, horizonY + 30),
      Offset(size.width * 0.75, horizonY + 60),
      Offset(size.width * 0.40, horizonY + 160),
      Offset(size.width * 0.82, horizonY + 240),
      Offset(size.width * 0.18, horizonY + 320),
      Offset(size.width * 0.62, horizonY + 410),
      Offset(size.width * 0.14, horizonY + 500),
      Offset(size.width * 0.78, horizonY + 590),
      Offset(size.width * 0.36, horizonY + 680),
      Offset(size.width * 0.70, horizonY + 770),
      Offset(size.width * 0.18, horizonY + 860),
      Offset(size.width * 0.60, horizonY + 950),
    ];

    for (final pos in positions) {
      final path = Path();
      path.moveTo(pos.dx, pos.dy);
      path.quadraticBezierTo(pos.dx + 16, pos.dy - 6, pos.dx + 32, pos.dy);
      path.quadraticBezierTo(pos.dx + 48, pos.dy - 6, pos.dx + 64, pos.dy);
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Widget Representasi Tiap Pulau dengan Label Putih Bersih Ceria
class _IslandWidget extends StatelessWidget {
  final IslandInfo island;
  final double width;
  final double height;
  final bool hasStandingMascot;
  final bool hasStartButton;
  final bool hasStars;
  final VoidCallback onTap;

  const _IslandWidget({
    required this.island,
    required this.width,
    required this.height,
    this.hasStandingMascot = false,
    this.hasStartButton = false,
    this.hasStars = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget islandImage = Image.asset(
      island.imagePath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.terrain_rounded,
        size: height,
        color: Colors.teal[300],
      ),
    );

    // Pulau Locked: Menggunakan ColorFilter BlendMode.srcATop agar bagian transparan PNG tetap bersih menyatu dengan laut
    if (island.isLocked) {
      islandImage = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.35),
          BlendMode.srcATop,
        ),
        child: Opacity(
          opacity: 0.72,
          child: islandImage,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gambar Pulau Utama & Gembok 3D
              Stack(
                alignment: Alignment.center,
                children: [
                  islandImage,
                  // Ikon Gembok 3D Bulat Bersih di Tengah Pulau Locked
                  if (island.isLocked)
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF374151).withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),

              // Label Kartu Kapsul Putih Bersih dengan Border Hijau Tosca Tebal 2px Ceria
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF2F8F83),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  island.label,
                  style: const TextStyle(
                    color: Color(0xFF1E4E48),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // Indikator 3 Bintang Emas di Bawah Label (Pulau 1 Completed)
              if (hasStars && island.stars > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFBBF24),
                      size: 22,
                    ),
                  ),
                ),
              ],

              // Tombol Hijau Timbul 3D "MULAI" (Pulau 2 Unlocked)
              if (hasStartButton && island.isUnlocked) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFF1E8449), width: 3.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF27AE60).withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'MULAI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Karakter Zaid & Aisyah Berdiri Menjorok Nyata di Atas Daratan Pulau 2
          if (hasStandingMascot)
            Positioned(
              left: 18,
              top: -18,
              child: Image.asset(
                'assets/images/mascot_berdua.png',
                height: 85,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
        ],
      ),
    );
  }
}

// Modal Bottom Sheet: Pilihan Tahap 1 sampai Tahap 4 saat Pulau Terbuka Diketuk
class _StageSelectionSheet extends StatelessWidget {
  final IslandInfo island;

  const _StageSelectionSheet({required this.island});

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'title': 'Tahap 1: Pengenalan Dasar', 'diff': 'Easy', 'color': const Color(0xFF2ECC71), 'unlocked': true, 'done': island.isCompleted},
      {'title': 'Tahap 2: Simulasi Praktik', 'diff': 'Medium', 'color': const Color(0xFF3498DB), 'unlocked': true, 'done': island.stars >= 2},
      {'title': 'Tahap 3: Studi Kasus Harian', 'diff': 'Hard', 'color': const Color(0xFFE67E22), 'unlocked': island.stars >= 2, 'done': false},
      {'title': 'Tahap 4: Ujian Akhir Pulau', 'diff': 'Expert', 'color': const Color(0xFFE74C3C), 'unlocked': island.stars >= 3, 'done': false},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Header Info Pulau
          Row(
            children: [
              Image.asset(
                island.imagePath,
                width: 72,
                height: 56,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      island.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E4E48),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      island.subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Daftar 4 Tahap
          ...List.generate(stages.length, (i) {
            final st = stages[i];
            final unlocked = st['unlocked'] as bool;
            final done = st['done'] as bool;
            final diffColor = st['color'] as Color;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: unlocked ? Colors.white : Colors.grey[50],
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: unlocked ? const Color(0xFFC8E6D7) : Colors.grey[200]!,
                  width: 1.5,
                ),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFF2ECC71).withOpacity(0.15)
                          : (unlocked ? diffColor.withOpacity(0.15) : Colors.grey[200]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done
                          ? Icons.check_circle_rounded
                          : (unlocked ? Icons.play_arrow_rounded : Icons.lock_rounded),
                      color: done
                          ? const Color(0xFF2ECC71)
                          : (unlocked ? diffColor : Colors.grey[400]),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: unlocked ? const Color(0xFF1E293B) : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          st['diff'] as String,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: diffColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: unlocked
                        ? () {
                            Navigator.pop(context);
                            if (island.number == 2 && i == 1) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SimulasiScreen()),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizScreen(
                                    idPulau: 'pulau${island.number}',
                                    tahap: i + 1,
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B57),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      done ? 'Ulangi' : 'Main',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          // Tombol Buka Halaman Tahapan Lengkap
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final namaPulau = island.label.replaceAll(RegExp(r'^Pulau \d+:\s*'), '');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TahapanScreen(
                      pulauNo: island.number,
                      pulauNama: namaPulau,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.list_alt_rounded, size: 18),
              label: const Text(
                'Buka Halaman Tahapan Lengkap',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E6F68),
                side: const BorderSide(color: Color(0xFF1E6F68), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
