import 'dart:async';

import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/fisher_yates_shuffle.dart';
import '../core/fsm/adventure_fsm.dart';
import '../core/storage_service.dart';
import '../data/bank_soal.dart';
import '../game/qalbukids_adventure_game.dart';
import 'peta_screen.dart';

List<List<Map<String, dynamic>>> partitionTreasureChestQuestions(
  List<Map<String, dynamic>> questions, {
  Random? random,
}) {
  if (questions.length != 11) {
    throw ArgumentError('Peti harta karun membutuhkan tepat 11 soal.');
  }
  final activeRandom = random ?? Random();
  final chestCount = 4 + activeRandom.nextInt(3);
  final groups = List<List<Map<String, dynamic>>>.generate(
    chestCount,
    (index) => [questions[index]],
  );
  final remaining = FisherYatesShuffler.shuffle(
    questions.skip(chestCount).toList(),
    random: activeRandom,
  );

  for (final question in remaining) {
    final available = List<int>.generate(
      chestCount,
      (index) => index,
    ).where((index) => groups[index].length < 3).toList();
    if (available.isEmpty) {
      throw StateError('Partisi soal peti melebihi kapasitas.');
    }
    groups[available[activeRandom.nextInt(available.length)]].add(question);
  }
  return FisherYatesShuffler.shuffle(groups, random: activeRandom);
}

Future<void> unlockAdventureIslandProgress({
  required StorageService storage,
  required int pulauId,
  required int skor,
  required int jumlahBenar,
  required int bintang,
  required int nyawa,
}) async {
  await storage.saveAdventureResult(
    pulauId: pulauId,
    skor: skor,
    jumlahBenar: jumlahBenar,
    bintang: bintang,
    nyawa: nyawa,
  );
}

class AdventureScreen extends StatefulWidget {
  final int pulauId;
  final String namaPulau;
  final Duration timeLimit;
  final bool obstaclesEnabled;

  const AdventureScreen({
    super.key,
    required this.pulauId,
    required this.namaPulau,
    this.timeLimit = const Duration(seconds: 180),
    this.obstaclesEnabled = false,
  });

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  static const _pesanNyawaHabis =
      'Nyawamu habis (0 ❤️)! Yuk baca materi di Menu Belajar atau selesaikan Simulasi Praktik untuk menambah nyawa.';
  static const _islandCompletionDelay = Duration(milliseconds: 2800);
  static const _pesanRintangan =
      '⚠️ Ups! Kena rintangan! Ayo lompati dan mulai dari awal jalur ya!';
  static const _pesanWaktuHabis =
      '⏰ Waktu Habis! Yuk coba lagi dan lebih sigap melompati rintangan serta menjawab kuis!';

  final StorageService _storage = StorageService();
  late final List<List<Map<String, dynamic>>> _chestQuestionGroups;
  late final List<Map<String, dynamic>> _gateQuestions;
  late final QalbuKidsAdventureGame _game;
  late final Future<void> _walletReady;
  Future<void> _coinSaveQueue = Future<void>.value();
  int _koin = StorageService.defaultKoin;
  int _nyawa = StorageService.defaultNyawa;
  int _pendingCoinSaves = 0;
  bool _showingQuiz = false;
  bool _quizDialogVisible = false;
  bool _returningToMap = false;
  bool _timerExpired = false;
  bool _timeoutDialogOpen = false;
  late int _remainingSeconds;
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
    final questions = BankSoal.getSoalPetualangan(widget.pulauId);
    _chestQuestionGroups = partitionTreasureChestQuestions(
      questions.take(11).toList(),
    );
    _gateQuestions = questions.skip(11).take(9).toList();
    _game = QalbuKidsAdventureGame(
      pulauId: widget.pulauId,
      onGateTriggered: _handleGateTriggered,
      onTreasureChestTriggered: _handleTreasureChestTriggered,
      onObstacleHit: _handleObstacleHit,
      onCoinCollected: _handleCoinCollected,
      obstaclesEnabled: widget.obstaclesEnabled,
      treasureQuestionGroups: _chestQuestionGroups,
    );
    _remainingSeconds = max(1, widget.timeLimit.inSeconds);
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _handleCountdownTick(),
    );
    _walletReady = _loadWallet();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _game.stopMoving();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    final koin = await _storage.getKoin();
    final nyawa = await _storage.getNyawa();
    if (!mounted) return;
    setState(() {
      _koin = koin + _pendingCoinSaves;
      _nyawa = nyawa;
    });
  }

  void _handleCoinCollected() {
    if (!mounted) return;
    setState(() => _koin++);
    _pendingCoinSaves++;
    _coinSaveQueue = _coinSaveQueue.then((_) async {
      await _walletReady;
      await _storage.tambahKoin(1);
      _pendingCoinSaves--;
    });
  }

  void _handleObstacleHit() {
    if (!mounted || _returningToMap) return;
    unawaited(HapticFeedback.lightImpact());
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const ValueKey('adventure-obstacle-warning'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.amber[50],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.amber[200]!),
        ),
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.amber[900]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _pesanRintangan,
                style: TextStyle(
                  color: Colors.brown[800],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCountdownTick() {
    if (!mounted ||
        _timerExpired ||
        _returningToMap ||
        _game.fsm.gateState == GateState.unlocked) {
      return;
    }
    final next = _remainingSeconds - 1;
    setState(() => _remainingSeconds = max(0, next));
    if (next <= 0) unawaited(_handleTimeExpired());
  }

  Future<void> _handleTimeExpired() async {
    if (!mounted ||
        _timerExpired ||
        _returningToMap ||
        _game.fsm.gateState == GateState.unlocked) {
      return;
    }
    _timerExpired = true;
    _returningToMap = true;
    _countdownTimer.cancel();
    _game.stopMoving();
    _game.pauseEngine();

    if (_quizDialogVisible) {
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showTimeExpiredDialog());
      });
      return;
    }
    await _showTimeExpiredDialog();
  }

  Future<void> _showTimeExpiredDialog() async {
    if (!mounted || _timeoutDialogOpen) return;
    _timeoutDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          key: const ValueKey('adventure-timeout-dialog'),
          icon: const Icon(Icons.timer_off_outlined,
              color: Colors.redAccent, size: 48),
          title: const Text('⏰ Waktu Habis!'),
          content: const Text(_pesanWaktuHabis),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _returnToMap();
              },
              child: const Text('Kembali ke Peta'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _restartIsland();
              },
              child: const Text('Ulangi Pulau'),
            ),
          ],
        ),
      ),
    );
    _timeoutDialogOpen = false;
  }

  void _restartIsland() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AdventureScreen(
          pulauId: widget.pulauId,
          namaPulau: widget.namaPulau,
          obstaclesEnabled: widget.obstaclesEnabled,
        ),
      ),
    );
  }

  void _returnToMap() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PetaScreen()),
    );
  }

  void _handleGateTriggered() {
    if (_showingQuiz || _returningToMap) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_showQuiz(
          mode: AdventureQuizMode.finalGate,
          questions: _gateQuestions,
        ));
      }
    });
  }

  void _handleTreasureChestTriggered(TreasureChestComponent chest) {
    if (_showingQuiz || _returningToMap) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_showQuiz(
          mode: AdventureQuizMode.treasureChest,
          questions: chest.questions,
          chest: chest,
        ));
      }
    });
  }

  Future<void> _showQuiz({
    required AdventureQuizMode mode,
    required List<Map<String, dynamic>> questions,
    TreasureChestComponent? chest,
  }) async {
    if (_showingQuiz || _returningToMap || _timerExpired) return;
    _showingQuiz = true;
    final nyawa = await _storage.getNyawa();
    if (!mounted) {
      _showingQuiz = false;
      return;
    }
    if (_timerExpired) {
      _showingQuiz = false;
      _game.pauseEngine();
      return;
    }
    setState(() => _nyawa = nyawa);

    if (mode == AdventureQuizMode.finalGate && nyawa <= 0) {
      _quizDialogVisible = true;
      await _showNyawaHabisDialog();
      _quizDialogVisible = false;
      if (!mounted) return;
      _showingQuiz = false;
      _game.cancelQuiz();
      if (_timerExpired) _game.pauseEngine();
      return;
    }

    _game.pauseEngine();
    _quizDialogVisible = true;
    final result = await showDialog<AdventureQuizResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdventureQuizDialog(
        pulauId: widget.pulauId,
        namaPulau: widget.namaPulau,
        initialNyawa: nyawa,
        mode: mode,
        questions: questions,
        onNyawaChanged: (value) {
          if (mounted) setState(() => _nyawa = value);
        },
      ),
    );
    _quizDialogVisible = false;
    if (!mounted) return;
    if (_timerExpired) {
      _showingQuiz = false;
      if (chest != null) {
        _game.cancelTreasureChest(chest);
      } else {
        _game.cancelQuiz();
      }
      _game.pauseEngine();
      return;
    }

    _game.resumeEngine();
    _showingQuiz = false;

    if (chest != null) {
      if (result == null) {
        _game.cancelTreasureChest(chest);
      } else {
        setState(() => _nyawa = result.nyawa);
        _game.completeTreasureChest(chest);
      }
      return;
    }

    if (result == null) {
      _game.cancelQuiz();
      return;
    }

    setState(() => _nyawa = result.nyawa);
    _game.completeQuiz(
      result.skor,
      jumlahBenar: result.jumlahBenar,
    );
    if (_game.fsm.gateState == GateState.unlocked) {
      _countdownTimer.cancel();
    }
    await _saveAdventureProgress(result);
    if (!mounted) return;
    if (!result.passed) {
      final message = result.completedAll
          ? 'Kamu menjawab ${result.jumlahBenar}/9 benar. Minimal 6 benar untuk membuka gerbang pulau berikutnya!'
          : _pesanNyawaHabis;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const ValueKey('adventure-quiz-failed-notification'),
          backgroundColor: Colors.red[700],
          content: Text(message),
        ),
      );
      return;
    }

    _game.stopMoving();
    setState(() => _returningToMap = true);
    if (!mounted) return;
    if (result.perfect) await _showPerfectTrophyDialog();
    if (!mounted) return;
    await _showCompletionAndContinue(result);
  }

  Future<void> _showNyawaHabisDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('❤️ Nyawa Habis'),
        content: const Text(_pesanNyawaHabis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAdventureProgress(AdventureQuizResult result) async {
    await unlockAdventureIslandProgress(
      storage: _storage,
      pulauId: widget.pulauId,
      skor: result.skor,
      jumlahBenar: result.jumlahBenar,
      bintang: result.stars,
      nyawa: result.nyawa,
    );
  }

  Future<void> _showPerfectTrophyDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('adventure-perfect-trophy-dialog'),
        icon: const Icon(Icons.emoji_events_rounded,
            color: Colors.amber, size: 56),
        title: Text('🏆 Piala Penghargaan Pulau ${widget.pulauId}'),
        content: Text(
          '🏆 LUAR BIASA! 9/9 Benar Sempurna! Piala Penghargaan Pulau ${widget.pulauId} Terbuka!',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCompletionAndContinue(AdventureQuizResult result) async {
    final hasNextIsland = widget.pulauId < StorageService.totalIslands;
    final badgeName = BankSoal.badgeName(widget.pulauId).replaceAll('\n', ' ');
    final achievementMessage = result.perfect
        ? 'Piala Penghargaan $badgeName terbuka.'
        : '${result.stars} Bintang Pulau ${widget.pulauId} diperoleh.';
    final nextIslandMessage = hasNextIsland
        ? 'Gerbang terbuka! Masuk ke Pulau ${widget.pulauId + 1}...'
        : 'Gerbang terbuka! Seluruh pulau telah diselesaikan.';
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        key: const ValueKey('adventure-island-success-notification'),
        duration: _islandCompletionDelay,
        backgroundColor: Colors.green[800],
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: Colors.amber, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Berhasil! Pulau ${widget.pulauId} selesai!',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text('$achievementMessage $nextIslandMessage'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await Future<void>.delayed(_islandCompletionDelay);
    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    if (hasNextIsland) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdventureScreen(
            pulauId: widget.pulauId + 1,
            namaPulau: BankSoal.islandName(widget.pulauId + 1),
            obstaclesEnabled: widget.obstaclesEnabled,
          ),
        ),
      );
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          Positioned(
            top: padding.top + 12,
            left: padding.left + 12,
            child: _HudButton(
              icon: Icons.arrow_back_rounded,
              onPressed: _returningToMap ? () {} : () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: padding.top + 12,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: _AdventureTimerCapsule(
                  key: const ValueKey('adventure-timer'),
                  remainingSeconds: _remainingSeconds,
                  isUrgent: _remainingSeconds < 30,
                ),
              ),
            ),
          ),
          Positioned(
            top: padding.top + 12,
            right: padding.right + 12,
            child: IgnorePointer(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HudStatCapsule(
                    key: const ValueKey('adventure-coins'),
                    emoji: '🪙',
                    value: _koin,
                    label: 'Koin',
                    accent: Colors.amber[800]!,
                  ),
                  const SizedBox(width: 8),
                  _HudStatCapsule(
                    key: const ValueKey('adventure-lives'),
                    emoji: '❤️',
                    value: _nyawa,
                    label: 'Nyawa',
                    accent: Colors.red[700]!,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: padding.bottom + 18,
            left: padding.left + 18,
            child: IgnorePointer(
              ignoring: _returningToMap,
              child: Row(
                children: [
                  _HoldControl(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onStart: () => _game.setMoveLeft(true),
                    onStop: () => _game.setMoveLeft(false),
                  ),
                  const SizedBox(width: 14),
                  _HoldControl(
                    icon: Icons.arrow_forward_ios_rounded,
                    onStart: () => _game.setMoveRight(true),
                    onStop: () => _game.setMoveRight(false),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: padding.bottom + 18,
            right: padding.right + 18,
            child: IgnorePointer(
              ignoring: _returningToMap,
              child: _JumpControl(onPressed: _game.jump),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HudButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: Colors.teal[800]),
        ),
      ),
    );
  }
}

class _AdventureTimerCapsule extends StatefulWidget {
  final int remainingSeconds;
  final bool isUrgent;

  const _AdventureTimerCapsule({
    super.key,
    required this.remainingSeconds,
    required this.isUrgent,
  });

  @override
  State<_AdventureTimerCapsule> createState() => _AdventureTimerCapsuleState();
}

class _AdventureTimerCapsuleState extends State<_AdventureTimerCapsule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _AdventureTimerCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.isUrgent) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeSeconds = max(0, widget.remainingSeconds);
    final minutes = (safeSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (safeSeconds % 60).toString().padLeft(2, '0');
    final accent = widget.isUrgent ? Colors.red[700]! : Colors.teal[800]!;
    final background = widget.isUrgent ? Colors.red[50]! : Colors.teal[50]!;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Opacity(
        opacity: widget.isUrgent ? 1 - _pulseController.value * 0.45 : 1,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(alpha: 0.48),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Semantics(
          label: 'Waktu tersisa: $minutes:$seconds',
          excludeSemantics: true,
          child: Text(
            '⏱️ $minutes:$seconds',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _HudStatCapsule extends StatelessWidget {
  final String emoji;
  final int value;
  final String label;
  final Color accent;

  const _HudStatCapsule({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Text(
          '$emoji $value',
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

class _JumpControl extends StatelessWidget {
  final VoidCallback onPressed;

  const _JumpControl({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('adventure-jump'),
      color: Colors.amber[400],
      elevation: 9,
      shadowColor: Colors.amber[900],
      shape: CircleBorder(
        side: BorderSide(color: Colors.green[800]!, width: 3),
      ),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onPressed(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 92,
            height: 92,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.green[900],
                  size: 40,
                ),
                Text(
                  'Lompat',
                  style: TextStyle(
                    color: Colors.green[900],
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
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

class _HoldControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _HoldControl({
    required this.icon,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onStart(),
      onPointerUp: (_) => onStop(),
      onPointerCancel: (_) => onStop(),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.teal[700]!, width: 3),
        ),
        child: Icon(icon, color: Colors.teal[800], size: 34),
      ),
    );
  }
}

enum AdventureQuizMode { treasureChest, finalGate }

class AdventureQuizResult {
  final bool passed;
  final int skor;
  final int nyawa;
  final int jumlahBenar;
  final int totalQuestions;
  final int stars;
  final bool completedAll;
  final bool perfect;

  const AdventureQuizResult({
    required this.passed,
    required this.skor,
    required this.nyawa,
    this.jumlahBenar = 0,
    this.totalQuestions = 9,
    this.stars = 0,
    this.completedAll = true,
    this.perfect = false,
  });
}

class AdventureQuizDialog extends StatefulWidget {
  final int pulauId;
  final String namaPulau;
  final int initialNyawa;
  final AdventureQuizMode mode;
  final List<Map<String, dynamic>>? questions;
  final ValueChanged<int>? onNyawaChanged;

  const AdventureQuizDialog({
    super.key,
    required this.pulauId,
    required this.namaPulau,
    required this.initialNyawa,
    this.mode = AdventureQuizMode.finalGate,
    this.questions,
    this.onNyawaChanged,
  });

  @override
  State<AdventureQuizDialog> createState() => _AdventureQuizDialogState();
}

class _AdventureQuizDialogState extends State<AdventureQuizDialog> {
  final StorageService _storage = StorageService();
  List<Map<String, dynamic>> _questions = [];
  int _index = 0;
  int _benar = 0;
  int _nyawa = StorageService.defaultNyawa;
  int? _selectedIndex;
  bool _answered = false;
  bool _finished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nyawa = widget.initialNyawa;
    _loadQuestions();
  }

  void _loadQuestions() {
    try {
      final source = widget.questions ??
          BankSoal.getSoalPetualangan(widget.pulauId).skip(11).take(9).toList();
      _questions = FisherYatesShuffler.acakDaftarSoal(source);
      final validCount = widget.mode == AdventureQuizMode.treasureChest
          ? _questions.isNotEmpty && _questions.length <= 3
          : _questions.length == 9;
      _error = validCount ? null : 'Soal untuk ujian ini belum tersedia.';
    } catch (_) {
      _questions = [];
      _error = 'Soal tidak dapat dimuat. Silakan coba lagi.';
    }
    _index = 0;
    _benar = 0;
    _selectedIndex = null;
    _answered = false;
    _finished = false;
    if (mounted) setState(() {});
  }

  Future<void> _answer(int index) async {
    if (_answered || _finished || _questions.isEmpty) return;
    final question = _questions[_index];
    final isCorrect = index == question['jawabanBenar'] as int;
    setState(() {
      _answered = true;
      _selectedIndex = index;
      if (isCorrect) _benar++;
    });

    final int nyawa;
    if (widget.mode == AdventureQuizMode.treasureChest) {
      nyawa = isCorrect ? await _storage.tambahNyawa(2) : _nyawa;
    } else {
      nyawa = isCorrect
          ? await _storage.tambahNyawa(1)
          : await _storage.kurangiNyawa(1);
    }
    if (!mounted) return;
    setState(() => _nyawa = nyawa);
    widget.onNyawaChanged?.call(nyawa);
    if (widget.mode == AdventureQuizMode.finalGate && _nyawa <= 0) {
      _finish();
    }
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selectedIndex = null;
        _answered = false;
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    final result = _makeResult(_passed);
    setState(() => _finished = true);
    if (widget.mode == AdventureQuizMode.treasureChest) {
      Navigator.pop(context, result);
    }
  }

  void _retry() {
    if (_nyawa <= 0) {
      _exitResult();
    } else {
      _loadQuestions();
    }
  }

  void _exitResult() => Navigator.pop(context, _makeResult(_passed));

  AdventureQuizResult _makeResult(bool passed) {
    return AdventureQuizResult(
      passed: passed,
      skor: _score,
      nyawa: _nyawa,
      jumlahBenar: _benar,
      totalQuestions:
          widget.mode == AdventureQuizMode.finalGate ? 9 : _questions.length,
      stars: _stars,
      completedAll: _completedAll,
      perfect: _perfect,
    );
  }

  bool get _completedAll =>
      _questions.isNotEmpty && _index == _questions.length - 1;

  bool get _passed =>
      _completedAll &&
      _nyawa > 0 &&
      (widget.mode == AdventureQuizMode.treasureChest ||
          _benar >= AdventureFSM.finalExamPassScore);

  bool get _perfect =>
      widget.mode == AdventureQuizMode.finalGate &&
      _completedAll &&
      _benar == 9 &&
      _nyawa > 0;

  int get _stars {
    if (widget.mode != AdventureQuizMode.finalGate || !_completedAll) return 0;
    if (_benar >= 7) return 3;
    if (_benar >= 4) return 2;
    if (_benar >= 1) return 1;
    return 0;
  }

  int get _score =>
      _questions.isEmpty ? 0 : (_benar / _questions.length * 100).round();

  @override
  Widget build(BuildContext context) {
    final question = _questions.isEmpty ? null : _questions[_index];
    final options = question == null
        ? <String>[]
        : (question['opsi'] as List).cast<String>();
    final correctIndex = question?['jawabanBenar'] as int?;
    final isCorrect =
        _answered && _selectedIndex != null && _selectedIndex == correctIndex;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    ),
                  ],
                )
              : _finished
                  ? _buildResult()
                  : _buildQuestion(options, correctIndex, isCorrect),
        ),
      ),
    );
  }

  Widget _buildQuestion(
    List<String> options,
    int? correctIndex,
    bool isCorrect,
  ) {
    final isTreasureChest = widget.mode == AdventureQuizMode.treasureChest;
    final feedback = isCorrect
        ? (isTreasureChest
            ? '✨ Benar! Harta Karun +2 ❤️ Nyawa'
            : '✨ MasyaAllah, Benar! +1 ❤️ Nyawa')
        : (isTreasureChest
            ? '💡 Belum tepat! Tenang, nyawamu aman di peti harta karun'
            : '❌ Kurang Tepat! -1 ❤️ Nyawa');
    final feedbackColor = isCorrect
        ? Colors.green[800]!
        : (isTreasureChest ? Colors.amber[900]! : Colors.red[800]!);
    final feedbackBackground = isCorrect
        ? Colors.green[50]
        : (isTreasureChest ? Colors.amber[50] : Colors.red[50]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isTreasureChest
                    ? 'Peti Harta Karun'
                    : 'Ujian Akhir ${widget.namaPulau}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Colors.red, size: 21),
                  const SizedBox(width: 5),
                  Text('$_nyawa',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Soal ${_index + 1}/${_questions.length}'),
        const SizedBox(height: 12),
        Text(
          _questions[_index]['pertanyaan'] as String,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                Color? background;
                if (_answered) {
                  if (index == correctIndex) {
                    background = Colors.green[100];
                  } else if (index == _selectedIndex) {
                    background = Colors.red[100];
                  }
                }
                return SizedBox(
                  width: width,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _answered ? null : () => _answer(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: background ?? Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      option,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (_answered) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: feedbackBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              feedback,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: feedbackColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _next,
            child: Text(
              _index == _questions.length - 1 ? 'Lihat Hasil' : 'Lanjut',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResult() {
    final passed = _passed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed
              ? Icons.emoji_events_rounded
              : Icons.sentiment_dissatisfied_rounded,
          size: 72,
          color: passed ? Colors.amber[700] : Colors.red[400],
        ),
        const SizedBox(height: 12),
        Text(
          passed ? 'LULUS!' : 'BELUM LULUS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: passed ? Colors.green[800] : Colors.red[800],
          ),
        ),
        const SizedBox(height: 10),
        Text('Skor: $_score'),
        Text('Benar: $_benar/9'),
        Text('Nyawa: $_nyawa'),
        if (_completedAll) ...[
          const SizedBox(height: 8),
          Text('Bintang Pulau: $_stars/3'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) => Icon(
                Icons.star_rounded,
                color: index < _stars ? Colors.amber[700] : Colors.grey[300],
                size: 32,
              ),
            ),
          ),
        ],
        if (_perfect) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '🏆 LUAR BIASA! 9/9 Benar Sempurna! Piala Penghargaan Pulau ${widget.pulauId} Terbuka!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.amber[900]!,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ] else if (!passed && _completedAll && _nyawa > 0) ...[
          const SizedBox(height: 12),
          Text(
            'Kamu menjawab $_benar/9 benar. Minimal 6 benar untuk membuka gerbang pulau berikutnya!',
            textAlign: TextAlign.center,
          ),
        ],
        if (_nyawa <= 0) ...[
          const SizedBox(height: 10),
          const Text(
            _AdventureScreenState._pesanNyawaHabis,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 18),
        if (!passed && _nyawa > 0)
          ElevatedButton(
            onPressed: _retry,
            child: const Text('Coba Lagi'),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _exitResult,
          child: Text(passed ? 'Buka Gerbang' : 'Keluar dari Ujian'),
        ),
      ],
    );
  }
}
