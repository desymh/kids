import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/storage_service.dart';
import '../data/materi_data.dart';
import 'belajar_detail_screen.dart';
import 'simulasi_screen.dart';
import 'toko_screen.dart';

const _boardAspectRatio = 1.12;
const _boardSpacing = 22.0;
const _materiBoardHeightRatio = 0.44;

class BelajarScreen extends StatefulWidget {
  const BelajarScreen({super.key});

  @override
  State<BelajarScreen> createState() => _BelajarScreenState();
}

class _BelajarScreenState extends State<BelajarScreen> {
  final StorageService _storage = StorageService();
  final Map<int, bool> _selesai = {};
  int _koin = StorageService.defaultKoin;
  int _nyawa = StorageService.defaultNyawa;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final koin = await _storage.getKoin();
    final nyawa = await _storage.getNyawa();
    final completion = <int, bool>{};
    for (var i = 0; i < MateriData.dataBabBelajar.length; i++) {
      final bab = MateriData.dataBabBelajar[i];
      final key = 'bab_${bab['bab']}_selesai';
      completion[i] = await _storage.getProgres(key);
    }
    if (!mounted) return;
    setState(() {
      _koin = koin;
      _nyawa = nyawa;
      _selesai.addAll(completion);
    });
  }

  Future<void> _openSubMateri(int babIndex) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubMateriListScreen(
          babIndex: babIndex,
          bab: MateriData.dataBabBelajar[babIndex],
        ),
      ),
    );
    if (mounted) await _loadStatus();
  }

  Future<void> _openSimulation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SimulasiScreen()),
    );
    if (mounted) await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return _LearningScaffold(
      backgroundKey: 'belajar-background',
      title: 'Pilih Bab Pelajaran',
      titleKey: const ValueKey('belajar-title-banner'),
      coins: _koin,
      lives: _nyawa,
      coinsKey: const ValueKey('belajar-coins'),
      livesKey: const ValueKey('belajar-lives'),
      onBack: () => Navigator.pop(context),
      child: Stack(
        children: [
          Positioned.fill(
            child: ListView.separated(
              key: const ValueKey('belajar-bab-list'),
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: MateriData.dataBabBelajar.length,
              separatorBuilder: (_, __) => const SizedBox(width: _boardSpacing),
              itemBuilder: (_, babIndex) {
                final bab = MateriData.dataBabBelajar[babIndex];
                final babNumber = bab['bab'] as int;
                return Center(
                  child: _BoardTile(
                    key: ValueKey('bab-board-$babNumber'),
                    imageKey: ValueKey('bab-board-image-$babNumber'),
                    asset: 'assets/images/icon_bab.png',
                    title: _babBoardTitle(bab),
                    textColor: const Color(0xFF5A3B1B),
                    shadowColor: const Color(0x66FFFFFF),
                    titleScale: 1.35,
                    splitTitle: true,
                    floating: true,
                    floatingPhase: babIndex * 0.18,
                    heightRatio: 0.48,
                    done: _selesai[babIndex] ?? false,
                    onTap: () => _openSubMateri(babIndex),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 20,
            bottom: 12,
            child: _SimulasiButton(onTap: _openSimulation),
          ),
        ],
      ),
    );
  }
}

class SubMateriListScreen extends StatefulWidget {
  final int babIndex;
  final Map<String, dynamic> bab;

  const SubMateriListScreen({
    super.key,
    required this.babIndex,
    required this.bab,
  });

  @override
  State<SubMateriListScreen> createState() => _SubMateriListScreenState();
}

class _SubMateriListScreenState extends State<SubMateriListScreen> {
  final StorageService _storage = StorageService();
  int _koin = StorageService.defaultKoin;
  int _nyawa = StorageService.defaultNyawa;
  bool _selesai = false;

  List<Map<String, dynamic>> get _items =>
      (widget.bab['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final koin = await _storage.getKoin();
    final nyawa = await _storage.getNyawa();
    final selesai = await _storage.getProgres(
      'bab_${widget.bab['bab']}_selesai',
    );
    if (!mounted) return;
    setState(() {
      _koin = koin;
      _nyawa = nyawa;
      _selesai = selesai;
    });
  }

  Future<void> _openMateri(int itemIndex) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BelajarDetailScreen(
          babIndex: widget.babIndex,
          bab: widget.bab,
          itemIndex: itemIndex,
        ),
      ),
    );
    if (mounted) await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return _LearningScaffold(
      backgroundKey: 'submateri-background',
      title: widget.bab['judul']?.toString() ?? 'Pilih Materi',
      titleKey: const ValueKey('submateri-title-banner'),
      coins: _koin,
      lives: _nyawa,
      coinsKey: const ValueKey('submateri-coins'),
      livesKey: const ValueKey('submateri-lives'),
      onBack: () => Navigator.pop(context),
      child: items.isEmpty
          ? const Center(child: Text('Materi belum tersedia.'))
          : _buildMateriList(items),
    );
  }

  Widget _buildMateriList(List<Map<String, dynamic>> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        var boardHeight = screenHeight * _materiBoardHeightRatio;
        if (items.length == 3) {
          final maxBoardWidth =
              (constraints.maxWidth - 48 - 2 * _boardSpacing) / 3;
          boardHeight = math.min(
            boardHeight,
            maxBoardWidth / _boardAspectRatio,
          );
        }
        final boardWidth = boardHeight * _boardAspectRatio;
        final contentWidth = items.length * boardWidth +
            (items.length - 1) * _boardSpacing;
        final horizontalPadding =
            items.length == 3 ? (constraints.maxWidth - contentWidth) / 2 : 24.0;

        return ListView.separated(
          key: const ValueKey('submateri-list'),
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: _boardSpacing),
          itemBuilder: (_, itemIndex) {
            final item = items[itemIndex];
            return Center(
              child: _BoardTile(
                key: ValueKey('materi-board-$itemIndex'),
                imageKey: ValueKey('materi-board-image-$itemIndex'),
                asset: 'assets/images/icon_materi.png',
                title: _materiBoardTitle(item),
                textColor: const Color(0xFF5A3B1B),
                shadowColor: const Color(0x66FFFFFF),
                floating: true,
                floatingPhase: itemIndex * 0.18,
                heightRatio: boardHeight / screenHeight,
                done: _selesai,
                onTap: () => _openMateri(itemIndex),
              ),
            );
          },
        );
      },
    );
  }
}

class _LearningScaffold extends StatelessWidget {
  final String backgroundKey;
  final String title;
  final Key titleKey;
  final int coins;
  final int lives;
  final Key coinsKey;
  final Key livesKey;
  final VoidCallback onBack;
  final Widget child;

  const _LearningScaffold({
    required this.backgroundKey,
    required this.title,
    required this.titleKey,
    required this.coins,
    required this.lives,
    required this.coinsKey,
    required this.livesKey,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_menu_utama.png',
            key: ValueKey(backgroundKey),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/bg_menu_utama.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  _LearningHeader(
                    title: title,
                    titleKey: titleKey,
                    coins: coins,
                    lives: lives,
                    coinsKey: coinsKey,
                    livesKey: livesKey,
                    onBack: onBack,
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningHeader extends StatelessWidget {
  final String title;
  final Key titleKey;
  final int coins;
  final int lives;
  final Key coinsKey;
  final Key livesKey;
  final VoidCallback onBack;

  const _LearningHeader({
    required this.title,
    required this.titleKey,
    required this.coins,
    required this.lives,
    required this.coinsKey,
    required this.livesKey,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bannerWidth =
              (constraints.maxWidth - 230).clamp(120.0, 420.0).toDouble();
          return Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: const Color(0xFF244B43),
                  tooltip: 'Kembali',
                  onPressed: onBack,
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: bannerWidth),
                  child: Container(
                    key: titleKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E8B70), Color(0xFF1D6657)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF1D6657).withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: WalletStatsRow(
                  coinsKey: coinsKey,
                  livesKey: livesKey,
                  coins: coins,
                  lives: lives,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BoardTile extends StatefulWidget {
  final Key imageKey;
  final String asset;
  final String title;
  final Color textColor;
  final Color shadowColor;
  final double titleScale;
  final bool splitTitle;
  final bool floating;
  final double floatingPhase;
  final double heightRatio;
  final bool done;
  final VoidCallback onTap;

  const _BoardTile({
    super.key,
    required this.imageKey,
    required this.asset,
    required this.title,
    this.textColor = Colors.white,
    this.shadowColor = const Color(0x66000000),
    this.titleScale = 1.0,
    this.splitTitle = false,
    this.floating = false,
    this.floatingPhase = 0.0,
    required this.heightRatio,
    required this.done,
    required this.onTap,
  });

  @override
  State<_BoardTile> createState() => _BoardTileState();
}

class _BoardTileState extends State<_BoardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.floating) _floatController.repeat();
  }

  @override
  void didUpdateWidget(covariant _BoardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.floating == oldWidget.floating) return;
    if (widget.floating) {
      _floatController.repeat();
    } else {
      _floatController.stop();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  TextStyle _titleStyle(double size) {
    return TextStyle(
      color: widget.textColor,
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1.25,
      shadows: [
        Shadow(
          color: widget.shadowColor,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardHeight = MediaQuery.sizeOf(context).height * widget.heightRatio;
    final boardWidth = boardHeight * _boardAspectRatio;
    final baseFontSize = (boardHeight * 0.075).clamp(13.0, 20.0).toDouble();
    final fontSize = baseFontSize * widget.titleScale;
    final titleLines = widget.title.split('\n');
    final hasSplitTitle = widget.splitTitle && titleLines.length > 1;

    return SizedBox(
      width: boardWidth,
      height: boardHeight,
      child: Semantics(
        button: true,
        label: widget.title,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final wave = widget.floating
                  ? math.sin(
                      (_floatController.value + widget.floatingPhase) *
                          2 *
                          math.pi,
                    )
                  : 0.0;
              return Transform.translate(
                offset: Offset(0, wave * 8),
                child: child,
              );
            },
            child: AnimatedScale(
              scale: _pressed ? 0.95 : 1,
              duration: _pressed
                  ? const Duration(milliseconds: 70)
                  : const Duration(milliseconds: 240),
              curve: Curves.elasticOut,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      widget.asset,
                      key: widget.imageKey,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      boardWidth * 0.17,
                      boardHeight * (hasSplitTitle ? 0.10 : 0.19),
                      boardWidth * 0.17,
                      boardHeight * (hasSplitTitle ? 0.34 : 0.19),
                    ),
                    child: hasSplitTitle
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                titleLines.first,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _titleStyle(fontSize),
                              ),
                              SizedBox(height: boardHeight * 0.012),
                              Text(
                                titleLines.skip(1).join(' '),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _titleStyle(fontSize * 0.72).copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: _titleStyle(fontSize),
                          ),
                  ),
                  if (widget.done)
                    Positioned(
                      top: boardHeight * 0.07,
                      right: boardWidth * 0.09,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4C95D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF245F50),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimulasiButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SimulasiButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0xFF245F50).withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: const ValueKey('menu-simulasi'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/icon_wudhu_sholat_cropped.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              const Text(
                'SIMULASI PRAKTIK',
                style: TextStyle(
                  color: Color(0xFF244B43),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xFF2E8B70),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _babBoardTitle(Map<String, dynamic> bab) {
  final title = bab['judul']?.toString() ?? 'Bab Pelajaran';
  final parts = title.split(RegExp(r':\s*'));
  if (parts.length < 2) return title.toUpperCase();
  final heading = parts.first.toUpperCase();
  final subtitle = parts.skip(1).join(' ').toLowerCase();
  return '$heading\n$subtitle';
}

String _materiBoardTitle(Map<String, dynamic> item) {
  final title = item['judulKartu']?.toString() ?? 'Materi';
  return title
      .replaceAll(
        RegExp(r'\s*\(\s*Safinatun\s*Najah\s*\)', caseSensitive: false),
        '',
      )
      .trim();
}
