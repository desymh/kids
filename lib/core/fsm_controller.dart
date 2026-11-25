enum ProgressState { locked, unlocked, completed }

class ProgressionFSM {
  final Map<String, ProgressState> _states = {};

  ProgressState stateOf(String key) => _states[key] ?? ProgressState.locked;

  void unlock(String key) {
    if (_states[key] == ProgressState.locked) {
      _states[key] = ProgressState.unlocked;
    }
  }

  void complete(String key, int skor, int nyawa) {
    if (skor >= 60 && nyawa > 0) {
      _states[key] = ProgressState.completed;
      // unlock next tahap/pulau
    }
  }

  bool canAdvance(int skor, int nyawa) => skor >= 60 && nyawa > 0;
}

class IbadahSimulationFSM {
  int _current = 0;
  int nyawa;
  int poin;
  final List<String> sequence;
  final void Function(String)? onAudio;

  IbadahSimulationFSM({
    required this.sequence,
    this.nyawa = 3,
    this.poin = 0,
    this.onAudio,
  });

  int get current => _current;
  bool get isComplete => _current >= sequence.length;

  bool input(String gerakan) {
    if (_current >= sequence.length) return false;
    if (gerakan == sequence[_current]) {
      onAudio?.call(gerakan);
      poin += 20;
      _current++;
      return true;
    } else {
      nyawa -= 1;
      return false;
    }
  }

  void reset() {
    _current = 0;
  }
}
