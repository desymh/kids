import 'package:flutter/material.dart';
import '../core/local_storage_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  String avatar = 'Zaid';
  final storage = LocalStorageService();

  Future<void> _save() async {
    await storage.saveProfil(_nameCtrl.text.trim(), avatar);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD8F3E5), Color(0xFFE8F8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Text('QalbuKids', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.teal[900])),
                const SizedBox(height: 8),
                Text('Masukkan nama panggilan & pilih karakter', style: TextStyle(color: Colors.teal[700])),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama panggilan',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _AvatarChip(name: 'Zaid', selected: avatar == 'Zaid', onTap: () => setState(() => avatar = 'Zaid'))),
                    const SizedBox(width: 12),
                    Expanded(child: _AvatarChip(name: 'Aisyah', selected: avatar == 'Aisyah', onTap: () => setState(() => avatar = 'Aisyah'))),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nameCtrl.text.trim().isEmpty ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.teal[600],
                    ),
                    child: const Text('Mulai Petualangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

class _AvatarChip extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _AvatarChip({required this.name, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final asset = name == 'Zaid' ? 'assets/images/avatar_zaid.jpeg' : 'assets/images/avatar_aisyah.jpeg';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD5EFE2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF2E8B57) : Colors.teal[100]!, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child: Image.asset(
                  asset,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.person, size: 40, color: Colors.teal[800]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: selected ? const Color(0xFF2E8B57) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}