import 'package:flutter/material.dart';

import '../core/storage_service.dart';

class TokoScreen extends StatefulWidget {
  const TokoScreen({super.key});

  @override
  State<TokoScreen> createState() => _TokoScreenState();
}

class _TokoScreenState extends State<TokoScreen> with TickerProviderStateMixin {
  static const _insufficientCoinsMessage =
      'Koinmu belum cukup! Yuk main petualangan dan kumpulkan koin dulu 🪙';

  final StorageService _storage = StorageService();
  int _koin = StorageService.defaultKoin;
  int _nyawa = StorageService.defaultNyawa;
  bool _buying = false;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

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
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    _floatAnimation = Tween<double>(begin: -7, end: 7).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatController.repeat(reverse: true);
    _loadWallet();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
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
            'assets/images/bg_langit_masjid.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/bg_langit_masjid.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.white.withValues(alpha: 0.12)),
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
                      _WalletCapsule(
                        key: const ValueKey('shop-coins'),
                        symbol: '🪙',
                        value: '$_koin',
                        color: const Color(0xFFB7791F),
                      ),
                      const SizedBox(width: 8),
                      _WalletCapsule(
                        key: const ValueKey('shop-lives'),
                        symbol: '❤️',
                        value: '$_nyawa',
                        color: const Color(0xFFD64545),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 360;
                        return Row(
                          children: [
                            Expanded(
                              flex: compact ? 2 : 3,
                              child: _ShopGuide(
                                floatAnimation: _floatAnimation,
                                compact: compact,
                              ),
                            ),
                            SizedBox(width: compact ? 12 : 24),
                            Expanded(
                              flex: compact ? 5 : 6,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                    const SizedBox(height: 14),
                                  ],
                                  Expanded(
                                    child: Row(
                                      children: _packages.map((package) {
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                            ),
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
                                      }).toList(),
                                    ),
                                  ),
                                ],
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

class _ShopGuide extends StatelessWidget {
  final Animation<double> floatAnimation;
  final bool compact;

  const _ShopGuide({
    required this.floatAnimation,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!compact) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D5F52).withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              children: [
                Text(
                  'Butuh nyawa lagi?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E8B57),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tukar koinmu di sini, yuk!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF52766F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, floatAnimation.value),
              child: child,
            ),
            child: Image.asset(
              'assets/images/mascot_berdua.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.emoji_people_rounded,
                size: 120,
                color: Color(0xFF2E8B57),
              ),
            ),
          ),
        ),
      ],
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
