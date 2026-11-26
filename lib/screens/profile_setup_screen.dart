import 'package:flutter/material.dart';
import '../core/storage_service.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isEditing;

  const ProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const Color _darkEmerald = Color(0xFF1E4E48);

  final _nameCtrl = TextEditingController();
  final StorageService _storage = StorageService();
  String _avatar = 'zaid';
  String? _nameError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadSavedProfile();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedProfile() async {
    final nama = await _storage.getNama();
    final avatar = await _storage.getAvatar();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = nama;
      _avatar = avatar;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final nama = _nameCtrl.text.trim();
    if (nama.isEmpty) {
      setState(() => _nameError = 'Nama panggilan tidak boleh kosong.');
      return;
    }

    setState(() {
      _nameError = null;
      _saving = true;
    });

    await _storage.setNama(nama);
    await _storage.setAvatar(_avatar);
    await _storage.setRegistered(true);
    if (!mounted) return;

    if (widget.isEditing) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _selectAvatar(String avatar) {
    if (_saving) return;
    setState(() => _avatar = avatar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F5EE),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight - 48).clamp(0.0, double.infinity),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isEditing)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Kembali',
                          onPressed: () => Navigator.pop(context),
                          icon:
                              const Icon(Icons.arrow_back, color: _darkEmerald),
                        ),
                      ),
                    const _WelcomeHeader(),
                    const SizedBox(height: 54),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _ProfileCard(
                        nameController: _nameCtrl,
                        avatar: _avatar,
                        nameError: _nameError,
                        saving: _saving,
                        isEditing: widget.isEditing,
                        onNameChanged: () {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                        onAvatarSelected: _selectAvatar,
                        onSave: _save,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 28,
          left: 4,
          child: Icon(
            Icons.cloud,
            size: 72,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
        Positioned(
          top: 12,
          right: 2,
          child: Icon(
            Icons.cloud,
            size: 62,
            color: Colors.white.withValues(alpha: 0.62),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                "Assalamu'alaikum!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E4E48),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Kenalan dulu sebelum bertualang, yuk!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF52766F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final TextEditingController nameController;
  final String avatar;
  final String? nameError;
  final bool saving;
  final bool isEditing;
  final VoidCallback onNameChanged;
  final ValueChanged<String> onAvatarSelected;
  final VoidCallback onSave;

  const _ProfileCard({
    required this.nameController,
    required this.avatar,
    required this.nameError,
    required this.saving,
    required this.isEditing,
    required this.onNameChanged,
    required this.onAvatarSelected,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 88, 22, 28),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFEFD),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFAED8C6).withValues(alpha: 0.72),
                offset: const Offset(0, 7),
                blurRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 16),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8F3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFF2F8F83),
                      size: 25,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        enabled: !saving,
                        onChanged: (_) => onNameChanged(),
                        onSubmitted: (_) => onSave(),
                        cursorColor: const Color(0xFF2F8F83),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF254B45),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Masukkan Nama Panggilanmu...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                          errorText: nameError,
                          errorStyle: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih Karaktermu:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF355C55),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AvatarOption(
                    label: 'Zaid',
                    asset: 'assets/images/avatar_zaid.png',
                    selected: avatar == 'zaid',
                    onTap: () => onAvatarSelected('zaid'),
                  ),
                  _AvatarOption(
                    label: 'Aisyah',
                    asset: 'assets/images/avatar_aisyah.png',
                    fallbackAsset: 'assets/images/avatar_aisyah.jpeg',
                    selected: avatar == 'aisyah',
                    onTap: () => onAvatarSelected('aisyah'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _StartButton(
                label: isEditing ? 'Simpan Profil' : 'Mulai Bertualang!',
                saving: saving,
                onPressed: onSave,
              ),
            ],
          ),
        ),
        Positioned(
          top: -58,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/mascot_berdua.png',
            height: 145,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _AvatarOption extends StatelessWidget {
  final String label;
  final String asset;
  final String? fallbackAsset;
  final bool selected;
  final VoidCallback onTap;

  const _AvatarOption({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
    this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(56),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? const Color(0xFF2F8F83) : Colors.transparent,
                width: 3.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2F8F83).withValues(alpha: 0.22),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFFE7F3ED),
              child: ClipOval(
                child: Image.asset(
                  asset,
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    if (fallbackAsset != null) {
                      return Image.asset(
                        fallbackAsset!,
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                      );
                    }
                    return const Icon(
                      Icons.person,
                      size: 42,
                      color: Color(0xFF2F8F83),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: selected ? const Color(0xFF1E635A) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final String label;
  final bool saving;
  final VoidCallback onPressed;

  const _StartButton({
    required this.label,
    required this.saving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E635A),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E635A).withValues(alpha: 0.2),
              offset: const Offset(0, 7),
              blurRadius: 14,
            ),
          ],
        ),
        child: Material(
          color: const Color(0xFF2F8F83),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: saving ? null : onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 55,
              alignment: Alignment.center,
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
