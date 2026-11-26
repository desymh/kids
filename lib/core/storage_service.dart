import 'package:shared_preferences/shared_preferences.dart';
import 'fsm_controller.dart';

class StorageService {
  static const String keyNama = 'user_nama';
  static const String keyAvatar = 'user_avatar';
  static const String keyRegistered = 'is_registered';
  static const String keyTotalPoin = 'total_poin';
  static const String keyNyawa = 'nyawa';
  static const String keyTotalBintang = 'total_bintang';
  static const String keyLencana = 'lencana';
  static const String keyGuruMode = 'guru_mode';

  static const int totalIslands = 6;
  static const int stagesPerIsland = 4;
  static const int totalBadges = 6;
  static const int defaultNyawa = 5;

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();

    final nama = sp.getString(keyNama) ?? sp.getString('nama') ?? '';
    await sp.setString(keyNama, nama.trim());
    final legacyAvatar =
        sp.getString(keyAvatar) ?? sp.getString('avatar') ?? 'zaid';
    await sp.setString(
        keyAvatar, legacyAvatar.toLowerCase() == 'aisyah' ? 'aisyah' : 'zaid');
    if (!sp.containsKey(keyRegistered)) {
      await sp.setBool(keyRegistered, nama.trim().isNotEmpty);
    }
    if (!sp.containsKey(keyTotalPoin)) {
      await sp.setInt(
          keyTotalPoin, sp.getInt('totalPoin') ?? sp.getInt('poin') ?? 0);
    }
    final storedNyawa = sp.get(keyNyawa);
    await setNyawa(storedNyawa is int ? storedNyawa : defaultNyawa);
    if (!sp.containsKey(keyTotalBintang)) {
      await sp.setInt(keyTotalBintang,
          sp.getInt('totalBintang') ?? sp.getInt('bintang') ?? 0);
    }

    final badges = await getLencana();
    await setLencana(badges);

    for (var pulau = 1; pulau <= totalIslands; pulau++) {
      final islandKey = ProgressionFSM.islandKey(pulau);
      if (!sp.containsKey(islandKey) || sp.get(islandKey) is! String) {
        await setLevelState(islandKey, _readLegacyState(sp, islandKey));
      }
      for (var tahap = 1; tahap <= stagesPerIsland; tahap++) {
        final stageKey = ProgressionFSM.stageKey(pulau, tahap);
        if (!sp.containsKey(stageKey) || sp.get(stageKey) is! String) {
          await setLevelState(stageKey, _readLegacyState(sp, stageKey));
        }
      }
      final badgeKey = ProgressionFSM.badgeKey(pulau);
      if (!sp.containsKey(badgeKey) || sp.get(badgeKey) is! String) {
        final badges = await getLencana();
        await setLevelState(badgeKey,
            badges[pulau - 1] ? LevelState.unlocked : LevelState.locked);
      }
    }

    final firstIslandKey = ProgressionFSM.islandKey(1);
    final firstStageKey = ProgressionFSM.stageKey(1, 1);
    final firstIslandState = await getLevelState(firstIslandKey);
    final firstStageState = await getLevelState(firstStageKey);
    await setLevelState(
        firstIslandKey,
        firstIslandState == LevelState.locked
            ? LevelState.unlocked
            : firstIslandState);
    await setLevelState(
        firstStageKey,
        firstStageState == LevelState.locked
            ? LevelState.unlocked
            : firstStageState);
  }

  Future<String> getNama() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(keyNama) ?? '';
  }

  Future<void> setNama(String value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(keyNama, value.trim());
  }

  Future<String> getAvatar() async {
    final sp = await SharedPreferences.getInstance();
    final value = (sp.getString(keyAvatar) ?? 'zaid').toLowerCase();
    return value == 'aisyah' ? 'aisyah' : 'zaid';
  }

  Future<void> setAvatar(String value) async {
    final sp = await SharedPreferences.getInstance();
    final normalized = value.toLowerCase() == 'aisyah' ? 'aisyah' : 'zaid';
    await sp.setString(keyAvatar, normalized);
  }

  Future<bool> isRegistered() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(keyRegistered) ?? false;
  }

  Future<void> setRegistered(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(keyRegistered, value);
  }

  Future<int> getTotalPoin() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(keyTotalPoin) ?? 0;
  }

  Future<void> setTotalPoin(int value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(keyTotalPoin, value < 0 ? 0 : value);
  }

  Future<int> addTotalPoin(int value) async {
    final current = await getTotalPoin();
    final updated = current + value;
    await setTotalPoin(updated);
    return updated < 0 ? 0 : updated;
  }

  Future<int> getNyawa() async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.get(keyNyawa);
    if (stored is! int) {
      await sp.setInt(keyNyawa, defaultNyawa);
      return defaultNyawa;
    }
    final nyawa = _clampNyawa(stored);
    if (nyawa != stored) {
      await sp.setInt(keyNyawa, nyawa);
    }
    return nyawa;
  }

  Future<void> setNyawa(int value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(keyNyawa, _clampNyawa(value));
  }

  Future<int> kurangiNyawa(int jumlah) async {
    final current = await getNyawa();
    final pengurangan = jumlah < 0 ? 0 : jumlah;
    final updated = _clampNyawa(current - pengurangan);
    await setNyawa(updated);
    return updated;
  }

  Future<int> tambahNyawa(int jumlah) async {
    final current = await getNyawa();
    final penambahan = jumlah < 0 ? 0 : jumlah;
    final updated = _clampNyawa(current + penambahan);
    await setNyawa(updated);
    return updated;
  }

  int _clampNyawa(int value) => value < 0 ? 0 : value;

  Future<int> getTotalBintang() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(keyTotalBintang) ?? 0;
  }

  Future<void> setTotalBintang(int value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(keyTotalBintang, value < 0 ? 0 : value);
  }

  Future<LevelState> getLevelState(String key) async {
    final sp = await SharedPreferences.getInstance();
    final value = sp.get(key);
    if (value is String) {
      return LevelState.values.firstWhere(
        (state) => state.name == value,
        orElse: () => LevelState.locked,
      );
    }
    return _readLegacyState(sp, key);
  }

  Future<void> setLevelState(String key, LevelState state) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, state.name);
    await sp.setBool('${key}_completed', state == LevelState.completed);
    await sp.setBool('${key}_unlocked', state != LevelState.locked);
  }

  Future<Map<String, LevelState>> getFsmStates() async {
    final states = <String, LevelState>{};
    for (var pulau = 1; pulau <= totalIslands; pulau++) {
      states[ProgressionFSM.islandKey(pulau)] =
          await getLevelState(ProgressionFSM.islandKey(pulau));
      states[ProgressionFSM.badgeKey(pulau)] =
          await getLevelState(ProgressionFSM.badgeKey(pulau));
      for (var tahap = 1; tahap <= stagesPerIsland; tahap++) {
        final key = ProgressionFSM.stageKey(pulau, tahap);
        states[key] = await getLevelState(key);
      }
    }
    return states;
  }

  Future<void> saveFsmStates(Map<String, LevelState> states) async {
    for (final entry in states.entries) {
      await setLevelState(entry.key, entry.value);
    }
    final badges = List<bool>.filled(totalBadges, false);
    for (var pulau = 1; pulau <= totalIslands; pulau++) {
      badges[pulau - 1] =
          (states[ProgressionFSM.badgeKey(pulau)] ?? LevelState.locked) !=
              LevelState.locked;
    }
    await setLencana(badges);
  }

  Future<bool> getProgres(String key) async {
    return await getLevelState(key) != LevelState.locked;
  }

  Future<void> setProgres(String key, bool value) async {
    await setLevelState(key, value ? LevelState.completed : LevelState.locked);
  }

  Future<List<bool>> getLencana() async {
    final sp = await SharedPreferences.getInstance();
    final stored = sp.getStringList(keyLencana);
    final badges = List<bool>.filled(totalBadges, false);
    for (var i = 0; i < totalBadges; i++) {
      final raw = sp.get('lencana_${i + 1}');
      final badgeState = sp.get(ProgressionFSM.badgeKey(i + 1));
      final unlockedByState = badgeState == true ||
          badgeState == LevelState.unlocked.name ||
          badgeState == LevelState.completed.name;
      if (raw is bool) {
        badges[i] = raw || unlockedByState;
      } else if (raw is String) {
        badges[i] = raw == 'true' ||
            raw == LevelState.unlocked.name ||
            raw == LevelState.completed.name ||
            unlockedByState;
      } else {
        badges[i] = unlockedByState ||
            (stored != null && i < stored.length ? stored[i] == 'true' : false);
      }
    }
    return badges;
  }

  Future<void> setLencana(List<bool> badges) async {
    final sp = await SharedPreferences.getInstance();
    final normalized = List<bool>.filled(totalBadges, false);
    for (var i = 0; i < totalBadges && i < badges.length; i++) {
      normalized[i] = badges[i];
    }
    await sp.setStringList(keyLencana,
        normalized.map((unlocked) => unlocked ? 'true' : 'false').toList());
    for (var i = 0; i < totalBadges; i++) {
      final pulauId = i + 1;
      await sp.setBool('lencana_$pulauId', normalized[i]);
      await setLevelState(
        ProgressionFSM.badgeKey(pulauId),
        normalized[i] ? LevelState.unlocked : LevelState.locked,
      );
    }
  }

  Future<int> getStageStars(int pulauId, int tahap) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('${ProgressionFSM.stageKey(pulauId, tahap)}_bintang') ?? 0;
  }

  Future<void> setStageStars(int pulauId, int tahap, int value) async {
    final sp = await SharedPreferences.getInstance();
    final stars = value < 0 ? 0 : (value > 3 ? 3 : value);
    await sp.setInt(
        '${ProgressionFSM.stageKey(pulauId, tahap)}_bintang', stars);
  }

  Future<int> getIslandStars(int pulauId) async {
    return getStageStars(pulauId, stagesPerIsland);
  }

  Future<int> recalculateTotalStars() async {
    var total = 0;
    for (var pulau = 1; pulau <= totalIslands; pulau++) {
      for (var tahap = 1; tahap <= stagesPerIsland; tahap++) {
        total += await getStageStars(pulau, tahap);
      }
    }
    await setTotalBintang(total);
    return total;
  }

  Future<Map<String, int>?> getNextStage() async {
    for (var pulau = 1; pulau <= totalIslands; pulau++) {
      if (await getLevelState(ProgressionFSM.islandKey(pulau)) ==
          LevelState.locked) {
        continue;
      }
      for (var tahap = 1; tahap <= stagesPerIsland; tahap++) {
        final state =
            await getLevelState(ProgressionFSM.stageKey(pulau, tahap));
        if (state == LevelState.unlocked) {
          return {'pulau': pulau, 'tahap': tahap};
        }
      }
    }
    return null;
  }

  Future<int> getCompletedStageCount() async {
    var completed = 0;
    for (var pulau = 1; pulau <= totalIslands; pulau++) {
      for (var tahap = 1; tahap <= stagesPerIsland; tahap++) {
        if (await getLevelState(ProgressionFSM.stageKey(pulau, tahap)) ==
            LevelState.completed) {
          completed++;
        }
      }
    }
    return completed;
  }

  Future<bool> getGuruMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(keyGuruMode) ?? false;
  }

  Future<void> bukaSemuaPulauUntukTesting() async {
    final states = await getFsmStates();
    for (var pulau = 1; pulau <= totalIslands; pulau++) {
      states[ProgressionFSM.islandKey(pulau)] = LevelState.unlocked;
      for (var tahap = 1; tahap <= stagesPerIsland; tahap++) {
        states[ProgressionFSM.stageKey(pulau, tahap)] = LevelState.unlocked;
      }
    }
    await saveFsmStates(states);
  }

  Future<void> resetSemuaProgres() async {
    final states = <String, LevelState>{};
    for (var pulau = 1; pulau <= totalIslands; pulau++) {
      states[ProgressionFSM.islandKey(pulau)] = LevelState.locked;
      states[ProgressionFSM.badgeKey(pulau)] = LevelState.locked;
      for (var tahap = 1; tahap <= stagesPerIsland; tahap++) {
        states[ProgressionFSM.stageKey(pulau, tahap)] = LevelState.locked;
        await setStageStars(pulau, tahap, 0);
      }
    }
    states[ProgressionFSM.islandKey(1)] = LevelState.unlocked;
    states[ProgressionFSM.stageKey(1, 1)] = LevelState.unlocked;
    await saveFsmStates(states);
    await setTotalPoin(0);
    await setNyawa(defaultNyawa);
    await setTotalBintang(0);
  }

  LevelState _readLegacyState(SharedPreferences sp, String key) {
    if (sp.get('${key}_completed') == true) {
      return LevelState.completed;
    }
    if (sp.get('${key}_unlocked') == true || sp.get(key) == true) {
      return LevelState.unlocked;
    }
    if (key == ProgressionFSM.islandKey(1) ||
        key == ProgressionFSM.stageKey(1, 1)) {
      return LevelState.unlocked;
    }
    return LevelState.locked;
  }
}
