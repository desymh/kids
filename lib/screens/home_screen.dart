import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/storage_service.dart';
import 'belajar_screen.dart';
import 'lencana_screen.dart';
import 'peta_screen.dart';
import 'profile_setup_screen.dart';
import 'settings_screen.dart';
import 'toko_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  String nama = 'Santri';
  String avatarAsset = 'assets/images/avatar_zaid.png';
  int koin = StorageService.defaultKoin;
  int nyawa = StorageService.defaultNyawa;
  int jumlahLencanaTerbuka = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final savedNama = await _storage.getNama();
    final avatar = await _storage.getAvatar();
    final savedKoin = await _storage.getKoin();
    final savedNyawa = await _storage.getNyawa();
    final badges = await _storage.getLencana();
    if (!mounted) return;

    setState(() {
      nama = savedNama.isEmpty ? 'Santri' : savedNama;
      avatarAsset = avatar == 'aisyah'
          ? 'assets/images/avatar_aisyah.png'
          : 'assets/images/avatar_zaid.png';
      koin = savedKoin;
      nyawa = savedNyawa;
      jumlahLencanaTerbuka = StorageService.activeIslandIds
          .where((pulauId) => badges[pulauId - 1])
          .length;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _loadHomeData();
  }

  Future<void> _openProfileSummary() async {
    await _open(
      _ProfileSummaryScreen(
        nama: nama,
        avatarAsset: avatarAsset,
        koin: koin,
        nyawa: nyawa,
        jumlahLencanaTerbuka: jumlahLencanaTerbuka,
        onEditProfile: () => _open(const ProfileSetupScreen(isEditing: true)),
        onResetProgress: _resetProgress,
      ),
    );
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Progres Tes'),
        content: const Text(
          'Semua progres dan lencana akan dihapus. Nyawa akan diisi ulang. Profil tidak akan berubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _storage.resetSemuaProgres();
    if (!mounted) return;
    await _loadHomeData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progres tes berhasil direset.')),
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
            key: const ValueKey('home-background'),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/bg_menu_utama.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: _HomeContent(
              nama: nama,
              avatarAsset: avatarAsset,
              koin: koin,
              nyawa: nyawa,
              onAvatarTap: _openProfileSummary,
              onSettingsTap: () => _open(const SettingsScreen()),
              onBelajarTap: () => _open(const BelajarScreen()),
              onPetaTap: () => _open(const PetaScreen()),
              onLencanaTap: () => _open(const LencanaScreen()),
              onTokoTap: () => _open(const TokoScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String nama;
  final String avatarAsset;
  final int koin;
  final int nyawa;
  final VoidCallback onAvatarTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onBelajarTap;
  final VoidCallback onPetaTap;
  final VoidCallback onLencanaTap;
  final VoidCallback onTokoTap;

  const _HomeContent({
    required this.nama,
    required this.avatarAsset,
    required this.koin,
    required this.nyawa,
    required this.onAvatarTap,
    required this.onSettingsTap,
    required this.onBelajarTap,
    required this.onPetaTap,
    required this.onLencanaTap,
    required this.onTokoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ProfileCapsule(
                    key: const ValueKey('home-profile-capsule'),
                    nama: nama,
                    avatarAsset: avatarAsset,
                    onTap: onAvatarTap,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WalletStatsRow(
                          coinsKey: const ValueKey('home-coins'),
                          livesKey: const ValueKey('home-lives'),
                          coins: koin,
                          lives: nyawa,
                        ),
                        const SizedBox(width: 8),
                        _CircleButton(
                          key: const ValueKey('home-profile-settings'),
                          icon: Icons.settings_rounded,
                          tooltip: 'Profil & Pengaturan',
                          onTap: onSettingsTap,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final iconHeight = (MediaQuery.of(context).size.height * 0.30)
                    .clamp(0.0, constraints.maxHeight);
                final iconWidth = constraints.maxWidth * 0.19;

                Widget menuIcon({
                  required String id,
                  required String asset,
                  required String label,
                  required double phase,
                  required VoidCallback onTap,
                }) {
                  return SizedBox(
                    width: iconWidth,
                    height: iconHeight,
                    child: _FloatingMenuIcon(
                      key: ValueKey('menu-$id'),
                      asset: asset,
                      label: label,
                      phase: phase,
                      onTap: onTap,
                    ),
                  );
                }

                return Center(
                  child: SizedBox(
                    width: constraints.maxWidth * 0.94,
                    child: Row(
                      key: const ValueKey('home-menu-grid'),
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        menuIcon(
                          id: 'belajar',
                          asset: 'assets/images/icon_menu_belajar.png',
                          label: 'Belajar',
                          phase: 0,
                          onTap: onBelajarTap,
                        ),
                        menuIcon(
                          id: 'bermain',
                          asset: 'assets/images/icon_menu_bermain.png',
                          label: 'Bermain',
                          phase: 0.25,
                          onTap: onPetaTap,
                        ),
                        menuIcon(
                          id: 'koleksiku',
                          asset: 'assets/images/icon_menu_koleksiku.png',
                          label: 'Koleksiku',
                          phase: 0.5,
                          onTap: onLencanaTap,
                        ),
                        menuIcon(
                          id: 'toko',
                          asset: 'assets/images/icon_menu_toko.png',
                          label: 'Toko',
                          phase: 0.75,
                          onTap: onTokoTap,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCapsule extends StatelessWidget {
  final String nama;
  final String avatarAsset;
  final VoidCallback onTap;

  const _ProfileCapsule({
    super.key,
    required this.nama,
    required this.avatarAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5F52).withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFE6F5EE),
                child: ClipOval(
                  child: Image.asset(
                    avatarAsset,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hai, $nama!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF244B43)),
                      ),
                      Text(
                        'Ayo belajar & bertualang!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[600]),
                      ),
                    ],
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

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleButton(
      {super.key,
      required this.icon,
      required this.tooltip,
      required this.onTap});

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
              offset: const Offset(0, 5))
        ],
      ),
      child: IconButton(
          icon: Icon(icon, color: const Color(0xFF355C55)),
          tooltip: tooltip,
          onPressed: onTap),
    );
  }
}

class _FloatingMenuIcon extends StatefulWidget {
  final String asset;
  final String label;
  final double phase;
  final VoidCallback onTap;

  const _FloatingMenuIcon({
    super.key,
    required this.asset,
    required this.label,
    required this.phase,
    required this.onTap,
  });

  @override
  State<_FloatingMenuIcon> createState() => _FloatingMenuIconState();
}

class _FloatingMenuIconState extends State<_FloatingMenuIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final wave = math.sin(
              (_floatController.value + widget.phase) * 2 * math.pi,
            );
            return Transform.translate(
              offset: Offset(0, wave * 7),
              child: child,
            );
          },
          child: AnimatedScale(
            scale: _pressed ? 0.90 : 1,
            duration: _pressed
                ? const Duration(milliseconds: 70)
                : const Duration(milliseconds: 240),
            curve: Curves.elasticOut,
            child: Image.asset(
              widget.asset,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.menu_rounded,
                size: 72,
                color: Color(0xFF244B43),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSummaryScreen extends StatelessWidget {
  final String nama;
  final String avatarAsset;
  final int koin;
  final int nyawa;
  final int jumlahLencanaTerbuka;
  final VoidCallback onEditProfile;
  final VoidCallback onResetProgress;

  const _ProfileSummaryScreen({
    required this.nama,
    required this.avatarAsset,
    required this.koin,
    required this.nyawa,
    required this.jumlahLencanaTerbuka,
    required this.onEditProfile,
    required this.onResetProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F5EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF244B43),
        title: const Text('Profil'),
      ),
      body: SafeArea(
        child: ProfileSummaryTab(
          nama: nama,
          avatarAsset: avatarAsset,
          koin: koin,
          nyawa: nyawa,
          jumlahLencanaTerbuka: jumlahLencanaTerbuka,
          onEditProfile: () {
            Navigator.pop(context);
            onEditProfile();
          },
          onResetProgress: onResetProgress,
        ),
      ),
    );
  }
}
