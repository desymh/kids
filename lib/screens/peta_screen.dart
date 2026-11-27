import 'package:flutter/material.dart';
import 'adventure_screen.dart';
import '../core/fsm_controller.dart';
import '../core/storage_service.dart';

class PetaScreen extends StatefulWidget {
  const PetaScreen({super.key});

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> {
  final StorageService _storage = StorageService();
  final ScrollController _scroll = ScrollController();

  final List<Map<String, dynamic>> _pulau = [
    {'no': 1, 'nama': 'Pondasi Islam', 'asset': 'assets/images/pulau_1_islam.png', 'width': 160.0, 'left': 40.0, 'top': 900.0},
    {'no': 2, 'nama': 'Thaharah', 'asset': 'assets/images/pulau_2_thaharah.png', 'width': 160.0, 'left': 200.0, 'top': 750.0},
    {'no': 3, 'nama': 'Ibadah Shalat', 'asset': 'assets/images/pulau_3_shalat.png', 'width': 160.0, 'left': 40.0, 'top': 600.0},
    {'no': 4, 'nama': 'Ibadah Puasa', 'asset': 'assets/images/pulau_4_puasa.png', 'width': 160.0, 'left': 200.0, 'top': 450.0},
    {'no': 5, 'nama': 'Doa & Adab', 'asset': 'assets/images/pulau_5_adab.png', 'width': 160.0, 'left': 40.0, 'top': 300.0},
    {'no': 6, 'nama': 'Ujian Akhir', 'asset': 'assets/images/pulau_6_istana.png', 'width': 200.0, 'left': 140.0, 'top': 120.0},
  ];

  final Map<int, String> _status = {};
  final Map<int, int> _stars = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _loadStatus() async {
    final states = await _storage.getFsmStates();
    for (final p in _pulau) {
      final no = p['no'] as int;
      final state = states[ProgressionFSM.islandKey(no)] ?? LevelState.locked;
      _status[no] = state.name;
      _stars[no] = await _storage.getIslandStars(no);
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = 1100.0;
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.teal[800]), onPressed: () => Navigator.pop(context)),
        title: Text('Peta Petualangan', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal[900])),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              // Background gradient
              Container(
                height: height,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE6F7FA), Color(0xFF72C5C1), Color(0xFF53AEA9)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Waves custom paint
              Positioned.fill(child: CustomPaint(painter: _WavePainter())),
              // Path custom paint
              Positioned.fill(child: CustomPaint(painter: _PathPainter())),
              // Islands
              ..._pulau.map((p) {
                final no = p['no'] as int;
                final status = _status[no] ?? 'locked';
                final unlocked = status != 'locked';
                final completed = status == 'completed';
                return Positioned(
                  left: p['left'] as double,
                  top: p['top'] as double,
                  child: GestureDetector(
                    onTap: unlocked
                        ? () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => AdventureScreen(pulauId: no, namaPulau: p['nama'] as String)));
                            if (mounted) await _loadStatus();
                          }
                        : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pulau ini masih terkunci!'), backgroundColor: Colors.red)),
                    child: Column(
                      children: [
                        if (status == 'unlocked')
                          Image.asset('assets/images/mascot_berdua.png', height: 80),
                        Opacity(
                          opacity: status == 'locked' ? 0.72 : 1.0,
                          child: Image.asset(p['asset'] as String, width: p['width'] as double),
                        ),
                        if (status == 'locked')
                          const Icon(Icons.lock, color: Colors.white, size: 32),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                          child: Text('Pulau $no: ${p['nama']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        if (completed)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              3,
                              (i) => Icon(
                                Icons.star,
                                color: i < (_stars[no] ?? 0) ? Colors.amber : Colors.grey[300],
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    for (double y = size.height * 0.5; y < size.height; y += 40) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 60) {
        path.quadraticBezierTo(x + 15, y - 8, x + 30, y);
        path.quadraticBezierTo(x + 45, y + 8, x + 60, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF4CA6A2)..strokeWidth = 3..style = PaintingStyle.stroke;
    final stonePaint = Paint()..color = const Color(0xFFFDF8EE);
    final stoneBorder = Paint()..color = const Color(0xFF4CA6A2)..style = PaintingStyle.stroke..strokeWidth = 2;

    final points = [
      Offset(120, 980),
      Offset(280, 830),
      Offset(120, 680),
      Offset(280, 530),
      Offset(120, 380),
      Offset(240, 220),
    ];

    for (int i = 0; i < points.length - 1; i++) {
      final path = Path();
      path.moveTo(points[i].dx, points[i].dy);
      path.quadraticBezierTo((points[i].dx + points[i + 1].dx) / 2, (points[i].dy + points[i + 1].dy) / 2 - 40, points[i + 1].dx, points[i + 1].dy);
      canvas.drawPath(path, paint);
    }

    for (final p in points) {
      canvas.drawCircle(p, 6, stonePaint);
      canvas.drawCircle(p, 6, stoneBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}