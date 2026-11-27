enum PlayerState { idle, walk, interact }

enum GateState { locked, quizActive, unlocked }

class AdventureFSM {
  PlayerState _playerState = PlayerState.idle;
  GateState _gateState;

  AdventureFSM({GateState initialGateState = GateState.locked})
      : _gateState = initialGateState;

  PlayerState get playerState => _playerState;
  GateState get gateState => _gateState;

  bool get canMove =>
      _gateState != GateState.quizActive &&
      _playerState != PlayerState.interact;

  void updateMovement(bool moving) {
    if (!canMove) return;
    _playerState = moving ? PlayerState.walk : PlayerState.idle;
  }

  bool beginQuiz() {
    if (_gateState != GateState.locked) return false;
    _gateState = GateState.quizActive;
    _playerState = PlayerState.interact;
    return true;
  }

  bool finishQuiz({required int skor}) {
    if (_gateState != GateState.quizActive) return false;
    if (skor >= passScore) {
      _gateState = GateState.unlocked;
    } else {
      _gateState = GateState.locked;
    }
    _playerState = PlayerState.idle;
    return _gateState == GateState.unlocked;
  }

  void cancelQuiz() {
    if (_gateState != GateState.quizActive) return;
    _gateState = GateState.locked;
    _playerState = PlayerState.idle;
  }

  static const int passScore = 60;
}
