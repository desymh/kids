import 'package:flutter/material.dart';
import 'dart:math';
import '../data/bank_soal.dart';
import '../models/data_models.dart';
import '../core/fsm_controller.dart';
import '../core/storage_service.dart';
import 'toko_screen.dart';

class LencanaScreen extends StatefulWidget {
  final bool isEmbedded;
  const LencanaScreen({super.key, this.isEmbedded = false});

  @override
  LencanaScreenState createState() => LencanaScreenState();
}

class LencanaScreenState extends State<LencanaScreen> {
  final StorageService _storage = StorageService();
  List<bool> _badges = List<bool>.filled(StorageService.totalBadges, false);
  int _koin = StorageService.defaultKoin;
  int _nyawa = StorageService.defaultNyawa;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final badges = await _storage.getLencana();
    final koin = await _storage.getKoin();
    final nyawa = await _storage.getNyawa();
    if (!mounted) return;
    setState(() {
      _badges = badges;
      _koin = koin;
      _nyawa = nyawa;
    });
  }

  Future<void> _showBadgeDetail(int pulauId) async {
    final badgeName = BankSoal.badgeName(pulauId).replaceAll('\n', ' ');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          badgeName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber[100],
                border: Border.all(color: Colors.amber[600]!, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.25),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/icon_trophy.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Penghargaan Pulau ${ProgressionFSM.displayIslandNumber(pulauId)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.teal[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diraih setelah menamatkan seluruh tahap ${BankSoal.islandName(pulauId)} dengan skor minimal 60 dan sisa nyawa.',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const innerColors = [
      Color(0xFFFFD54F),
      Color(0xFFBAE6FD),
      Color(0xFFC8E6C9),
      Color(0xFFFFE0B2),
      Color(0xFFE1BEE7),
      Color(0xFFFFF59D),
    ];
    const ribbonColors = [
      Color(0xFFD32F2F),
      Color(0xFF0284C7),
      Color(0xFF2E7D32),
      Color(0xFFEF6C00),
      Color(0xFF7B1FA2),
      Color(0xFFF9A825),
    ];
    final activeIslandIds = StorageService.activeIslandIds;
    final unlockedBadgeCount =
        activeIslandIds.where((pulauId) => _badges[pulauId - 1]).length;
    final badges = List.generate(
      activeIslandIds.length,
      (index) {
        final pulauId = activeIslandIds[index];
        return BadgeData(
          BankSoal.badgeName(pulauId),
          _badges[pulauId - 1],
          Colors.amber[700]!,
          innerColors[pulauId - 1],
          ribbonColors[pulauId - 1],
        );
      },
    );

    final headerStats = Row(
      key: const ValueKey('lencana-header-stats'),
      mainAxisSize: MainAxisSize.min,
      children: [
        WalletStatsRow(
          coinsKey: const ValueKey('lencana-coins'),
          livesKey: const ValueKey('lencana-lives'),
          coins: _koin,
          lives: _nyawa,
        ),
        const SizedBox(width: 14),
        _HeaderStat(
          key: const ValueKey('lencana-count'),
          icon: Icons.shield,
          iconColor: Colors.grey[600]!,
          value: '$unlockedBadgeCount/${StorageService.activeBadgeCount}',
        ),
      ],
    );

    final badgeList = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 300;
        final cardWidth = constraints.maxWidth < 560 ? 164.0 : 184.0;
        final cardHeight =
            (constraints.maxHeight - 16).clamp(172.0, 210.0).toDouble();
        return ListView.separated(
          key: const ValueKey('lencana-list'),
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: badges.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, index) {
            final pulauId = activeIslandIds[index];
            return Center(
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _BadgeCard(
                  data: badges[index],
                  pulauId: pulauId,
                  compact: compact,
                  onTap: badges[index].unlocked
                      ? () => _showBadgeDetail(pulauId)
                      : null,
                ),
              ),
            );
          },
        );
      },
    );

    if (widget.isEmbedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Koleksi Lencana Santri',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.teal[900],
                fontSize: 20,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: headerStats,
            ),
          ),
          Expanded(child: badgeList),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.teal[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Koleksi Lencana Santri',
          style:
              TextStyle(fontWeight: FontWeight.w900, color: Colors.teal[900]),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: headerStats,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_menu_utama.png',
            key: const ValueKey('lencana-background'),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/bg_menu_utama.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: badgeList,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const _HeaderStat({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF244B43),
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeData data;
  final int pulauId;
  final bool compact;
  final VoidCallback? onTap;

  const _BadgeCard({
    required this.data,
    required this.pulauId,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final medalSize = compact ? 88.0 : 96.0;
    return Material(
      key: ValueKey('badge-card-surface-$pulauId'),
      color: Colors.white.withValues(alpha: 0.94),
      elevation: compact ? 2 : 3,
      shadowColor: Colors.teal[900]!.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        side: BorderSide(color: Colors.teal[100]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('badge-card-$pulauId'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Opacity(
            opacity: data.unlocked ? 1.0 : 0.55,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: medalSize,
                  height: medalSize,
                  child: CustomPaint(
                    painter: _MedalPainter(
                      unlocked: data.unlocked,
                      rimColor: data.rimColor,
                      innerColor: data.innerColor,
                      ribbonColor: data.ribbonColor,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w900,
                    color: data.unlocked ? Colors.grey[800] : Colors.grey[600],
                    height: 1.2,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                if (data.unlocked)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 12,
                      vertical: compact ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.amber[600]!),
                    ),
                    child: Text(
                      'TERBUKA',
                      style: TextStyle(
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF8A5A00),
                      ),
                    ),
                  )
                else
                  Text(
                    'Tamatkan Pulau $pulauId untuk membuka',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 9 : 10,
                      color: Colors.grey[600],
                      height: 1.2,
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

class _MedalPainter extends CustomPainter {
  final bool unlocked;
  final Color rimColor;
  final Color innerColor;
  final Color ribbonColor;
  _MedalPainter(
      {required this.unlocked,
      required this.rimColor,
      required this.innerColor,
      required this.ribbonColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final medalRadius = size.width * 0.35;

    final ribbonPaint = Paint()
      ..color = unlocked ? ribbonColor : Colors.grey[500]!;
    final ribbonPath = Path()
      ..moveTo(center.dx - 20, center.dy + 30)
      ..lineTo(center.dx - 32, center.dy + 70)
      ..lineTo(center.dx - 14, center.dy + 62)
      ..lineTo(center.dx - 4, center.dy + 72)
      ..lineTo(center.dx, center.dy + 36)
      ..close();
    canvas.drawPath(ribbonPath, ribbonPaint);
    canvas.drawPath(
        Path()
          ..moveTo(center.dx + 20, center.dy + 30)
          ..lineTo(center.dx + 32, center.dy + 70)
          ..lineTo(center.dx + 14, center.dy + 62)
          ..lineTo(center.dx + 4, center.dy + 72)
          ..lineTo(center.dx, center.dy + 36)
          ..close(),
        ribbonPaint);

    canvas.drawCircle(center, medalRadius,
        Paint()..color = unlocked ? rimColor : Colors.grey[400]!);
    canvas.drawCircle(center, medalRadius * 0.85,
        Paint()..color = unlocked ? innerColor : Colors.grey[500]!);

    if (unlocked) {
      if (rimColor == Colors.amber[700]) {
        _drawStar(canvas, center, medalRadius * 0.7);
      } else {
        _drawDroplet(canvas, center, medalRadius * 0.7);
      }
    } else {
      final lockPaint = Paint()..color = Colors.grey[600]!;
      final lockRect = Rect.fromCenter(
          center: Offset(center.dx, center.dy + 8), width: 24, height: 18);
      canvas.drawRRect(
          RRect.fromRectAndRadius(lockRect, Radius.circular(4)), lockPaint);
      final arcPaint = Paint()
        ..color = Colors.grey[600]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCircle(center: Offset(center.dx, center.dy), radius: 12),
          -pi,
          pi,
          false,
          arcPaint);
      canvas.drawCircle(center, 3, Paint()..color = Colors.grey[300]!);
    }

    if (unlocked) {
      canvas.drawCircle(
          center,
          medalRadius + 4,
          Paint()
            ..color = Colors.black12
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8));
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + i * 2 * pi / 5;
      final outerX = center.dx + radius * cos(angle);
      final outerY = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      final innerAngle = angle + pi / 5;
      final innerX = center.dx + radius * 0.4 * cos(innerAngle);
      final innerY = center.dy + radius * 0.4 * sin(innerAngle);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.amber[100]!);
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.amber[700]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  void _drawDroplet(Canvas canvas, Offset center, double radius) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.cubicTo(
        center.dx - radius * 0.7,
        center.dy - radius * 0.3,
        center.dx - radius,
        center.dy + radius * 0.2,
        center.dx,
        center.dy + radius);
    path.cubicTo(
        center.dx + radius,
        center.dy + radius * 0.2,
        center.dx + radius * 0.7,
        center.dy - radius * 0.3,
        center.dx,
        center.dy - radius);
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF0284C7));
    canvas.drawPath(
        Path()
          ..moveTo(center.dx - 9, center.dy - 2)
          ..quadraticBezierTo(
              center.dx - 9, center.dy - 8, center.dx - 5, center.dy - 8),
        Paint()
          ..color = Colors.blue[50]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _MedalPainter oldDelegate) {
    return oldDelegate.unlocked != unlocked ||
        oldDelegate.rimColor != rimColor ||
        oldDelegate.innerColor != innerColor ||
        oldDelegate.ribbonColor != ribbonColor;
  }
}
