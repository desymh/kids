enum LevelState { locked, unlocked, completed }

class StageProgressionResult {
  final bool passed;
  final bool nextStageUnlocked;
  final bool islandCompleted;
  final bool nextIslandUnlocked;
  final bool badgeUnlocked;

  const StageProgressionResult({
    required this.passed,
    this.nextStageUnlocked = false,
    this.islandCompleted = false,
    this.nextIslandUnlocked = false,
    this.badgeUnlocked = false,
  });
}

class ProgressionFSM {
  static const int passScore = 60;
  static const List<int> activeIslandIds = [1, 2, 3, 4, 6];

  static int displayIslandNumber(int pulauId) {
    final index = activeIslandIds.indexOf(pulauId);
    return index >= 0 ? index + 1 : pulauId;
  }

  static int? nextActiveIslandId(int pulauId) {
    final index = activeIslandIds.indexOf(pulauId);
    if (index < 0 || index >= activeIslandIds.length - 1) return null;
    return activeIslandIds[index + 1];
  }

  final Map<String, LevelState> _states;

  ProgressionFSM({Map<String, LevelState> initialStates = const {}})
      : _states = Map<String, LevelState>.from(initialStates);

  static String stageKey(int pulauId, int tahap) =>
      'pulau_${pulauId}_tahap_$tahap';

  static String islandKey(int pulauId) => 'pulau_$pulauId';

  static String badgeKey(int pulauId) => 'badge_pulau_$pulauId';

  Map<String, LevelState> get states => Map<String, LevelState>.from(_states);

  LevelState getState(String key) => _states[key] ?? LevelState.locked;

  void loadStates(Map<String, LevelState> states) {
    _states
      ..clear()
      ..addAll(states);
  }

  void unlock(String key) {
    if (getState(key) == LevelState.locked) {
      _states[key] = LevelState.unlocked;
    }
  }

  void complete(String key, int skor, int nyawa) {
    if (_canPass(skor, nyawa)) {
      _states[key] = LevelState.completed;
    }
  }

  bool canAdvance(String key, int skor, int nyawa) {
    return getState(key) != LevelState.locked && _canPass(skor, nyawa);
  }

  void unlockNext(String currentKey, String nextKey, int skor, int nyawa) {
    if (canAdvance(currentKey, skor, nyawa)) {
      unlock(nextKey);
    }
  }

  StageProgressionResult completeStage({
    required int pulauId,
    required int tahap,
    required int skor,
    required int nyawa,
    int totalIslands = 6,
  }) {
    final currentKey = stageKey(pulauId, tahap);
    if (!activeIslandIds.contains(pulauId) ||
        pulauId > totalIslands ||
        tahap < 1 ||
        tahap > 4 ||
        getState(currentKey) == LevelState.locked ||
        !_canPass(skor, nyawa)) {
      return const StageProgressionResult(passed: false);
    }

    final currentIslandKey = islandKey(pulauId);
    final badgeKey = ProgressionFSM.badgeKey(pulauId);
    _states[currentKey] = LevelState.completed;
    unlock(currentIslandKey);

    if (tahap < 4) {
      final nextKey = stageKey(pulauId, tahap + 1);
      final wasLocked = getState(nextKey) == LevelState.locked;
      unlock(nextKey);
      return StageProgressionResult(
        passed: true,
        nextStageUnlocked: wasLocked,
      );
    }

    _states[currentIslandKey] = LevelState.completed;
    final badgeWasLocked = getState(badgeKey) == LevelState.locked;
    unlock(badgeKey);

    var nextIslandUnlocked = false;
    final nextIslandId = nextActiveIslandId(pulauId);
    if (nextIslandId != null && nextIslandId <= totalIslands) {
      final nextIslandKey = islandKey(nextIslandId);
      final nextStageKey = stageKey(nextIslandId, 1);
      nextIslandUnlocked = getState(nextIslandKey) == LevelState.locked;
      unlock(nextIslandKey);
      unlock(nextStageKey);
    }

    return StageProgressionResult(
      passed: true,
      islandCompleted: true,
      nextIslandUnlocked: nextIslandUnlocked,
      badgeUnlocked: badgeWasLocked,
    );
  }

  bool _canPass(int skor, int nyawa) => skor >= passScore && nyawa > 0;
}

class IbadahSimulationFSM {
  int _stateIndex = 0;
  final List<String> steps;

  IbadahSimulationFSM({required this.steps});

  int get currentState => _stateIndex;
  bool get isComplete => _stateIndex >= steps.length;

  bool validasiLangkah(int langkahDipilih) {
    if (_stateIndex >= steps.length) return false;
    if (langkahDipilih == _stateIndex) {
      _stateIndex++;
      return true;
    }
    return false;
  }

  void reset() {
    _stateIndex = 0;
  }
}
