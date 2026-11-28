import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'adventure_screen.dart';
import 'toko_screen.dart';
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

  static const List<_Island> _pulau = [
    _Island(1, 'Pondasi Islam', 'assets/images/pulau_1_islam.png'),
    _Island(2, 'Thaharah', 'assets/images/pulau_2_thaharah.png'),
    _Island(3, 'Ibadah Shalat', 'assets/images/pulau_3_shalat.png'),
    _Island(4, 'Ibadah Puasa', 'assets/images/pulau_4_puasa.png'),
    _Island(6, 'Ujian Akhir', 'assets/images/pulau_6_istana.png'),
  ];

  final Map<int, LevelState> _status = {};
  final Map<int, int> _stars = {};
  int _koin = StorageService.defaultKoin;
  int _nyawa = StorageService.defaultNyawa;
  double? _activeCenterX;
  double _viewportWidth = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final koin = await _storage.getKoin();
    final nyawa = await _storage.getNyawa();
    final states = await _storage.getFsmStates();
    final stars = <int, int>{};
    final status = <int, LevelState>{};
    for (final island in _pulau) {
      status[island.no] =
          states[ProgressionFSM.islandKey(island.no)] ?? LevelState.locked;
      stars[island.no] = await _storage.getIslandStars(island.no);
    }
    if (!mounted) return;
    setState(() {
      _koin = koin;
      _nyawa = nyawa;
      _status.addAll(status);
      _stars.addAll(stars);
    });
  }

  Future<void> _openIsland(_Island island) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdventureScreen(
          pulauId: island.no,
          namaPulau: island.nama,
        ),
      ),
    );
    if (mounted) await _loadStatus();
  }

  void _centerActiveIsland() {
    if (!mounted || !_scroll.hasClients || _activeCenterX == null) return;
    final maxOffset = _scroll.position.maxScrollExtent;
    final target =
        (_activeCenterX! - _viewportWidth / 2).clamp(0.0, maxOffset).toDouble();
    if ((_scroll.offset - target).abs() < 1) return;
    _scroll.jumpTo(target);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.teal[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Peta Petualangan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.teal[900],
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WalletStatsRow(
              coinsKey: const ValueKey('peta-coins'),
              livesKey: const ValueKey('peta-lives'),
              coins: _koin,
              lives: _nyawa,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final layout = _MapLayout.fromViewport(viewport);
          _viewportWidth = viewport.width;
          final activeIndex = _pulau.indexWhere(
            (island) =>
                (_status[island.no] ??
                    (island.no == 1
                        ? LevelState.unlocked
                        : LevelState.locked)) ==
                LevelState.unlocked,
          );
          _activeCenterX =
              activeIndex >= 0 ? layout.centers[activeIndex].dx : null;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _centerActiveIsland());

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE6F7FA),
                      Color(0xFF72C5C1),
                      Color(0xFF53AEA9),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _WavePainter())),
              SingleChildScrollView(
                key: const ValueKey('peta-horizontal-scroll'),
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: layout.contentWidth,
                  height: viewport.height,
                  child: Stack(
                    key: const ValueKey('peta-landscape-map'),
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          key: const ValueKey('peta-bubble-path'),
                          painter: _BubblePathPainter(
                            layout.centers,
                            layout.islandSizes.first,
                          ),
                        ),
                      ),
                      for (var index = 0; index < _pulau.length; index++)
                        _buildIsland(
                          island: _pulau[index],
                          center: layout.centers[index],
                          islandSize: layout.islandSizes[index],
                        ),
                      if (activeIndex >= 0)
                        _buildAdventurePrompt(
                          island: _pulau[activeIndex],
                          center: layout.centers[activeIndex],
                          islandSize: layout.islandSizes[activeIndex],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdventurePrompt({
    required _Island island,
    required Offset center,
    required double islandSize,
  }) {
    final islandTop = center.dy - islandSize / 2;
    const characterHeightRatio = 0.36;
    const standingYRatio = 0.70;
    final characterHeight = math.min(110.0, islandSize * characterHeightRatio);
    final characterWidth = characterHeight * 129 / 225;
    const goWidth = 38.0;
    const goHeight = 24.0;
    const goGap = 6.0;
    final promptWidth = characterWidth + goWidth + goGap;

    return Positioned(
      key: const ValueKey('peta-adventure-action'),
      left: center.dx - promptWidth / 2,
      top: islandTop + islandSize * standingYRatio - characterHeight,
      width: promptWidth,
      height: characterHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: IgnorePointer(
              child: _AdventureZaid(
                key: const ValueKey('peta-active-avatar'),
                height: characterHeight,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: const Color(0xFF35A85F),
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
              shadowColor: const Color(0xFF326F69),
              child: InkWell(
                key: ValueKey('peta-go-${island.no}'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openIsland(island),
                child: SizedBox(
                  width: goWidth,
                  height: goHeight,
                  child: const Center(
                    child: Text(
                      'GO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIsland({
    required _Island island,
    required Offset center,
    required double islandSize,
  }) {
    final status = _status[island.no] ??
        (island.no == 1 ? LevelState.unlocked : LevelState.locked);
    final unlocked = status != LevelState.locked;

    return Positioned(
      left: center.dx - islandSize / 2,
      top: center.dy - islandSize / 2,
      width: islandSize,
      child: GestureDetector(
        key: ValueKey('peta-pulau-${island.no}'),
        behavior: HitTestBehavior.opaque,
        onTap: unlocked
            ? () => _openIsland(island)
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pulau ini masih terkunci!'),
                    backgroundColor: Colors.red,
                  ),
                ),
        child: Semantics(
          button: true,
          label:
              'Pulau ${ProgressionFSM.displayIslandNumber(island.no)}: ${island.nama}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: islandSize,
                height: islandSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: unlocked ? 1 : 0.62,
                        child: Image.asset(
                          island.asset,
                          key: ValueKey('peta-pulau-${island.no}-artwork'),
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    if (!unlocked)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              width: islandSize * 0.25,
                              height: islandSize * 0.25,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.9),
                                border: Border.all(
                                  color: Colors.teal.withValues(alpha: 0.35),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.lock,
                                color: Colors.teal[800],
                                size: islandSize * 0.14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: -islandSize * 0.04,
                      right: -islandSize * 0.04,
                      bottom: islandSize * 0.035,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: islandSize * 0.035,
                          vertical: islandSize * 0.022,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: Colors.teal.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          'Pulau ${ProgressionFSM.displayIslandNumber(island.no)}: ${island.nama}',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: math.min(13, islandSize * 0.072),
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            color: Colors.teal[900],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                key: ValueKey('peta-pulau-${island.no}-stars'),
                height: 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (starIndex) => Icon(
                      Icons.star,
                      color: unlocked && starIndex < (_stars[island.no] ?? 0)
                          ? Colors.amber
                          : Colors.grey[300],
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Island {
  final int no;
  final String nama;
  final String asset;

  const _Island(this.no, this.nama, this.asset);
}

const List<double> _nodeYFactors = [0.64, 0.36, 0.64, 0.36, 0.38];

class _MapLayout {
  final List<Offset> centers;
  final List<double> islandSizes;
  final double contentWidth;

  const _MapLayout(this.centers, this.islandSizes, this.contentWidth);

  factory _MapLayout.fromViewport(Size viewport) {
    final baseSize = math.max(148.0, viewport.height * 0.52);
    final finalSize = baseSize * 1.28;
    final islandSizes = List.generate(
      _nodeYFactors.length,
      (index) => index == _nodeYFactors.length - 1 ? finalSize : baseSize,
    );
    final gap = baseSize * 0.32;
    final padding = baseSize * 0.45;
    final centers = <Offset>[];
    var left = padding;
    for (var index = 0; index < islandSizes.length; index++) {
      centers.add(
        Offset(
          left + islandSizes[index] / 2,
          viewport.height * _nodeYFactors[index],
        ),
      );
      left += islandSizes[index] + gap;
    }
    return _MapLayout(
      centers,
      islandSizes,
      left - gap + padding,
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
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

class _BubblePathPainter extends CustomPainter {
  final List<Offset> points;
  final double islandSize;

  const _BubblePathPainter(this.points, this.islandSize);

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = const Color(0xFF326F69).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final fillPaint = Paint()
      ..color = const Color(0xFFE4FFFF).withValues(alpha: 0.62);
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < points.length - 1; index++) {
      final start = points[index];
      final end = points[index + 1];
      final control = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2 - islandSize * 0.08,
      );
      final distance = (end - start).distance;
      final bubbleCount = math.max(5, (distance / (islandSize * 0.18)).round());

      for (var step = 1; step < bubbleCount; step++) {
        final t = step / bubbleCount;
        final inverse = 1 - t;
        final point = Offset(
          inverse * inverse * start.dx +
              2 * inverse * t * control.dx +
              t * t * end.dx,
          inverse * inverse * start.dy +
              2 * inverse * t * control.dy +
              t * t * end.dy,
        );
        final radius = islandSize * (0.038 + (step % 3) * 0.008);
        canvas.drawCircle(point, radius + 2, shadowPaint);
        canvas.drawCircle(point, radius, fillPaint);
        canvas.drawCircle(point, radius, borderPaint);
        canvas.drawArc(
          Rect.fromCircle(center: point, radius: radius * 0.68),
          math.pi * 1.05,
          math.pi * 0.42,
          false,
          highlightPaint,
        );
        if (step.isEven) {
          canvas.drawCircle(
            point + Offset(radius * 0.95, -radius * 0.75),
            radius * 0.24,
            fillPaint,
          );
          canvas.drawCircle(
            point + Offset(radius * 0.95, -radius * 0.75),
            radius * 0.24,
            borderPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePathPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.islandSize != islandSize;
  }
}

class _AdventureZaid extends StatefulWidget {
  final double height;

  const _AdventureZaid({
    super.key,
    required this.height,
  });

  @override
  State<_AdventureZaid> createState() => _AdventureZaidState();
}

class _AdventureZaidState extends State<_AdventureZaid> {
  static const String _asset = 'assets/images/zaid_spritesheet.png';

  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  late final ImageStreamListener _imageListener;

  @override
  void initState() {
    super.initState();
    _imageListener = ImageStreamListener(_handleImage);
    _imageStream = const AssetImage(_asset).resolve(ImageConfiguration.empty);
    _imageStream!.addListener(_imageListener);
  }

  void _handleImage(ImageInfo value, bool synchronouslyLoaded) {
    if (!mounted) {
      value.dispose();
      return;
    }
    final previous = _imageInfo;
    setState(() => _imageInfo = value);
    previous?.dispose();
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    _imageInfo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * 129 / 225;
    return Semantics(
      label: 'Zaid siap berpetualang',
      image: true,
      child: SizedBox(
        width: width,
        height: widget.height,
        child: CustomPaint(
          key: const ValueKey('peta-adventure-zaid-paint'),
          painter: _AdventureZaidPainter(_imageInfo?.image),
        ),
      ),
    );
  }
}

class _AdventureZaidPainter extends CustomPainter {
  static const int _frameCount = 4;
  static const double _contentLeft = 12;
  static const double _contentTop = 65;
  static const double _contentWidth = 129;
  static const double _contentHeight = 225;

  final ui.Image? image;

  const _AdventureZaidPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.96,
        size.width * 0.64,
        size.height * 0.035,
      ),
      Paint()
        ..color = const Color(0xFF326F69).withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );

    final sprite = image;
    if (sprite == null) return;
    final frameWidth = sprite.width / _frameCount;
    final sourceLeft = math.min(
      _contentLeft,
      math.max(0.0, frameWidth - _contentWidth),
    );
    final source = Rect.fromLTWH(
      sourceLeft,
      _contentTop,
      _contentWidth,
      _contentHeight,
    );
    canvas.drawImageRect(
      sprite,
      source,
      Offset.zero & size,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = ui.FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _AdventureZaidPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
