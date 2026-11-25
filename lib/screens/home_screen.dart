import 'package:flutter/material.dart';
import 'belajar_screen.dart';
import 'peta_screen.dart';
import 'simulasi_screen.dart';
import 'lencana_screen.dart';
import 'settings_screen.dart';
import 'quiz_screen.dart';
import 'tahapan_screen.dart';
import 'daily_quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nama = 'Zaid';
  String avatarAsset = 'assets/images/avatar_zaid.jpeg';
  int bintang = 12;
  int poin = 390;
  int _navIndex = 0;

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Karakter Santri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AvatarOption(
                  name: 'Zaid',
                  asset: 'assets/images/avatar_zaid.jpeg',
                  selected: avatarAsset.contains('zaid'),
                  onTap: () => _selectAvatar('Zaid', 'assets/images/avatar_zaid.jpeg'),
                ),
                const SizedBox(width: 32),
                _AvatarOption(
                  name: 'Aisyah',
                  asset: 'assets/images/avatar_aisyah.jpeg',
                  selected: avatarAsset.contains('aisyah'),
                  onTap: () => _selectAvatar('Aisyah', 'assets/images/avatar_aisyah.jpeg'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _selectAvatar(String name, String asset) {
    setState(() {
      nama = name;
      avatarAsset = asset;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F5EE),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _navIndex,
          children: [
            // Tab 0: Beranda
            _HomeContent(
              nama: nama,
              avatarAsset: avatarAsset,
              bintang: bintang,
              poin: poin,
              onAvatarTap: _showAvatarPicker,
              onSettingsTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              onBelajarTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BelajarScreen()),
              ),
              onPetaTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PetaScreen()),
              ),
              onSimulasiTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SimulasiScreen()),
              ),
              onLencanaTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LencanaScreen()),
              ),
              onContinueTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TahapanScreen(pulauNo: 2, pulauNama: 'Thaharah'),
                ),
              ),
              onMisiTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyQuizScreen()),
              ),
            ),
            // Tab 1: Lencana
            const _EmbeddedLencanaTab(),
            // Tab 2: Profil
            _EmbeddedProfilTab(
              nama: nama,
              avatarAsset: avatarAsset,
              bintang: bintang,
              poin: poin,
              onGantiKarakter: _showAvatarPicker,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFC8E6D7), width: 1.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  active: _navIndex == 0,
                  onTap: () => setState(() => _navIndex = 0),
                ),
                _NavItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Lencana',
                  active: _navIndex == 1,
                  onTap: () => setState(() => _navIndex = 1),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  active: _navIndex == 2,
                  onTap: () => setState(() => _navIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2E8B57);
    final inactiveColor = Colors.grey[400];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  final String name;
  final String asset;
  final bool selected;
  final VoidCallback onTap;
  const _AvatarOption({
    required this.name,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? const Color(0xFF2E8B57) : Colors.transparent,
                width: 3.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2E8B57).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child: Image.asset(
                  asset,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: selected ? const Color(0xFF2E8B57) : const Color(0xFF4A5568),
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
  final int bintang;
  final int poin;
  final VoidCallback onAvatarTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onBelajarTap;
  final VoidCallback onPetaTap;
  final VoidCallback onSimulasiTap;
  final VoidCallback onLencanaTap;
  final VoidCallback onContinueTap;
  final VoidCallback onMisiTap;

  const _HomeContent({
    required this.nama,
    required this.avatarAsset,
    required this.bintang,
    required this.poin,
    required this.onAvatarTap,
    required this.onSettingsTap,
    required this.onBelajarTap,
    required this.onPetaTap,
    required this.onSimulasiTap,
    required this.onLencanaTap,
    required this.onContinueTap,
    required this.onMisiTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Atas: Profil Avatar, Bintang, Poin Trophy, & Tombol Pengaturan
          Row(
            children: [
              InkWell(
                onTap: onAvatarTap,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFC8E6D7), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child: Image.asset(
                        avatarAsset,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 26, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hai, $nama!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 4),
                        Text(
                          '$bintang',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Pill Poin & Trophy
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFC8E6D7), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/icon_trophy.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.emoji_events,
                        size: 20,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$poin',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Pengaturan (Settings)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8E6D7), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Color(0xFF718096), size: 22),
                  onPressed: onSettingsTap,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Hero Karakter & Balon Sapaan (Sesuai Desain Blueprint)
          Container(
            height: 165,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEBF8F2), Color(0xFFD5EFE2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFC8E6D7), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Latar Belakang Masjid Samar
                  Positioned(
                    right: 10,
                    bottom: 0,
                    child: Opacity(
                      opacity: 0.28,
                      child: Image.asset(
                        'assets/images/bg_masjid.png',
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.mosque_rounded,
                          size: 130,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ),
                  // Maskot Santri Waving di Kiri/Tengah
                  Positioned(
                    left: 8,
                    bottom: 0,
                    child: Image.asset(
                      'assets/images/mascot_berdua.png',
                      height: 155,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        avatarAsset,
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Balon Sapaan di Kanan Atas
                  Positioned(
                    top: 20,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 185),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC8E6D7)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Assalamu'alaikum!",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E8B57),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Siap berpetualang hari ini?",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4A5568),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Kartu Misi Harian (Ungu Ceria)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5DFA), Color(0xFF986EF2)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C5DFA).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 24, color: Color(0xFFFBBF24)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Misi Harian:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Jawab 1 Soal Acak (+50 Poin)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onMisiTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26463),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Coba',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Grid 2x2 Menu Utama dengan Karakter Santri Besar (Sesuai Desain Blueprint)
          Row(
            children: [
              Expanded(
                child: _GameMenuCard(
                  gradient: const [Color(0xFF38A896), Color(0xFF268A7A)],
                  borderBottomColor: const Color(0xFF14544A),
                  bannerColor: const Color(0xFF165C52),
                  imageAsset: 'assets/images/icon_belajar.png',
                  title: 'MENU BELAJAR',
                  subtitle: '5 Bab Materi & Audio',
                  onTap: onBelajarTap,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _GameMenuCard(
                  gradient: const [Color(0xFFF39C48), Color(0xFFE27C24)],
                  borderBottomColor: const Color(0xFF9E4B11),
                  bannerColor: const Color(0xFFB85912),
                  imageAsset: 'assets/images/icon_game.png',
                  title: 'GAME UJIAN',
                  subtitle: 'Petualangan 6 Pulau',
                  onTap: onPetaTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GameMenuCard(
                  gradient: const [Color(0xFF5BA4CB), Color(0xFF428EB7)],
                  borderBottomColor: const Color(0xFF255877),
                  bannerColor: const Color(0xFF2C6488),
                  imageAsset: 'assets/images/icon_wudhu_sholat.jpeg',
                  title: 'SIMULASI PRAKTIK',
                  subtitle: 'Latihan Wudhu & Shalat',
                  onTap: onSimulasiTap,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _GameMenuCard(
                  gradient: const [Color(0xFFE87A7A), Color(0xFFD65C5C)],
                  borderBottomColor: const Color(0xFF943232),
                  bannerColor: const Color(0xFFA63939),
                  imageAsset: 'assets/images/icon_pencapaian.png',
                  title: 'KOLEKSI LENCANA',
                  subtitle: '6 Lencana Cantik',
                  onTap: onLencanaTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. Baris Lanjutkan Progres (Pulau 2 - Tahap 2 Thaharah 60%)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC8E6D7), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Lanjutkan: Pulau 2 - Tahap 2 (Thaharah)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2D3748),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '60%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E8B57),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: const LinearProgressIndicator(
                          value: 0.6,
                          minHeight: 8,
                          backgroundColor: Color(0xFFD9F2E6),
                          valueColor: AlwaysStoppedAnimation(Color(0xFF2E8B57)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Tombol Play Hijau
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B57),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E8B57).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    padding: EdgeInsets.zero,
                    onPressed: onContinueTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameMenuCard extends StatelessWidget {
  final List<Color> gradient;
  final Color borderBottomColor;
  final Color bannerColor;
  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GameMenuCard({
    required this.gradient,
    required this.borderBottomColor,
    required this.bannerColor,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isJpeg = imageAsset.endsWith('.jpeg') || imageAsset.endsWith('.jpg');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 184,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border(bottom: BorderSide(color: borderBottomColor, width: 5)),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Area Karakter Besar (Mengisi penuh bagian atas kartu sesuai Blueprint)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Center(
                  child: isJpeg
                      ? Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              imageAsset,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            // Banner Judul Melengkung di Bagian Bawah
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: bannerColor.withOpacity(0.92),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.88),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Embedded Lencana Tab agar tidak terjadi bentrok Scaffold
class _EmbeddedLencanaTab extends StatelessWidget {
  const _EmbeddedLencanaTab();

  @override
  Widget build(BuildContext context) {
    return const LencanaScreen(isEmbedded: true);
  }
}

// Embedded Profil Tab interaktif
class _EmbeddedProfilTab extends StatelessWidget {
  final String nama;
  final String avatarAsset;
  final int bintang;
  final int poin;
  final VoidCallback onGantiKarakter;

  const _EmbeddedProfilTab({
    required this.nama,
    required this.avatarAsset,
    required this.bintang,
    required this.poin,
    required this.onGantiKarakter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      child: Column(
        children: [
          const Text(
            'Profil Santri',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 24),
          // Foto Profil Besar
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFF2E8B57), width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E8B57).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child: Image.asset(
                  avatarAsset,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 70),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nama,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Santri Cilik Hebat',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 24),
          // Statistik Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFC8E6D7), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 30),
                    const SizedBox(height: 4),
                    Text(
                      '$bintang',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const Text(
                      'Bintang',
                      style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
                    ),
                  ],
                ),
                Container(width: 1.5, height: 40, color: const Color(0xFFE2E8F0)),
                Column(
                  children: [
                    Image.asset(
                      'assets/images/icon_trophy.png',
                      width: 28,
                      height: 28,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.emoji_events,
                        size: 28,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$poin',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const Text(
                      'Poin',
                      style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Tombol Ganti Karakter
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGantiKarakter,
              icon: const Icon(Icons.switch_account_rounded),
              label: const Text(
                'Ganti Karakter (Zaid / Aisyah)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
