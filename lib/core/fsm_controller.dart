enum LevelState { locked, unlocked, completed }

class ProgressionFSM {
  final Map<String, LevelState> _states = {};

  LevelState getState(String key) => _states[key] ?? LevelState.locked;

  void unlock(String key) {
    if (_states[key] == null || _states[key] == LevelState.locked) {
      _states[key] = LevelState.unlocked;
    }
  }

  void complete(String key, int skor, int nyawa) {
    if (skor >= 60 && nyawa > 0) {
      _states[key] = LevelState.completed;
    }
  }

  bool canAdvance(String key, int skor, int nyawa) {
    return skor >= 60 && nyawa > 0;
  }

  void unlockNext(String currentKey, String nextKey, int skor, int nyawa) {
    if (skor >= 60 && nyawa > 0) {
      unlock(nextKey);
    }
  }
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