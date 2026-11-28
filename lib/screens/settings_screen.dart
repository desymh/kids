import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage_service.dart';
import 'toko_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  bool _sound = true;
  bool _guruMode = false;
  int _koin = StorageService.defaultKoin;
  int _nyawa = StorageService.defaultNyawa;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final koin = await _storage.getKoin();
    final nyawa = await _storage.getNyawa();
    if (!mounted) return;
    setState(() {
      _sound = sp.getBool('sound') ?? true;
      _guruMode = sp.getBool('guru_mode') ?? false;
      _koin = koin;
      _nyawa = nyawa;
    });
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('sound', _sound);
    await sp.setBool('guru_mode', _guruMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.teal[900],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WalletStatsRow(
              coinsKey: const ValueKey('settings-coins'),
              livesKey: const ValueKey('settings-lives'),
              coins: _koin,
              lives: _nyawa,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Suara Latar'),
            subtitle: const Text('Mengaktifkan/menonaktifkan musik latar'),
            value: _sound,
            onChanged: (v) => setState(() {
              _sound = v;
              _save();
            }),
            activeColor: Colors.teal[600],
          ),
          SwitchListTile(
            title: const Text('Mode Guru/Dosen'),
            subtitle: const Text('Membuka seluruh pulau untuk demonstrasi'),
            value: _guruMode,
            onChanged: (v) => setState(() {
              _guruMode = v;
              _save();
            }),
            activeColor: Colors.teal[600],
          ),
        ],
      ),
    );
  }
}
