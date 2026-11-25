import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _kNama = 'nama';
  static const String _kAvatar = 'avatar';
  static const String _kTotalPoin = 'totalPoin';
  static const String _kTotalBintang = 'totalBintang';
  static const String _kLencana = 'lencana';

  // Default open pulau_1_tahap_1
  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    if (!sp.containsKey('pulau_1_tahap_1')) {
      await sp.setBool('pulau_1_tahap_1', true);
    }
    if (!sp.containsKey(_kLencana)) {
      await sp.setStringList(_kLencana, List.filled(6, 'false'));
    }
    if (!sp.containsKey(_kNama)) {
      await sp.setString(_kNama, 'Zaid');
    }
    if (!sp.containsKey(_kAvatar)) {
      await sp.setString(_kAvatar, 'Zaid');
    }
    if (!sp.containsKey(_kTotalPoin)) {
      await sp.setInt(_kTotalPoin, 0);
    }
    if (!sp.containsKey(_kTotalBintang)) {
      await sp.setInt(_kTotalBintang, 0);
    }
  }

  Future<String> getNama() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kNama) ?? 'Zaid';
  }

  Future<void> setNama(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kNama, v);
  }

  Future<String> getAvatar() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kAvatar) ?? 'Zaid';
  }

  Future<void> setAvatar(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAvatar, v);
  }

  Future<int> getTotalPoin() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kTotalPoin) ?? 0;
  }

  Future<void> setTotalPoin(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kTotalPoin, v);
  }

  Future<int> getTotalBintang() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kTotalBintang) ?? 0;
  }

  Future<void> setTotalBintang(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kTotalBintang, v);
  }

  Future<bool> getProgres(String key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(key) ?? false;
  }

  Future<void> setProgres(String key, bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(key, v);
  }

  Future<List<bool>> getLencana() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_kLencana) ?? List.filled(6, 'false');
    return list.map((e) => e == 'true').toList();
  }

  Future<void> setLencana(List<bool> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kLencana, list.map((e) => e ? 'true' : 'false').toList());
  }

  Future<void> bukaSemuaPulauUntukTesting() async {
    final sp = await SharedPreferences.getInstance();
    for (int p = 1; p <= 6; p++) {
      for (int t = 1; t <= 4; t++) {
        await sp.setBool('pulau_${p}_tahap_$t', true);
      }
    }
  }

  Future<void> resetSemuaProgres() async {
    final sp = await SharedPreferences.getInstance();
    for (int p = 1; p <= 6; p++) {
      for (int t = 1; t <= 4; t++) {
        await sp.remove('pulau_${p}_tahap_$t');
      }
    }
    await sp.setBool('pulau_1_tahap_1', true);
    await sp.setStringList(_kLencana, List.filled(6, 'false'));
    await sp.setInt(_kTotalPoin, 0);
    await sp.setInt(_kTotalBintang, 0);
  }
}