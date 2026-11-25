import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _keyNama = 'nama';
  static const _keyAvatar = 'avatar';
  static const _keyBintang = 'bintang';
  static const _keyPoin = 'poin';

  Future<void> saveProfil(String nama, String avatar) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_keyNama, nama);
    await sp.setString(_keyAvatar, avatar);
  }

  Future<Map<String, String>> loadProfil() async {
    final sp = await SharedPreferences.getInstance();
    return {
      'nama': sp.getString(_keyNama) ?? '',
      'avatar': sp.getString(_keyAvatar) ?? 'Zaid',
    };
  }

  Future<int> loadBintang() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_keyBintang) ?? 0;
  }

  Future<int> loadPoin() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_keyPoin) ?? 0;
  }

  Future<void> saveBintang(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_keyBintang, v);
  }

  Future<void> savePoin(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_keyPoin, v);
  }
}
