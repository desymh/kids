import 'package:flutter/material.dart';

import '../core/storage_service.dart';

class TokoScreen extends StatefulWidget {
  const TokoScreen({super.key});

  @override
  State<TokoScreen> createState() => _TokoScreenState();
}

class _TokoScreenState extends State<TokoScreen> {
  static const _insufficientCoinsMessage =
      'Koinmu belum cukup! Yuk main petualangan dan kumpulkan koin dulu 🪙';

  final StorageService _storage = StorageService();
  int _koin = StorageService.defaultKoin;
  int _nyawa = StorageService.defaultNyawa;
  bool _buying = false;

  static const _packages = [
    _LifePackage(
      id: 1,
      lives: 1,
      price: 30,
      tag: '',
      gradient: [Color(0xFF55C7AE), Color(0xFF269B87)],
      shadowColor: Color(0xFF176B5D),
    ),
    _LifePackage(
      id: 2,
      lives: 3,
      price: 80,
      tag: 'Hemat!',
      gradient: [Color(0xFF72BEEF), Color(0xFF3B8FC9)],
      shadowColor: Color(0xFF245F8B),
    ),
    _LifePackage(
      id: 3,
      lives: 5,
      price: 120,
      tag: 'Favorit!',
      gradient: [Color(0xFFBE96F7), Color(0xFF8C5BD7)],
      shadowColor: Color(0xFF59389B),
    ),
    _LifePackage(
      id: 4,
      lives: 10,
      price: 220,
      tag: 'Lebih Hemat!',
      gradient: [Color(0xFF4DD6B5), Color(0xFF168A78)],
      shadowColor: Color(0xFF0C6658),
    ),
    _LifePackage(
      id: 5,
      lives: 15,
      price: 300,
      tag: 'Hemat Maksimal!',
      gradient: [Color(0xFFFFB86B), Color(0xFFE67E22)],
      shadowColor: Color(0xFFA85B16),
    ),
    _LifePackage(
      id: 6,
      lives: 20,
      price: 380,
      tag: '',
      gradient: [Color(0xFFFF8FA3), Color(0xFFD64565)],
      shadowColor: Color(0xFF9F2947),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final koin = await _storage.getKoin();
    final nyawa = await _storage.getNyawa();
    if (!mounted) return;
    setState(() {
      _koin = koin;
      _nyawa = nyawa;
    });
  }

  Future<void> _buyPackage(_LifePackage package) async {
    if (_buying) return;
    setState(() => _buying = true);

    final purchased = await _storage.beliNyawaDenganKoin(
      hargaKoin: package.price,
      jumlahNyawa: package.lives,
    );
    if (!mounted) return;
    setState(() => _buying = false);

    if (!purchased) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_insufficientCoinsMessage)),
      );
      return;
    }

    await _loadWallet();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          '🎉 Berhasil membeli Nyawa!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Nyawamu bertambah ${package.lives}. Terus semangat bertualang!',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Mantap!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F5EE),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_menu_utama.png',
            key: const ValueKey('shop-background'),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/bg_menu_utama.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Kembali',
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Toko Nyawa',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF244B43),
                          ),
                        ),
                      ),
                      WalletStatsRow(
                        coinsKey: const ValueKey('shop-coins'),
                        livesKey: const ValueKey('shop-lives'),
                        coins: _koin,
                        lives: _nyawa,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 360;
                        final cardWidth =
                            constraints.maxWidth < 560 ? 176.0 : 208.0;
                        final maxCardHeight = compact ? 250.0 : 300.0;
                        final cardHeight =
                            (constraints.maxHeight - (compact ? 8 : 64))
                                .clamp(160.0, maxCardHeight)
                                .toDouble();
                        return Column(
                          children: [
                            if (!compact) ...[
                              const Text(
                                'Pilih paket nyawa favoritmu!',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF244B43),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Geser ke samping untuk pilihan lainnya',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF52766F),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Expanded(
                              child: ListView.separated(
                                key: const ValueKey('shop-package-list'),
                                scrollDirection: Axis.horizontal,
                                physics: const ClampingScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 12 : 20,
                                  vertical: compact ? 4 : 8,
                                ),
                                itemCount: _packages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (_, index) {
                                  final package = _packages[index];
                                  return Center(
                                    child: SizedBox(
                                      width: cardWidth,
                                      height: cardHeight,
                                      child: _PackageCard(
                                        key: ValueKey(
                                          'shop-package-${package.id}',
                                        ),
                                        package: package,
                                        compact: compact,
                                        enabled: !_buying,
                                        onTap: () => _buyPackage(package),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatefulWidget {
  final _LifePackage package;
  final bool compact;
  final bool enabled;
  final VoidCallback onTap;

  const _PackageCard({
    super.key,
    required this.package,
    required this.compact,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final package = widget.package;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: _pressed
            ? const Duration(milliseconds: 70)
            : const Duration(milliseconds: 240),
        curve: Curves.elasticOut,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.65,
          child: Container(
            padding: EdgeInsets.all(widget.compact ? 10 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: package.gradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border(
                bottom: BorderSide(color: package.shadowColor, width: 7),
              ),
              boxShadow: [
                BoxShadow(
                  color: package.shadowColor.withValues(alpha: 0.32),
                  blurRadius: 5,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (package.tag.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      package.tag,
                      style: TextStyle(
                        fontSize: widget.compact ? 9 : 11,
                        fontWeight: FontWeight.w900,
                        color: package.shadowColor,
                      ),
                    ),
                  ),
                  SizedBox(height: widget.compact ? 4 : 10),
                ],
                Container(
                  width: widget.compact ? 46 : 70,
                  height: widget.compact ? 46 : 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: widget.compact ? 28 : 44,
                  ),
                ),
                SizedBox(height: widget.compact ? 6 : 12),
                Text(
                  '+${package.lives} ❤️ Nyawa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.compact ? 12 : 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: widget.compact ? 4 : 8),
                Text(
                  '${package.price} 🪙 Koin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.compact ? 10 : 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: widget.enabled ? widget.onTap : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.compact ? 8 : 14,
                        vertical: widget.compact ? 7 : 10,
                      ),
                      child: Text(
                        'Tukar',
                        style: TextStyle(
                          fontSize: widget.compact ? 10 : 12,
                          fontWeight: FontWeight.w900,
                          color: package.shadowColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WalletStatsRow extends StatelessWidget {
  final int coins;
  final int lives;
  final Key? coinsKey;
  final Key? livesKey;
  final double spacing;

  const WalletStatsRow({
    super.key,
    required this.coins,
    required this.lives,
    this.coinsKey,
    this.livesKey,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WalletCapsule(
          key: coinsKey,
          symbol: '🪙',
          value: '$coins',
          color: const Color(0xFFB7791F),
        ),
        SizedBox(width: spacing),
        _WalletCapsule(
          key: livesKey,
          symbol: '❤️',
          value: '$lives',
          color: const Color(0xFFD64545),
        ),
      ],
    );
  }
}

class _WalletCapsule extends StatelessWidget {
  final String symbol;
  final String value;
  final Color color;

  const _WalletCapsule({
    super.key,
    required this.symbol,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(symbol, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF244B43),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5F52).withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF355C55)),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

class _LifePackage {
  final int id;
  final int lives;
  final int price;
  final String tag;
  final List<Color> gradient;
  final Color shadowColor;

  const _LifePackage({
    required this.id,
    required this.lives,
    required this.price,
    required this.tag,
    required this.gradient,
    required this.shadowColor,
  });
}
