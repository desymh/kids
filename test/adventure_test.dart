import 'dart:ui' as ui;

import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/fsm/adventure_fsm.dart';
import 'package:qalbukids/core/fsm_controller.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/data/bank_soal.dart';
import 'package:qalbukids/game/qalbukids_adventure_game.dart';
import 'package:qalbukids/screens/adventure_screen.dart';
import 'package:qalbukids/screens/peta_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pesanNyawaHabis =
    'Nyawamu habis (0 ❤️)! Yuk baca materi di Menu Belajar atau selesaikan Simulasi Praktik untuk menambah nyawa.';

String _currentQuestion(WidgetTester tester) {
  final questions =
      BankSoal.bank.map((question) => question['pertanyaan']).toSet();
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final value = text.data;
    if (value != null && questions.contains(value)) return value;
  }
  throw TestFailure('Current quiz question was not found.');
}

String _optionForCurrentQuestion(
  WidgetTester tester, {
  required bool correct,
}) {
  final question = BankSoal.bank.firstWhere(
    (question) => question['pertanyaan'] == _currentQuestion(tester),
  );
  final options = (question['opsi'] as List).cast<String>();
  final correctOption = options[question['jawabanBenar'] as int];
  return correct
      ? correctOption
      : options.firstWhere((option) => option != correctOption);
}

List<List<Map<String, dynamic>>> _treasureGroups() {
  final questions = BankSoal.getSoalPetualangan(1).take(11).toList();
  return partitionTreasureChestQuestions(questions, random: Random(12));
}

Future<AdventureQuizResult> _answerGateQuiz(
  WidgetTester tester, {
  required int correctCount,
  required int initialNyawa,
  int pulauId = 1,
  void Function()? onResult,
}) async {
  SharedPreferences.setMockInitialValues(
      {StorageService.keyNyawa: initialNyawa});
  final storage = StorageService();
  await storage.init();
  AdventureQuizResult? result;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              result = await showDialog<AdventureQuizResult>(
                context: context,
                barrierDismissible: false,
                builder: (_) => AdventureQuizDialog(
                  pulauId: pulauId,
                  namaPulau: BankSoal.islandName(pulauId),
                  initialNyawa: initialNyawa,
                ),
              );
            },
            child: const Text('Buka Ujian'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka Ujian'));
  await tester.pumpAndSettle();

  for (var i = 0; i < 9; i++) {
    final correct =
        _optionForCurrentQuestion(tester, correct: i < correctCount);
    await tester.tap(find.widgetWithText(ElevatedButton, correct));
    await tester.pumpAndSettle();
    await tester.tap(find.text(i == 8 ? 'Lihat Hasil' : 'Lanjut'));
    await tester.pumpAndSettle();
  }

  onResult?.call();
  final passed = correctCount >= 6 && initialNyawa - (9 - correctCount) > 0;
  await tester.tap(find.text(passed ? 'Buka Gerbang' : 'Keluar dari Ujian'));
  await tester.pumpAndSettle();
  final quizResult = result;
  if (quizResult == null) {
    throw TestFailure('The gate quiz did not return a result.');
  }
  return quizResult;
}

Future<void> _pumpQuiz(
  WidgetTester tester, {
  required int nyawa,
  AdventureQuizMode mode = AdventureQuizMode.finalGate,
  List<Map<String, dynamic>>? questions,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdventureQuizDialog(
          pulauId: 1,
          namaPulau: 'Pondasi Islam',
          initialNyawa: nyawa,
          mode: mode,
          questions: questions,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<QalbuKidsAdventureGame> _pumpAdventureGame(
  WidgetTester tester, {
  int pulauId = 1,
  void Function()? onGateTriggered,
  void Function()? onGateOpened,
  void Function()? onCoinCollected,
  void Function(TreasureChestComponent chest)? onTreasureChestTriggered,
  void Function()? onObstacleHit,
  bool obstaclesEnabled = false,
  List<List<Map<String, dynamic>>> treasureQuestionGroups = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(960, 540);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final game = QalbuKidsAdventureGame(
    pulauId: pulauId,
    onGateTriggered: onGateTriggered ?? () {},
    onGateOpened: onGateOpened,
    onCoinCollected: onCoinCollected,
    onTreasureChestTriggered: onTreasureChestTriggered,
    onObstacleHit: onObstacleHit,
    obstaclesEnabled: obstaclesEnabled,
    treasureQuestionGroups: treasureQuestionGroups,
  );
  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await Future<void>.sync(() => game.toBeLoaded())
        .timeout(const Duration(seconds: 5));
    await tester.pump();
  });
  game.pauseEngine();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  return game;
}

Future<QalbuKidsAdventureGame> _pumpAdventureScreen(
  WidgetTester tester, {
  int pulauId = 1,
  Duration timeLimit = const Duration(seconds: 180),
  Map<String, Object> preferences = const {},
  bool obstaclesEnabled = false,
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(960, 540);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      home: AdventureScreen(
        pulauId: pulauId,
        namaPulau: BankSoal.islandName(pulauId),
        timeLimit: timeLimit,
        obstaclesEnabled: obstaclesEnabled,
      ),
    ),
  );
  await tester.pump();
  final gameFinder = find.byWidgetPredicate((widget) => widget is GameWidget);
  final gameWidget = tester.widget<GameWidget>(gameFinder);
  final game = gameWidget.game as QalbuKidsAdventureGame;
  for (var i = 0; i < 100 && !game.isLoaded; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(game.isLoaded, isTrue);
  game.pauseEngine();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdventureFSM', () {
    test('moves between idle and walk while the gate is locked', () {
      final fsm = AdventureFSM();
      expect(fsm.playerState, PlayerState.idle);
      expect(fsm.gateState, GateState.locked);

      fsm.updateMovement(true);
      expect(fsm.playerState, PlayerState.walk);
      fsm.updateMovement(false);
      expect(fsm.playerState, PlayerState.idle);
    });

    test('gate collision starts the quiz and blocks movement', () {
      final fsm = AdventureFSM();
      expect(fsm.beginQuiz(), isTrue);
      expect(fsm.playerState, PlayerState.interact);
      expect(fsm.gateState, GateState.quizActive);
      expect(fsm.canMove, isFalse);

      fsm.updateMovement(true);
      expect(fsm.playerState, PlayerState.interact);
      expect(fsm.beginQuiz(), isFalse);
    });

    test('only a passing score unlocks the gate', () {
      final fsm = AdventureFSM()..beginQuiz();
      expect(fsm.finishQuiz(skor: 59), isFalse);
      expect(fsm.gateState, GateState.locked);
      expect(fsm.playerState, PlayerState.idle);

      expect(fsm.beginQuiz(), isTrue);
      expect(fsm.finishQuiz(skor: 60), isTrue);
      expect(fsm.gateState, GateState.unlocked);
      expect(fsm.playerState, PlayerState.idle);
    });

    test('final gate uses the exact six-of-nine pass threshold', () {
      final fsm = AdventureFSM()..beginQuiz();
      expect(fsm.finishQuiz(skor: 100, jumlahBenar: 5), isFalse);
      expect(fsm.gateState, GateState.locked);

      expect(fsm.beginQuiz(), isTrue);
      expect(fsm.finishQuiz(skor: 0, jumlahBenar: 6), isTrue);
      expect(fsm.gateState, GateState.unlocked);
    });

    test('canceling a quiz returns the gate to locked', () {
      final fsm = AdventureFSM()..beginQuiz();
      fsm.cancelQuiz();
      expect(fsm.gateState, GateState.locked);
      expect(fsm.playerState, PlayerState.idle);
    });
  });

  group('Adventure platforming', () {
    testWidgets('Zaid jumps, reaches high coins, and lands precisely',
        (tester) async {
      final game = await _pumpAdventureGame(tester);
      final groundY = game.player.groundY;

      expect(game.velocityY, 0);
      expect(game.gravity, 1150);
      expect(game.isOnGround, isTrue);

      game.jump();
      expect(game.velocityY, -520);
      expect(game.isOnGround, isFalse);
      game.update(0.20);
      expect(game.player.position.y, lessThan(groundY - 50));
      final risingVelocity = game.velocityY;
      game.jump();
      expect(game.velocityY, risingVelocity);

      for (var i = 0; i < 60 && !game.isOnGround; i++) {
        game.update(1 / 60);
      }
      expect(game.isOnGround, isTrue);
      expect(game.velocityY, 0);
      expect(game.player.position.y, closeTo(groundY, 0.001));

      final highCoin = game.coins.elementAt(6);
      game.player.position.x = highCoin.position.x;
      game.update(0);
      expect(highCoin.isCollected, isFalse);

      game.jump();
      for (var i = 0; i < 28; i++) {
        game.update(1 / 60);
      }
      expect(game.player.position.y, lessThan(groundY - 100));
      expect(highCoin.isCollected, isTrue);
      for (var i = 0; i < 60 && !game.isOnGround; i++) {
        game.update(1 / 60);
      }
      expect(game.player.position.y, closeTo(groundY, 0.001));

      game.fsm.beginQuiz();
      game.jump();
      expect(game.velocityY, 0);
      expect(game.isOnGround, isTrue);
    });

    testWidgets('sixteen coins use four platformer patterns before the gate',
        (tester) async {
      final game = await _pumpAdventureGame(tester);
      final coins = game.coins.toList();
      final heights = coins.map((coin) => coin.heightAboveGround).toList();
      const heightRatios = [
        0.14,
        0.14,
        0.14,
        0.22,
        0.30,
        0.38,
        0.30,
        0.22,
        0.14,
        0.14,
        0.14,
        0.22,
        0.30,
        0.38,
        0.30,
        0.22,
      ];

      expect(QalbuKidsAdventureGame.coinPatternCount, 4);
      expect(QalbuKidsAdventureGame.coinCount, 16);
      expect(coins, hasLength(16));
      expect(
        heights,
        [for (final ratio in heightRatios) game.size.y * ratio],
      );
      for (var i = 0; i < coins.length; i++) {
        final coin = coins[i];
        expect(
          coin.basePosition.y,
          closeTo(game.surfaceY - heights[i], 0.001),
        );
        expect(coin.anchor, Anchor.center);
        expect(coin.priority, 12);
        expect(
          coin.position.x,
          lessThan(
            game.guardian.position.x -
                QalbuKidsAdventureGame.guardianCollisionDistance,
          ),
        );
        if (i > 0) {
          expect(coin.position.x, greaterThan(coins[i - 1].position.x));
        }
      }
    });

    testWidgets('touching a coin removes it once and emits a sparkle callback',
        (tester) async {
      var pickups = 0;
      final game = await _pumpAdventureGame(
        tester,
        onCoinCollected: () => pickups++,
      );
      final coin = game.coins.first;

      game.player.position.x = coin.position.x;
      game.update(0);
      expect(coin.isCollected, isTrue);
      expect(game.collectedCoins, 1);
      expect(pickups, 1);

      game.update(0);
      expect(game.collectedCoins, 1);
      expect(pickups, 1);
      await tester.pump();
      expect(
        game.world.children.whereType<CoinCollectionEffect>(),
        isNotEmpty,
      );
    });

    testWidgets('adventure HUD updates and persists coins in real time',
        (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              SystemChannels.platform, (call) async => null);
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });
      SharedPreferences.setMockInitialValues({
        StorageService.keyKoin: 40,
        StorageService.keyNyawa: 7,
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(960, 540);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      late QalbuKidsAdventureGame game;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: AdventureScreen(pulauId: 1, namaPulau: 'Pondasi Islam'),
          ),
        );
        await tester.pump();
        final gameFinder = find.byWidgetPredicate(
          (widget) => widget is GameWidget,
        );
        final gameWidget = tester.widget<GameWidget>(gameFinder);
        game = gameWidget.game as QalbuKidsAdventureGame;
        await Future<void>.sync(() => game.toBeLoaded())
            .timeout(const Duration(seconds: 5));
        await tester.pump();
      });
      game.pauseEngine();
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }

      final coinCapsule = find.byKey(const ValueKey('adventure-coins'));
      final lifeCapsule = find.byKey(const ValueKey('adventure-lives'));
      final jumpButton = find.byKey(const ValueKey('adventure-jump'));
      expect(find.descendant(of: coinCapsule, matching: find.text('🪙 40')),
          findsOneWidget);
      expect(find.descendant(of: lifeCapsule, matching: find.text('❤️ 7')),
          findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
      expect(tester.getTopLeft(jumpButton).dx, greaterThan(480));
      expect(tester.getTopLeft(jumpButton).dy, greaterThan(270));
      expect(tester.getTopLeft(lifeCapsule).dx,
          greaterThan(tester.getTopLeft(coinCapsule).dx));

      await tester.tap(jumpButton);
      expect(game.velocityY, -520);
      expect(game.isOnGround, isFalse);
      for (var i = 0; i < 60 && !game.isOnGround; i++) {
        game.update(1 / 60);
      }
      expect(game.isOnGround, isTrue);

      final coin = game.coins.first;
      game.player.position.x = coin.position.x;
      game.update(0);
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump();
      expect(find.descendant(of: coinCapsule, matching: find.text('🪙 41')),
          findsOneWidget);
      expect(game.collectedCoins, 1);
      final savedCoins = await tester.runAsync(
        () => StorageService().getKoin(),
      );
      expect(savedCoins, 41);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('Treasure chests', () {
    testWidgets('five chests use fixed roomy slots between coin patterns',
        (tester) async {
      final groups = List.generate(
        5,
        (index) => [
          {
            'id': 'layout_$index',
            'pertanyaan': 'Pertanyaan $index',
            'opsi': ['A', 'B', 'C', 'D'],
            'jawabanBenar': 0,
          },
        ],
      );
      final game = await _pumpAdventureGame(
        tester,
        treasureQuestionGroups: groups,
      );
      final chests = game.treasureChests.toList();

      expect(
        chests.map((chest) => chest.position.x).toList(),
        [450, 850, 1250, 1650, 2050],
      );
      expect(
        chests.map((chest) => chest.isFloating).toList(),
        [false, true, false, true, false],
      );
      for (final coin in game.coins) {
        for (final chest in chests) {
          expect(
            (coin.position.x - chest.position.x).abs(),
            greaterThan((coin.size.x + chest.size.x) / 2),
          );
        }
      }
    });

    testWidgets(
        'eleven questions form varied chests on the road and in the air',
        (tester) async {
      final groups = _treasureGroups();
      final game = await _pumpAdventureGame(
        tester,
        treasureQuestionGroups: groups,
      );
      final chests = game.treasureChests.toList();
      final ids = chests
          .expand((chest) => chest.questions)
          .map((question) => question['id'])
          .toList();

      expect(groups.length, inInclusiveRange(4, 6));
      expect(chests, hasLength(groups.length));
      expect(ids, hasLength(11));
      expect(ids.toSet(), hasLength(11));
      for (final group in groups) {
        expect(group.length, inInclusiveRange(1, 3));
      }
      expect(chests.any((chest) => !chest.isFloating), isTrue);
      expect(chests.any((chest) => chest.isFloating), isTrue);

      for (var i = 0; i < chests.length; i++) {
        final chest = chests[i];
        expect(chest.state, TreasureChestState.closed);
        expect(chest.anchor, Anchor.bottomCenter);
        expect(chest.priority, 15);
        expect(chest.position.x, lessThan(game.guardian.position.x - 180));
        if (chest.isFloating) {
          expect(
            chest.basePosition.y,
            closeTo(
              game.surfaceY -
                  (game.size.y *
                      QalbuKidsAdventureGame.floatingChestHeightRatio),
              0.001,
            ),
          );
        } else {
          expect(chest.basePosition.y, closeTo(game.surfaceY, 0.001));
        }
        if (i > 0) {
          final spacing = chest.position.x - chests[i - 1].position.x;
          expect(spacing, greaterThan(0));
          expect(
            spacing,
            greaterThanOrEqualTo(
              QalbuKidsAdventureGame.treasureChestMinSpacing - 0.001,
            ),
          );
        }
      }
    });

    testWidgets('a touched chest opens once and blocks movement while active',
        (tester) async {
      var triggers = 0;
      TreasureChestComponent? triggeredChest;
      final game = await _pumpAdventureGame(
        tester,
        treasureQuestionGroups: _treasureGroups(),
        onTreasureChestTriggered: (chest) {
          triggers++;
          triggeredChest = chest;
        },
      );
      final chest =
          game.treasureChests.firstWhere((chest) => !chest.isFloating);
      game.player.position.x = chest.position.x;
      game.update(0);

      expect(triggers, 1);
      expect(triggeredChest, same(chest));
      expect(game.activeTreasureChest, same(chest));
      expect(game.fsm.playerState, PlayerState.idle);
      final frozenX = game.player.position.x;
      game.setMoveRight(true);
      game.update(0.1);
      game.jump();
      expect(game.player.position.x, frozenX);
      expect(game.velocityY, 0);
      expect(game.isOnGround, isTrue);

      game.completeTreasureChest(chest);
      expect(chest.state, TreasureChestState.opened);
      expect(game.activeTreasureChest, isNull);
      game.update(0);
      expect(triggers, 1);
    });

    testWidgets('a floating chest cannot be touched from the ground',
        (tester) async {
      var triggers = 0;
      final game = await _pumpAdventureGame(
        tester,
        treasureQuestionGroups: _treasureGroups(),
        onTreasureChestTriggered: (_) => triggers++,
      );
      final chest = game.treasureChests.firstWhere((chest) => chest.isFloating);
      game.player.position.x = chest.position.x;
      game.update(0);
      expect(triggers, 0);

      game.jump();
      for (var i = 0; i < 60 && triggers == 0; i++) {
        game.update(1 / 60);
      }
      expect(triggers, 1);
      expect(game.activeTreasureChest, same(chest));
      expect(game.isOnGround, isFalse);
    });
  });

  group('Adventure obstacles', () {
    testWidgets('three varied obstacles keep safe route clearance',
        (tester) async {
      final game = await _pumpAdventureGame(
        tester,
        obstaclesEnabled: true,
        treasureQuestionGroups: _treasureGroups(),
      );
      final obstacles = game.obstacles.toList()
        ..sort((a, b) => a.basePosition.x.compareTo(b.basePosition.x));
      final groundChests =
          game.treasureChests.where((chest) => !chest.isFloating).toList();
      final guardianLeft = game.guardian.position.x - game.guardian.size.x / 2;

      expect(obstacles, hasLength(3));
      expect(
        obstacles.where((obstacle) => obstacle.isMoving),
        hasLength(1),
      );
      expect(
        obstacles.map((obstacle) => obstacle.kind),
        containsAll([
          ObstacleKind.gardenRock,
          ObstacleKind.thornyBush,
          ObstacleKind.rollingLantern,
        ]),
      );

      for (var i = 0; i < obstacles.length; i++) {
        final obstacle = obstacles[i];
        final leftEdge = obstacle.basePosition.x -
            obstacle.patrolRange -
            obstacle.size.x * 0.38;
        final rightEdge = obstacle.basePosition.x +
            obstacle.patrolRange +
            obstacle.size.x * 0.38;

        expect(
          obstacle.basePosition.x,
          greaterThanOrEqualTo(
            QalbuKidsAdventureGame.playerStartX +
                QalbuKidsAdventureGame.obstacleStartClearance,
          ),
        );
        expect(leftEdge, greaterThan(QalbuKidsAdventureGame.playerStartX));
        expect(
          obstacle.patrolRange,
          lessThanOrEqualTo(QalbuKidsAdventureGame.obstaclePatrolMargin),
        );
        expect(
          rightEdge,
          lessThanOrEqualTo(
            guardianLeft - QalbuKidsAdventureGame.obstacleGuardianClearance,
          ),
        );
        for (final chest in groundChests) {
          final chestGap = rightEdge < chest.position.x
              ? chest.position.x - rightEdge
              : leftEdge - chest.position.x;
          expect(
            chestGap,
            greaterThan(40),
            reason: 'Obstacle ${obstacle.kind} is too close to a ground chest.',
          );
        }
        if (i > 0) {
          expect(
            obstacle.basePosition.x - obstacles[i - 1].basePosition.x,
            greaterThanOrEqualTo(
              QalbuKidsAdventureGame.obstacleFallbackMinSpacing,
            ),
          );
        }
      }
    });

    testWidgets('rolling lanterns move back and forth inside their patrol',
        (tester) async {
      final game = await _pumpAdventureGame(
        tester,
        obstaclesEnabled: true,
      );
      final lantern =
          game.obstacles.firstWhere((obstacle) => obstacle.isMoving);
      final initialX = lantern.position.x;
      final period = 2 * pi / lantern.speed;
      final samples = <double>[initialX];

      for (var i = 0; i < 120; i++) {
        lantern.update(period / 120);
        samples.add(lantern.position.x);
      }

      final cycleSamples = samples.sublist(0, samples.length - 1);
      final minX = cycleSamples.reduce(min);
      final maxX = cycleSamples.reduce(max);
      final maxIndex = cycleSamples.indexOf(maxX);
      expect(maxX - minX, greaterThan(lantern.patrolRange * 1.9));
      expect(samples.first, closeTo(initialX, 0.0001));
      expect(samples.last, closeTo(initialX, 0.0001));
      expect(
        cycleSamples[(maxIndex - 1) % cycleSamples.length],
        lessThan(maxX),
      );
      expect(
        cycleSamples[(maxIndex + 1) % cycleSamples.length],
        lessThan(maxX),
      );
      for (final sample in samples) {
        expect(
          sample,
          inInclusiveRange(
            lantern.basePosition.x - lantern.patrolRange - 0.0001,
            lantern.basePosition.x + lantern.patrolRange + 0.0001,
          ),
        );
      }
    });

    testWidgets('obstacle impact resets Zaid but preserves coins and chests',
        (tester) async {
      var hits = 0;
      final game = await _pumpAdventureGame(
        tester,
        obstaclesEnabled: true,
        treasureQuestionGroups: _treasureGroups(),
        onTreasureChestTriggered: (_) {},
        onObstacleHit: () => hits++,
      );
      final coin = game.coins.first;
      game.player.position.x = coin.position.x;
      game.update(0);
      expect(coin.isCollected, isTrue);

      final chest = game.treasureChests
          .firstWhere((treasureChest) => !treasureChest.isFloating);
      game.player.position.x = chest.position.x;
      game.update(0);
      game.completeTreasureChest(chest);
      expect(chest.isOpened, isTrue);
      final collectedBeforeHit = game.collectedCoins;

      final obstacle = game.obstacles.first;
      game.player.position.setValues(
        obstacle.position.x,
        game.player.groundY - 12,
      );
      game.isOnGround = false;
      game.velocityY = 180;
      game.update(0);

      expect(hits, 1);
      expect(game.player.position.x, QalbuKidsAdventureGame.playerStartX);
      expect(
        game.player.position.y,
        closeTo(game.player.groundY, 0.001),
      );
      expect(game.velocityY, 0);
      expect(game.isOnGround, isTrue);
      expect(game.isShaking, isTrue);
      expect(game.collectedCoins, greaterThanOrEqualTo(collectedBeforeHit));
      expect(coin.isCollected, isTrue);
      expect(chest.isOpened, isTrue);

      game.update(QalbuKidsAdventureGame.obstacleShakeDuration);
      expect(game.isShaking, isFalse);
    });

    testWidgets('one jump clears a static obstacle without an impact',
        (tester) async {
      var hits = 0;
      final game = await _pumpAdventureGame(
        tester,
        obstaclesEnabled: true,
        onObstacleHit: () => hits++,
      );
      final obstacle =
          game.obstacles.firstWhere((candidate) => !candidate.isMoving);
      final bodyHalfWidth =
          game.player.size.x * QalbuKidsAdventureGame.playerBodyWidthRatio / 2;
      final clearedX =
          obstacle.position.x + obstacle.size.x * 0.32 + bodyHalfWidth + 2;
      game.player.position.x = obstacle.position.x - 90;
      game.jump();
      game.setMoveRight(true);

      for (var i = 0; i < 120 && game.player.position.x < clearedX; i++) {
        game.update(1 / 120);
      }
      game.stopMoving();

      expect(hits, 0);
      expect(game.isOnGround, isFalse);
      expect(game.player.position.x, greaterThanOrEqualTo(clearedX));
    });

    testWidgets('forward and jump controls clear a last-moment obstacle',
        (tester) async {
      final game = await _pumpAdventureScreen(tester, obstaclesEnabled: true);
      for (final chest in game.treasureChests) {
        chest.open();
      }
      final obstacle =
          game.obstacles.firstWhere((candidate) => !candidate.isMoving);
      final bodyHalfWidth =
          game.player.size.x * QalbuKidsAdventureGame.playerBodyWidthRatio / 2;
      final obstacleHalfWidth = obstacle.size.x * 0.32;
      final clearedX =
          obstacle.position.x + obstacleHalfWidth + bodyHalfWidth + 2;
      game.player.position.x =
          obstacle.position.x - obstacleHalfWidth - bodyHalfWidth - 1;

      final forwardControl = find.byIcon(Icons.arrow_forward_ios_rounded);
      final jumpControl = find.byKey(const ValueKey('adventure-jump'));
      final forwardGesture = await tester.startGesture(
        tester.getCenter(forwardControl),
        pointer: 1,
      );
      await tester.pump();
      game.update(0);
      expect(game.fsm.playerState, PlayerState.walk);

      final jumpGesture = await tester.startGesture(
        tester.getCenter(jumpControl),
        pointer: 2,
      );
      expect(game.isOnGround, isFalse);
      for (var i = 0; i < 120 && game.player.position.x < clearedX; i++) {
        game.update(1 / 120);
      }
      await jumpGesture.up();
      await forwardGesture.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(game.player.position.x, greaterThanOrEqualTo(clearedX));
      expect(
        game.player.position.x,
        greaterThan(QalbuKidsAdventureGame.playerStartX),
      );
      expect(
        find.byKey(const ValueKey('adventure-obstacle-warning')),
        findsNothing,
      );
    });
  });

  testWidgets('guardian quiz only triggers when the player re-enters it',
      (tester) async {
    var triggers = 0;
    final game = await _pumpAdventureGame(
      tester,
      onGateTriggered: () => triggers++,
    );

    game.setMoveRight(true);
    for (var i = 0; i < 180 && triggers == 0; i++) {
      game.update(0.1);
      await tester.pump(const Duration(milliseconds: 100));
    }
    game.stopMoving();
    expect(triggers, 1);
    expect(game.fsm.gateState, GateState.quizActive);
    expect(game.fsm.playerState, PlayerState.interact);
    expect(
      game.player.position.x,
      greaterThanOrEqualTo(
        game.guardian.position.x -
            QalbuKidsAdventureGame.guardianCollisionDistance,
      ),
    );
    expect(game.player.position.x, lessThan(game.guardian.position.x));
    expect(game.player.playing, isFalse);

    game.cancelQuiz();
    game.update(0.1);
    expect(triggers, 1);
    expect(game.fsm.gateState, GateState.locked);

    game.setMoveLeft(true);
    for (var i = 0; i < 80; i++) {
      game.update(0.1);
      await tester.pump(const Duration(milliseconds: 100));
    }
    game.stopMoving();

    game.setMoveRight(true);
    for (var i = 0; i < 80 && triggers == 1; i++) {
      game.update(0.1);
      await tester.pump(const Duration(milliseconds: 100));
    }
    game.stopMoving();
    expect(triggers, 2);
    expect(game.fsm.gateState, GateState.quizActive);
  });

  testWidgets('quiz triggers exactly at the guardian collision distance',
      (tester) async {
    var triggers = 0;
    final game = await _pumpAdventureGame(
      tester,
      onGateTriggered: () => triggers++,
    );
    final collisionX = game.guardian.position.x -
        QalbuKidsAdventureGame.guardianCollisionDistance;

    game.player.position.x = collisionX - 0.01;
    game.update(0);
    expect(triggers, 0);
    expect(game.fsm.gateState, GateState.locked);

    game.player.position.x = collisionX;
    game.update(0);
    expect(triggers, 1);
    expect(game.fsm.gateState, GateState.quizActive);
    expect(game.fsm.playerState, PlayerState.interact);
  });

  testWidgets('passing the quiz opens the gate and notifies once',
      (tester) async {
    var notifications = 0;
    final game = await _pumpAdventureGame(
      tester,
      onGateOpened: () => notifications++,
    );
    final closedSprite = game.gate.sprite;

    game.player.position.x = game.guardian.position.x -
        QalbuKidsAdventureGame.guardianCollisionDistance;
    game.player.faceDirection(-1);
    game.player.setWalkBob(0.01);
    game.setMoveRight(true);
    game.fsm.beginQuiz();
    game.update(0);
    expect(game.camera.viewfinder.position.x, greaterThan(0));

    game.completeQuiz(59);
    expect(game.fsm.gateState, GateState.locked);
    expect(game.fsm.playerState, PlayerState.idle);
    expect(game.gate.sprite, same(closedSprite));
    expect(game.player.position.x, QalbuKidsAdventureGame.playerStartX);
    expect(
      game.player.position.y,
      closeTo(game.player.groundY, 0.001),
    );
    expect(game.player.scale.x, 1);
    expect(game.player.scale.y, 1);
    expect(game.player.playing, isFalse);
    expect(game.camera.viewfinder.position.x, 0);
    expect(game.skyParallax.parallax!.baseVelocity.x, 0);
    expect(notifications, 0);

    game.fsm.beginQuiz();
    game.completeQuiz(60);
    expect(game.fsm.gateState, GateState.unlocked);
    expect(game.gate.sprite, isNot(same(closedSprite)));
    expect(notifications, 1);

    game.completeQuiz(100);
    expect(notifications, 1);
  });

  group('Adventure visuals', () {
    test('scenery assets follow the island with safe defaults', () {
      final pulau1 = QalbuKidsAdventureGame(onGateTriggered: () {});
      final pulau2 = QalbuKidsAdventureGame(
        onGateTriggered: () {},
        pulauId: 2,
      );
      final pulau3 = QalbuKidsAdventureGame(
        onGateTriggered: () {},
        pulauId: 3,
      );
      final pulau4 = QalbuKidsAdventureGame(
        onGateTriggered: () {},
        pulauId: 4,
      );

      expect(pulau1.selectedSkyAsset, 'bg_langit_masjid.png');
      expect(pulau1.selectedRoadAsset, 'ground_jalan.png');
      expect(pulau2.selectedSkyAsset, 'bg_pulau_2.png');
      expect(pulau2.selectedSkyAssetFallback, 'bg_pulau_2.jpeg');
      expect(pulau2.selectedRoadAsset, 'ground_pulau_2.png');
      expect(pulau3.selectedSkyAsset, 'bg_pulau_3.png');
      expect(pulau3.selectedSkyAssetFallback, 'bg_pulau_3.jpeg');
      expect(pulau3.selectedRoadAsset, 'ground_pulau_3.png');
      expect(pulau4.selectedSkyAsset, 'bg_pulau_4.png');
      expect(pulau4.selectedSkyAssetFallback, 'bg_pulau_4.jpeg');
      expect(pulau4.selectedRoadAsset, 'ground_pulau_4.png');
    });

    testWidgets(
        'Pulau 3 keeps its road while grounding actors and collectibles lower',
        (tester) async {
      final game = await _pumpAdventureGame(
        tester,
        pulauId: 3,
        obstaclesEnabled: true,
        treasureQuestionGroups: _treasureGroups(),
      );

      expect(game.selectedSkyAsset, 'bg_pulau_3.png');
      expect(game.selectedRoadAsset, 'ground_pulau_3.png');
      expect(
        game.surfaceY,
        closeTo(
          game.size.y * QalbuKidsAdventureGame.pulau3SurfaceYRatio,
          0.001,
        ),
      );
      final genericSurfaceY =
          game.size.y * QalbuKidsAdventureGame.surfaceYRatio;
      expect(game.surfaceY, greaterThan(genericSurfaceY));
      expect(
        game.surfaceY - genericSurfaceY,
        closeTo(
          game.size.y * QalbuKidsAdventureGame.pulau3SurfaceOffsetRatio,
          0.001,
        ),
      );
      expect(game.player.position.y, closeTo(game.surfaceY, 0.001));
      expect(game.player.groundY, closeTo(game.surfaceY, 0.001));
      expect(
        game.gate.position.y,
        closeTo(
          game.surfaceY + QalbuKidsAdventureGame.gateGroundOffset,
          0.001,
        ),
      );
      expect(game.guardian.position.y, closeTo(game.surfaceY, 0.001));
      for (final coin in game.coins) {
        expect(
          coin.basePosition.y,
          closeTo(game.surfaceY - coin.heightAboveGround, 0.001),
        );
      }
      for (final chest in game.treasureChests) {
        expect(
          chest.basePosition.y,
          closeTo(game.surfaceY - chest.heightAboveGround, 0.001),
        );
      }
      for (final obstacle in game.obstacles) {
        expect(obstacle.basePosition.y, closeTo(game.surfaceY, 0.001));
      }
      for (final tile in game.backgroundTiles) {
        expect(tile.position.y, closeTo(game.size.y, 0.001));
        expect(
          tile.position.y - tile.size.y,
          closeTo(game.size.y - game.groundHeight, 0.001),
        );
      }
    });

    testWidgets(
        'Pulau 4 keeps its road while grounding actors and collectibles lower',
        (tester) async {
      final game = await _pumpAdventureGame(
        tester,
        pulauId: 4,
        obstaclesEnabled: true,
        treasureQuestionGroups: _treasureGroups(),
      );

      expect(game.selectedSkyAsset, 'bg_pulau_4.png');
      expect(game.selectedRoadAsset, 'ground_pulau_4.png');
      expect(
        game.surfaceY,
        closeTo(
          game.size.y * QalbuKidsAdventureGame.pulau4SurfaceYRatio,
          0.001,
        ),
      );
      final genericSurfaceY =
          game.size.y * QalbuKidsAdventureGame.surfaceYRatio;
      expect(game.surfaceY, greaterThan(genericSurfaceY));
      expect(
        game.surfaceY - genericSurfaceY,
        closeTo(
          game.size.y * QalbuKidsAdventureGame.pulau4SurfaceOffsetRatio,
          0.001,
        ),
      );
      expect(game.player.position.y, closeTo(game.surfaceY, 0.001));
      expect(game.player.groundY, closeTo(game.surfaceY, 0.001));
      expect(
        game.gate.position.y,
        closeTo(
          game.surfaceY + QalbuKidsAdventureGame.gateGroundOffset,
          0.001,
        ),
      );
      expect(game.guardian.position.y, closeTo(game.surfaceY, 0.001));
      for (final coin in game.coins) {
        expect(
          coin.basePosition.y,
          closeTo(game.surfaceY - coin.heightAboveGround, 0.001),
        );
      }
      for (final chest in game.treasureChests) {
        expect(
          chest.basePosition.y,
          closeTo(game.surfaceY - chest.heightAboveGround, 0.001),
        );
      }
      for (final obstacle in game.obstacles) {
        expect(obstacle.basePosition.y, closeTo(game.surfaceY, 0.001));
      }
      for (final tile in game.backgroundTiles) {
        expect(tile.position.y, closeTo(game.size.y, 0.001));
        expect(
          tile.position.y - tile.size.y,
          closeTo(game.size.y - game.groundHeight, 0.001),
        );
      }
    });

    testWidgets(
        'Pulau 2 restores the previous bridge while Zaid stays on its deck',
        (tester) async {
      final game = await _pumpAdventureGame(
        tester,
        pulauId: 2,
        obstaclesEnabled: true,
        treasureQuestionGroups: [
          [
            {
              'pertanyaan': 'Air suci disebut?',
              'opsi': ['Ma thahur', 'Najis', 'Biasa', 'Keruh'],
              'jawabanBenar': 0,
            },
          ],
        ],
      );
      expect(
        game.groundHeight,
        closeTo(
          game.size.y * QalbuKidsAdventureGame.groundHeightRatio,
          0.001,
        ),
      );
      expect(
        game.surfaceY,
        closeTo(
          game.size.y * QalbuKidsAdventureGame.pulau2SurfaceYRatio,
          0.001,
        ),
      );
      expect(
        game.surfaceY,
        lessThan(game.size.y * QalbuKidsAdventureGame.surfaceYRatio),
      );
      expect(
        game.surfaceY,
        closeTo(game.size.y - game.groundHeight, 0.001),
      );
      expect(game.player.position.y, closeTo(game.surfaceY, 0.001));
      expect(
        game.player.size.y,
        closeTo(
          game.size.y * QalbuKidsAdventureGame.playerHeightRatio,
          0.001,
        ),
      );
      expect(game.gate.position.x, QalbuKidsAdventureGame.worldWidth - 260);
      expect(
        game.gate.position.y,
        closeTo(
          game.surfaceY + QalbuKidsAdventureGame.gateGroundOffset,
          0.001,
        ),
      );
      expect(
        game.gate.size.y,
        closeTo(
          game.size.y * QalbuKidsAdventureGame.gateHeightRatio,
          0.001,
        ),
      );
      expect(
        game.guardian.position.x,
        closeTo(game.gate.position.x - (game.gate.size.x * 0.38), 0.001),
      );
      expect(game.guardian.position.y, closeTo(game.surfaceY, 0.001));
      expect(
        game.guardian.size.y,
        closeTo(
          game.size.y * QalbuKidsAdventureGame.guardianHeightRatio,
          0.001,
        ),
      );
      for (final coin in game.coins) {
        expect(
          coin.basePosition.y,
          closeTo(game.surfaceY - coin.heightAboveGround, 0.001),
        );
        expect(
          coin.position.x + coin.size.x / 2,
          lessThan(game.guardian.position.x - 180),
        );
      }
      for (final chest in game.treasureChests) {
        expect(
          chest.basePosition.y,
          closeTo(game.surfaceY - chest.heightAboveGround, 0.001),
        );
        expect(
          chest.position.x + chest.size.x / 2,
          lessThan(game.guardian.position.x - 180),
        );
      }
      for (final obstacle in game.obstacles) {
        expect(obstacle.basePosition.y, closeTo(game.surfaceY, 0.001));
      }

      game.jump();
      for (var i = 0; i < 60 && !game.isOnGround; i++) {
        game.update(1 / 60);
      }
      expect(game.isOnGround, isTrue);
      expect(game.player.position.y, closeTo(game.surfaceY, 0.001));

      final renderer =
          game.skyParallax.parallax!.layers.single.parallaxRenderer;
      expect(renderer.repeat, ImageRepeat.repeatX);
      expect(renderer.fill, LayerFill.height);
      expect(renderer.alignment, Alignment.bottomLeft);

      final tile = game.backgroundTiles.first;
      expect(tile.sprite!.srcPosition.x, 0);
      expect(
        tile.sprite!.srcPosition.y,
        QalbuKidsAdventureGame.roadContentTop,
      );
      expect(
        tile.sprite!.srcSize.x,
        QalbuKidsAdventureGame.roadContentWidth,
      );
      expect(
        tile.sprite!.srcSize.y,
        QalbuKidsAdventureGame.roadContentHeight,
      );
      expect(
        tile.position.y - tile.size.y,
        closeTo(game.surfaceY, 0.001),
      );
      expect(
        tile.size.y,
        closeTo(game.size.y * QalbuKidsAdventureGame.roadHeightRatio, 0.001),
      );
      expect(tile.position.y, closeTo(game.size.y, 0.001));
    });

    testWidgets('AdventureScreen passes the active island to the game',
        (tester) async {
      final game = await _pumpAdventureScreen(tester, pulauId: 2);

      expect(game.pulauId, 2);
      expect(game.selectedSkyAsset, 'bg_pulau_2.png');
      expect(game.selectedRoadAsset, 'ground_pulau_2.png');
    });

    testWidgets('one-way road tiles cover the bounded world seamlessly',
        (tester) async {
      final game = await _pumpAdventureGame(tester);
      final tiles = game.backgroundTiles.toList()
        ..sort((a, b) => a.tileIndex.compareTo(b.tileIndex));

      expect(tiles, hasLength(QalbuKidsAdventureGame.backgroundTileCount));
      final tileWidth = tiles.first.size.x;
      for (var i = 0; i < tiles.length; i++) {
        final tile = tiles[i];
        expect(tile.tileIndex, i);
        expect(
          tile.size.y,
          closeTo(game.size.y * QalbuKidsAdventureGame.roadHeightRatio, 0.001),
        );
        expect(tile.size.x, closeTo(tileWidth, 0.001));
        expect(tile.position.y, closeTo(game.size.y, 0.001));
        expect(tile.anchor, Anchor.bottomLeft);
        expect(tile.priority, 5);
        expect(tile.isMirrored, isFalse);
        expect(tile.scale.x, 1);
        expect(tile.scale.y, 1);
        expect(
          tile.seamBlendWidth,
          closeTo(QalbuKidsAdventureGame.roadTileOverlap, 0.001),
        );
        expect(
          tile.visualLeft,
          closeTo(
            i * (tileWidth - QalbuKidsAdventureGame.backgroundTileOverlap),
            0.001,
          ),
        );
      }

      for (var i = 1; i < tiles.length; i++) {
        expect(
          tiles[i - 1].visualRight - tiles[i].visualLeft,
          closeTo(QalbuKidsAdventureGame.backgroundTileOverlap, 0.001),
        );
      }
      expect(
        tiles.last.visualRight,
        greaterThanOrEqualTo(game.cameraBoundsWidth - 0.001),
      );
    });

    testWidgets('sky tile and viewport edges are opaque and seamless',
        (tester) async {
      final game = await _pumpAdventureGame(tester);
      final parallax = game.skyParallax.parallax!;
      final image = parallax.layers.single.parallaxRenderer.image;
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      expect(bytes, isNotNull);

      List<int> pixelAt(ByteData data, int width, int x, int y) {
        final offset = (y * width + x) * 4;
        return List<int>.generate(
          4,
          (channel) => data.getUint8(offset + channel),
        );
      }

      for (final y in [0, image.height ~/ 2, image.height - 1]) {
        final left = pixelAt(bytes!, image.width, 0, y);
        final right = pixelAt(bytes, image.width, image.width - 1, y);
        expect(left[3], 255);
        expect(right[3], 255);
        for (var channel = 0; channel < 3; channel++) {
          expect((left[channel] - right[channel]).abs(), lessThanOrEqualTo(2));
        }
      }

      final recorder = ui.PictureRecorder();
      parallax.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final rendered = await tester.runAsync(
        () => picture.toImage(game.size.x.toInt(), game.size.y.toInt()),
      );
      final renderedBytes = await tester.runAsync(
        () => rendered!.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      expect(renderedBytes, isNotNull);
      for (final y in [0, rendered!.height ~/ 2, rendered.height - 1]) {
        for (final x in [0, rendered.width - 1]) {
          final pixel = pixelAt(
            renderedBytes!,
            rendered.width,
            x,
            y,
          );
          expect(pixel[3], 255);
          expect(pixel[0] + pixel[1] + pixel[2], greaterThan(150));
        }
      }
    });

    testWidgets('sky parallax uses a soft wash and eased velocity',
        (tester) async {
      final game = await _pumpAdventureGame(tester);
      final layer = game.skyParallax.parallax!.layers.single;

      expect(game.skyParallax.priority, 0);
      expect(layer, isA<AdventureSkyParallaxLayer>());
      expect(layer.velocityMultiplier.x, closeTo(0.25, 0.0001));
      expect(layer.velocityMultiplier.y, 0);
      expect(game.backdropWash.priority, 1);
      expect(game.backdropWash.size.x, closeTo(game.size.x, 0.001));
      expect(game.backdropWash.size.y, closeTo(game.size.y, 0.001));
      expect(game.cloudCount, game.clouds.length);

      game.setMoveRight(true);
      game.update(0.1);
      final movingVelocity = game.skyParallax.parallax!.baseVelocity.x;
      expect(movingVelocity, greaterThan(0));
      expect(
        movingVelocity,
        lessThanOrEqualTo(QalbuKidsAdventureGame.parallaxSpeed),
      );

      game.stopMoving();
      game.update(0.1);
      expect(
        game.skyParallax.parallax!.baseVelocity.x,
        lessThan(movingVelocity),
      );
    });

    testWidgets('Zaid uses four walk frames and a frozen idle frame',
        (tester) async {
      final game = await _pumpAdventureGame(tester);

      expect(game.player.animation!.frames, hasLength(1));
      expect(game.player.animation!.loop, isFalse);
      expect(game.player.playing, isFalse);
      expect(game.player.animationTicker!.currentIndex, 0);

      game.player.setMovementState(PlayerState.interact);
      expect(game.player.animation!.frames, hasLength(1));
      expect(game.player.playing, isFalse);

      game.player.setMovementState(PlayerState.walk);
      final walk = game.player.animation!;
      expect(walk.frames, hasLength(4));
      expect(walk.loop, isTrue);
      expect(game.player.playing, isTrue);
      final sourceFrameWidth = walk.frames.first.sprite.image.width /
          QalbuKidsAdventureGame.playerFrameCount;
      for (var i = 0; i < walk.frames.length; i++) {
        final frame = walk.frames[i];
        expect(
          frame.stepTime,
          closeTo(QalbuKidsAdventureGame.walkStepTime, 0.0001),
        );
        expect(
          frame.sprite.srcSize.x,
          closeTo(QalbuKidsAdventureGame.playerContentWidth, 0.0001),
        );
        expect(
          frame.sprite.srcSize.y,
          closeTo(QalbuKidsAdventureGame.playerContentHeight, 0.0001),
        );
        expect(
          frame.sprite.srcPosition.x,
          closeTo(
            i * sourceFrameWidth + QalbuKidsAdventureGame.playerContentLeft,
            0.0001,
          ),
        );
      }

      game.player.update(QalbuKidsAdventureGame.walkStepTime + 0.01);
      expect(game.player.animationTicker!.currentIndex, 1);

      game.player.setMovementState(PlayerState.idle);
      expect(game.player.animation!.frames, hasLength(1));
      expect(game.player.animationTicker!.currentIndex, 0);
      expect(game.player.playing, isFalse);
    });

    testWidgets('Zaid flips only when his walking direction changes',
        (tester) async {
      final game = await _pumpAdventureGame(tester);

      expect(game.player.scale.x, 1);
      game.setMoveLeft(true);
      game.update(1 / 60);
      expect(game.fsm.playerState, PlayerState.walk);
      expect(game.player.scale.x, -1);

      game.player.faceDirection(-1);
      expect(game.player.scale.x, -1);
      game.stopMoving();
      game.update(1 / 60);
      expect(game.player.playing, isFalse);

      game.setMoveRight(true);
      game.update(1 / 60);
      expect(game.fsm.playerState, PlayerState.walk);
      expect(game.player.scale.x, 1);
    });

    testWidgets('actors use realistic proportions and precise footing',
        (tester) async {
      final game = await _pumpAdventureGame(tester);

      final groundY = game.size.y * QalbuKidsAdventureGame.groundYRatio;
      final actorY = groundY + QalbuKidsAdventureGame.actorGroundOffset;
      expect(
        game.player.size.y,
        closeTo(game.size.y * QalbuKidsAdventureGame.playerHeightRatio, 0.001),
      );
      expect(
        game.guardian.size.y,
        closeTo(
            game.size.y * QalbuKidsAdventureGame.guardianHeightRatio, 0.001),
      );
      expect(
        game.gate.size.y,
        closeTo(game.size.y * QalbuKidsAdventureGame.gateHeightRatio, 0.001),
      );
      expect(game.player.position.y, closeTo(actorY, 0.001));
      expect(game.guardian.position.y, closeTo(actorY, 0.001));
      expect(
        game.gate.position.y,
        closeTo(game.surfaceY + QalbuKidsAdventureGame.gateGroundOffset, 0.001),
      );
      expect(
        game.guardian.position.x,
        closeTo(game.gate.position.x - (game.gate.size.x * 0.38), 0.001),
      );
      expect(game.player.priority, 30);
      expect(game.gate.position.x, QalbuKidsAdventureGame.gateX);
      expect(game.cameraBoundsWidth, QalbuKidsAdventureGame.worldWidth);
      expect(game.gate.priority, 10);
      expect(game.guardian.priority, 20);
      expect(game.gate.scale.x, 1);
      expect(game.guardian.scale.x, -1);
      expect(game.player.anchor, Anchor.bottomCenter);
      expect(game.guardian.anchor, Anchor.bottomCenter);
      expect(game.gate.anchor, Anchor.bottomCenter);

      game.setMoveRight(true);
      game.update(0.05);
      final footLift = actorY - game.player.position.y;
      expect(footLift, closeTo(0, 0.001));
      expect(game.player.scale.y, lessThan(1));
      expect(
        game.player.scale.y,
        greaterThanOrEqualTo(1 - QalbuKidsAdventureGame.walkBobAmplitudeRatio),
      );
      game.stopMoving();
      game.update(0);
      expect(game.player.position.y, closeTo(actorY, 0.001));
      expect(game.player.scale.y, 1);
    });

    testWidgets('gate stands ahead of Zaid and faces the approach direction',
        (tester) async {
      final game = await _pumpAdventureGame(tester);

      expect(game.player.position.x, lessThan(game.guardian.position.x));
      expect(game.guardian.position.x, lessThan(game.gate.position.x));
      expect(
        game.guardian.position.x,
        closeTo(game.gate.position.x - (game.gate.size.x * 0.38), 0.001),
      );
      expect(game.guardian.priority, greaterThan(game.gate.priority));
      expect(game.gate.scale.x, 1);
      expect(game.gate.anchor, Anchor.bottomCenter);
    });

    testWidgets('camera uses damped manual top-left tracking', (tester) async {
      final game = await _pumpAdventureGame(tester);

      expect(game.size.x, 960);
      expect(game.size.y, 540);
      expect(game.camera.viewport, isA<MaxViewport>());
      expect(game.camera.viewport.size.x, closeTo(game.size.x, 0.001));
      expect(game.camera.viewport.size.y, closeTo(game.size.y, 0.001));
      expect(game.camera.viewfinder.zoom, 1);
      expect(game.camera.viewfinder.anchor, Anchor.topLeft);
      expect(
        game.camera.viewfinder.children.whereType<FollowBehavior>(),
        isEmpty,
      );

      game.player.position.x = 0;
      game.update(0);
      expect(game.camera.viewfinder.position.x, closeTo(0, 0.001));

      game.player.position.x = 400;
      game.update(0);
      expect(
        game.camera.viewfinder.position.x,
        closeTo(
            400 - game.size.x * QalbuKidsAdventureGame.cameraFocusRatio, 0.001),
      );

      game.fsm.beginQuiz();
      game.completeQuiz(100);
      game.player.position.x = 900;
      game.update(0);
      final previousCameraX = game.camera.viewfinder.position.x;
      game.player.position.x = 1000;
      game.update(1 / 60);
      final targetCameraX =
          1000 - game.size.x * QalbuKidsAdventureGame.cameraFocusRatio;
      expect(game.camera.viewfinder.position.x, greaterThan(previousCameraX));
      expect(game.camera.viewfinder.position.x, lessThan(targetCameraX));

      game.player.position.x = game.cameraBoundsWidth;
      game.update(0);
      expect(
        game.camera.viewfinder.position.x,
        closeTo(game.cameraBoundsWidth - game.size.x, 0.001),
      );
      expect(game.camera.viewfinder.position.y, 0);
    });

    testWidgets('camera clamp keeps both viewport edges inside the world',
        (tester) async {
      final game = await _pumpAdventureGame(tester);
      game.fsm.beginQuiz();
      game.completeQuiz(100);

      void expectVisibleAreaInsideWorld() {
        final visibleLeft = game.camera.viewfinder.position.x;
        final visibleRight = visibleLeft + game.size.x;
        expect(visibleLeft, greaterThanOrEqualTo(-0.001));
        expect(visibleRight, lessThanOrEqualTo(game.cameraBoundsWidth + 0.001));
      }

      game.player.position.x = 0;
      game.update(0);
      expectVisibleAreaInsideWorld();

      game.player.position.x = game.cameraBoundsWidth;
      game.update(0);
      expectVisibleAreaInsideWorld();
    });
  });

  test('six correct answers unlock the next island without a trophy', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    await unlockAdventureIslandProgress(
      storage: storage,
      pulauId: 1,
      skor: 67,
      jumlahBenar: 6,
      bintang: 2,
      nyawa: 8,
    );

    final states = await storage.getFsmStates();
    expect(states[ProgressionFSM.islandKey(1)], LevelState.completed);
    expect(states[ProgressionFSM.badgeKey(1)], LevelState.locked);
    expect(states[ProgressionFSM.islandKey(2)], LevelState.unlocked);
    expect(states[ProgressionFSM.stageKey(2, 1)], LevelState.unlocked);
    expect(states[ProgressionFSM.badgeKey(2)], LevelState.locked);
    expect((await storage.getLencana()).first, isFalse);
    expect(await storage.getIslandStars(1), 2);
  });

  test('nine correct answers unlock the perfect island trophy', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    await unlockAdventureIslandProgress(
      storage: storage,
      pulauId: 1,
      skor: 100,
      jumlahBenar: 9,
      bintang: 3,
      nyawa: 14,
    );

    final states = await storage.getFsmStates();
    expect(states[ProgressionFSM.islandKey(1)], LevelState.completed);
    expect(states[ProgressionFSM.badgeKey(1)], LevelState.unlocked);
    expect(states[ProgressionFSM.islandKey(2)], LevelState.unlocked);
    expect((await storage.getLencana()).first, isTrue);
    expect(await storage.getIslandStars(1), 3);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('lencana_1'), isTrue);
  });

  test('failing the adventure exam saves stars without unlocking progression',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    await unlockAdventureIslandProgress(
      storage: storage,
      pulauId: 1,
      skor: 56,
      jumlahBenar: 5,
      bintang: 1,
      nyawa: 5,
    );

    final states = await storage.getFsmStates();
    expect(states[ProgressionFSM.islandKey(1)], LevelState.unlocked);
    expect(states[ProgressionFSM.badgeKey(1)], LevelState.locked);
    expect(states[ProgressionFSM.islandKey(2)], LevelState.locked);
    expect((await storage.getLencana()).first, isFalse);
    expect(await storage.getIslandStars(1), 1);
  });

  test('later runs preserve better stars and an already earned trophy',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    await unlockAdventureIslandProgress(
      storage: storage,
      pulauId: 1,
      skor: 100,
      jumlahBenar: 9,
      bintang: 3,
      nyawa: 14,
    );
    await unlockAdventureIslandProgress(
      storage: storage,
      pulauId: 1,
      skor: 67,
      jumlahBenar: 6,
      bintang: 2,
      nyawa: 8,
    );

    expect(await storage.getIslandStars(1), 3);
    expect((await storage.getLencana()).first, isTrue);
    expect(await storage.getTotalBintang(), 3);
  });

  testWidgets('correct adventure answer adds one heart and shows feedback',
      (tester) async {
    SharedPreferences.setMockInitialValues({StorageService.keyNyawa: 4});
    final storage = StorageService();
    await storage.init();
    await _pumpQuiz(tester, nyawa: 4);

    final correct = _optionForCurrentQuestion(tester, correct: true);
    await tester.tap(find.widgetWithText(ElevatedButton, correct));
    await tester.pumpAndSettle();

    expect(await storage.getNyawa(), 5);
    expect(find.text('✨ MasyaAllah, Benar! +1 ❤️ Nyawa'), findsOneWidget);
  });

  testWidgets('correct chest answer adds two hearts with treasure feedback',
      (tester) async {
    SharedPreferences.setMockInitialValues({StorageService.keyNyawa: 4});
    final storage = StorageService();
    await storage.init();
    final question = BankSoal.getSoalPetualangan(1).first;
    await _pumpQuiz(
      tester,
      nyawa: 4,
      mode: AdventureQuizMode.treasureChest,
      questions: [question],
    );

    final correct = _optionForCurrentQuestion(tester, correct: true);
    await tester.tap(find.widgetWithText(ElevatedButton, correct));
    await tester.pumpAndSettle();

    expect(await storage.getNyawa(), 6);
    expect(find.text('✨ Benar! Harta Karun +2 ❤️ Nyawa'), findsOneWidget);
  });

  testWidgets('wrong chest answer keeps lives safe with gentle feedback',
      (tester) async {
    SharedPreferences.setMockInitialValues({StorageService.keyNyawa: 3});
    final storage = StorageService();
    await storage.init();
    final question = BankSoal.getSoalPetualangan(1).first;
    await _pumpQuiz(
      tester,
      nyawa: 3,
      mode: AdventureQuizMode.treasureChest,
      questions: [question],
    );

    final wrong = _optionForCurrentQuestion(tester, correct: false);
    await tester.tap(find.widgetWithText(ElevatedButton, wrong));
    await tester.pumpAndSettle();

    expect(await storage.getNyawa(), 3);
    expect(
      find.text('💡 Belum tepat! Tenang, nyawamu aman di peti harta karun'),
      findsOneWidget,
    );
  });

  testWidgets('wrong answer at one heart ends the adventure quiz immediately',
      (tester) async {
    SharedPreferences.setMockInitialValues({StorageService.keyNyawa: 1});
    final storage = StorageService();
    await storage.init();
    await _pumpQuiz(tester, nyawa: 1);

    final wrong = _optionForCurrentQuestion(tester, correct: false);
    await tester.tap(find.widgetWithText(ElevatedButton, wrong));
    await tester.pumpAndSettle();

    expect(await storage.getNyawa(), 0);
    expect(find.text('BELUM LULUS'), findsOneWidget);
    expect(find.text('Nyawa: 0'), findsOneWidget);
    expect(find.text(_pesanNyawaHabis), findsOneWidget);
  });

  testWidgets(
      'answering all nine gate questions correctly earns a perfect result',
      (tester) async {
    final result = await _answerGateQuiz(
      tester,
      correctCount: 9,
      initialNyawa: 5,
      onResult: () {
        expect(find.text('Bintang Pulau: 3/3'), findsOneWidget);
        expect(
          find.text(
              '🏆 LUAR BIASA! 9/9 Benar Sempurna! Piala Penghargaan Pulau 1 Terbuka!'),
          findsOneWidget,
        );
      },
    );

    expect(result.passed, isTrue);
    expect(result.jumlahBenar, 9);
    expect(result.totalQuestions, 9);
    expect(result.stars, 3);
    expect(result.perfect, isTrue);
    expect(result.nyawa, 14);
    expect(await StorageService().getNyawa(), 14);
  });

  testWidgets('final exam displays internal Pulau 6 as Pulau 5',
      (tester) async {
    final result = await _answerGateQuiz(
      tester,
      correctCount: 9,
      initialNyawa: 5,
      pulauId: 6,
      onResult: () {
        expect(
          find.text(
              '🏆 LUAR BIASA! 9/9 Benar Sempurna! Piala Penghargaan Pulau 5 Terbuka!'),
          findsOneWidget,
        );
        expect(
          find.text(
              '🏆 LUAR BIASA! 9/9 Benar Sempurna! Piala Penghargaan Pulau 6 Terbuka!'),
          findsNothing,
        );
      },
    );

    expect(result.perfect, isTrue);
  });

  for (final scenario in [
    (correct: 0, stars: 0, passed: false),
    (correct: 3, stars: 1, passed: false),
    (correct: 4, stars: 2, passed: false),
    (correct: 6, stars: 2, passed: true),
    (correct: 7, stars: 3, passed: true),
  ]) {
    testWidgets('${scenario.correct}/9 correct gives ${scenario.stars} stars',
        (tester) async {
      final result = await _answerGateQuiz(
        tester,
        correctCount: scenario.correct,
        initialNyawa: 20,
        onResult: () {
          expect(
              find.text('Bintang Pulau: ${scenario.stars}/3'), findsOneWidget);
          if (!scenario.passed) {
            expect(
              find.text(
                  'Kamu menjawab ${scenario.correct}/9 benar. Minimal 6 benar untuk membuka gerbang pulau berikutnya!'),
              findsOneWidget,
            );
          }
        },
      );

      expect(result.passed, scenario.passed);
      expect(result.jumlahBenar, scenario.correct);
      expect(result.stars, scenario.stars);
      expect(result.completedAll, isTrue);
      expect(result.perfect, isFalse);
    });
  }

  testWidgets(
      'AdventureScreen splits one shuffled pool into 11 chest and 9 gate questions',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            SystemChannels.platform, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(960, 540);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late QalbuKidsAdventureGame game;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdventureScreen(pulauId: 1, namaPulau: 'Pondasi Islam'),
        ),
      );
      await tester.pump();
      final gameFinder =
          find.byWidgetPredicate((widget) => widget is GameWidget);
      final gameWidget = tester.widget<GameWidget>(gameFinder);
      game = gameWidget.game as QalbuKidsAdventureGame;
      await Future<void>.sync(() => game.toBeLoaded())
          .timeout(const Duration(seconds: 5));
      await tester.pump();
    });
    game.pauseEngine();

    final chestIds = game.treasureChests
        .expand((chest) => chest.questions)
        .map((question) => question['id'].toString())
        .toList();
    expect(chestIds, hasLength(11));
    expect(chestIds.toSet(), hasLength(11));

    game.player.position.x = game.guardian.position.x -
        QalbuKidsAdventureGame.guardianCollisionDistance;
    game.update(0);
    tester.binding.scheduleFrame();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 2),
    );

    final dialog =
        tester.widget<AdventureQuizDialog>(find.byType(AdventureQuizDialog));
    final gateIds =
        dialog.questions!.map((question) => question['id'].toString()).toList();
    expect(gateIds, hasLength(9));
    expect(gateIds.toSet(), hasLength(9));
    expect({...chestIds, ...gateIds}, hasLength(20));
    expect(
      {...chestIds, ...gateIds},
      unorderedEquals(
        BankSoal.bank
            .where((question) => question['pulauId'] == 1)
            .map((question) => question['id'].toString()),
      ),
    );
    for (final question in dialog.questions!) {
      final options = (question['opsi'] as List).cast<String>();
      expect(options.toSet(), hasLength(4));
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a failed gate exam still saves stars without unlocking progress',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            SystemChannels.platform, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    SharedPreferences.setMockInitialValues({StorageService.keyNyawa: 20});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(960, 540);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late QalbuKidsAdventureGame game;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdventureScreen(pulauId: 1, namaPulau: 'Pondasi Islam'),
        ),
      );
      await tester.pump();
      final gameFinder =
          find.byWidgetPredicate((widget) => widget is GameWidget);
      final gameWidget = tester.widget<GameWidget>(gameFinder);
      game = gameWidget.game as QalbuKidsAdventureGame;
      await Future<void>.sync(() => game.toBeLoaded())
          .timeout(const Duration(seconds: 5));
      await tester.pump();
    });
    game.pauseEngine();

    game.player.position.x = game.guardian.position.x -
        QalbuKidsAdventureGame.guardianCollisionDistance;
    game.update(0);
    tester.binding.scheduleFrame();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 2),
    );

    for (var i = 0; i < 9; i++) {
      final option = _optionForCurrentQuestion(tester, correct: i < 3);
      await tester.tap(find.widgetWithText(ElevatedButton, option));
      await tester.pumpAndSettle();
      await tester.tap(find.text(i == 8 ? 'Lihat Hasil' : 'Lanjut'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Bintang Pulau: 1/3'), findsOneWidget);
    await tester.tap(find.text('Keluar dari Ujian'));
    await tester.pump();
    game.pauseEngine();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();

    expect(
      find.byKey(const ValueKey('adventure-quiz-failed-notification')),
      findsOneWidget,
    );
    final storage = StorageService();
    expect(await tester.runAsync(() => storage.getIslandStars(1)), 1);
    expect(
      await tester.runAsync(
        () => storage.getLevelState(ProgressionFSM.islandKey(2)),
      ),
      LevelState.locked,
    );
    final badges = await tester.runAsync(() => storage.getLencana());
    expect(badges, isNotNull);
    expect(badges!.first, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('Adventure countdown and feedback', () {
    const obstacleWarning =
        '⚠️ Ups! Kena rintangan! Ayo lompati dan mulai dari awal jalur ya!';
    const timeoutMessage =
        '⏰ Waktu Habis! Yuk coba lagi dan lebih sigap melompati rintangan serta menjawab kuis!';
    final timerFinder = find.byKey(const ValueKey('adventure-timer'));
    final timeoutFinder =
        find.byKey(const ValueKey('adventure-timeout-dialog'));

    String timerText(WidgetTester tester) {
      final text = tester.widget<Text>(
        find.descendant(of: timerFinder, matching: find.byType(Text)),
      );
      return text.data!;
    }

    Future<void> openChestQuiz(
      WidgetTester tester,
      QalbuKidsAdventureGame game,
    ) async {
      final chest = game.treasureChests
          .firstWhere((treasureChest) => !treasureChest.isFloating);
      game.player.position.x = chest.position.x;
      game.update(0);
      tester.binding.scheduleFrame();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AdventureQuizDialog), findsOneWidget);
    }

    testWidgets('shows a centered timer without obstacles and counts down',
        (tester) async {
      final game = await _pumpAdventureScreen(tester);

      expect(timerText(tester), '⏱️ 03:00');
      expect(game.obstacles, isEmpty);
      expect(tester.getCenter(timerFinder).dx, closeTo(480, 1));
      expect(tester.getCenter(timerFinder).dy, lessThan(60));

      await tester.pump(const Duration(seconds: 1));
      expect(timerText(tester), '⏱️ 02:59');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('obstacle impact shows the exact friendly warning banner',
        (tester) async {
      final game = await _pumpAdventureScreen(tester, obstaclesEnabled: true);
      final obstacle = game.obstacles.first;
      game.player.position.x = obstacle.position.x;
      game.update(0);
      await tester.pump();

      final warning = find.byKey(const ValueKey('adventure-obstacle-warning'));
      expect(warning, findsOneWidget);
      expect(find.descendant(of: warning, matching: find.text(obstacleWarning)),
          findsOneWidget);
      final banner = tester.widget<SnackBar>(warning);
      final warningText = tester.widget<Text>(
        find.descendant(of: warning, matching: find.text(obstacleWarning)),
      );
      expect(banner.backgroundColor, Colors.amber[50]);
      expect(warningText.style!.color, Colors.brown[800]);
      expect(game.player.position.x, QalbuKidsAdventureGame.playerStartX);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('timer turns red and pulses below thirty seconds',
        (tester) async {
      await _pumpAdventureScreen(
        tester,
        timeLimit: const Duration(seconds: 31),
      );
      final normalText = tester.widget<Text>(
        find.descendant(of: timerFinder, matching: find.text('⏱️ 00:31')),
      );
      expect(normalText.style!.color, Colors.teal[800]);

      await tester.pump(const Duration(seconds: 1));
      expect(timerText(tester), '⏱️ 00:30');
      final thresholdText = tester.widget<Text>(
        find.descendant(of: timerFinder, matching: find.text('⏱️ 00:30')),
      );
      expect(thresholdText.style!.color, Colors.teal[800]);

      await tester.pump(const Duration(seconds: 1));
      expect(timerText(tester), '⏱️ 00:29');
      final urgentText = tester.widget<Text>(
        find.descendant(of: timerFinder, matching: find.text('⏱️ 00:29')),
      );
      expect(urgentText.style!.color, Colors.red[700]);

      await tester.pump(const Duration(milliseconds: 550));
      final dimOpacity = tester.widget<Opacity>(
        find.descendant(of: timerFinder, matching: find.byType(Opacity)),
      );
      await tester.pump(const Duration(milliseconds: 275));
      final brightOpacity = tester.widget<Opacity>(
        find.descendant(of: timerFinder, matching: find.byType(Opacity)),
      );
      expect(dimOpacity.opacity, lessThan(brightOpacity.opacity));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('countdown keeps running during a chest quiz', (tester) async {
      final game = await _pumpAdventureScreen(
        tester,
        timeLimit: const Duration(seconds: 3),
        preferences: {StorageService.keyNyawa: 20},
      );
      await openChestQuiz(tester, game);
      final chest = game.activeTreasureChest!;

      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(AdventureQuizDialog), findsOneWidget);
      expect(timerText(tester), '⏱️ 00:01');

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.byType(AdventureQuizDialog), findsNothing);
      expect(timeoutFinder, findsOneWidget);
      expect(find.text(timeoutMessage), findsOneWidget);
      expect(game.activeTreasureChest, isNull);
      expect(chest.isOpened, isFalse);
      expect(game.paused, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('timeout stops play and retry starts a fresh island',
        (tester) async {
      final game = await _pumpAdventureScreen(
        tester,
        timeLimit: const Duration(seconds: 1),
      );
      game.resumeEngine();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(timerText(tester), '⏱️ 00:00');
      expect(timeoutFinder, findsOneWidget);
      expect(find.text(timeoutMessage), findsOneWidget);
      expect(find.text('Ulangi Pulau'), findsOneWidget);
      expect(find.text('Kembali ke Peta'), findsOneWidget);
      expect(game.fsm.gateState, GateState.locked);
      expect(game.paused, isTrue);

      await tester.tap(find.text('Ulangi Pulau'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final gameWidget = tester.widget<GameWidget>(
        find.byWidgetPredicate((widget) => widget is GameWidget),
      );
      final retryGame = gameWidget.game as QalbuKidsAdventureGame;
      await tester.runAsync(() async {
        await Future<void>.sync(() => retryGame.toBeLoaded())
            .timeout(const Duration(seconds: 5));
      });
      await tester.pump();
      retryGame.pauseEngine();

      expect(retryGame, isNot(same(game)));
      expect(retryGame.player.position.x, QalbuKidsAdventureGame.playerStartX);
      expect(retryGame.collectedCoins, 0);
      expect(timerText(tester), '⏱️ 03:00');
      expect(timeoutFinder, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('timeout map action returns directly to the island map',
        (tester) async {
      await _pumpAdventureScreen(
        tester,
        timeLimit: const Duration(seconds: 1),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.tap(find.text('Kembali ke Peta'));
      await tester.pumpAndSettle();

      expect(find.byType(AdventureScreen), findsNothing);
      expect(find.byType(PetaScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('opening the gate prevents a later timeout', (tester) async {
      final game = await _pumpAdventureScreen(
        tester,
        timeLimit: const Duration(seconds: 1),
      );
      game.fsm.beginQuiz();
      game.completeQuiz(60);
      expect(game.fsm.gateState, GateState.unlocked);

      await tester.pump(const Duration(seconds: 2));
      expect(timerText(tester), '⏱️ 00:01');
      expect(timeoutFinder, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets(
      'adventure map uses larger islands, bubbles, and overlaid Zaid with GO',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(960, 540);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      StorageService.keyAvatar: 'aisyah',
    });

    await tester.pumpWidget(const MaterialApp(home: PetaScreen()));
    await tester.pumpAndSettle();

    final map = find.byKey(const ValueKey('peta-landscape-map'));
    final mapRect = tester.getRect(map);
    expect(mapRect.width, greaterThan(mapRect.height));
    expect(find.byKey(const ValueKey('peta-bubble-path')), findsOneWidget);
    final mapScroll = find.byType(SingleChildScrollView);
    expect(mapScroll, findsOneWidget);
    expect(
      tester.widget<SingleChildScrollView>(mapScroll).scrollDirection,
      Axis.horizontal,
    );
    expect(find.byIcon(Icons.lock), findsNWidgets(4));
    expect(find.text('GO'), findsOneWidget);
    expect(find.text('MULAI'), findsNothing);
    expect(
      find.byKey(const ValueKey('peta-pulau-5-artwork')),
      findsNothing,
    );
    expect(find.text('Doa & Adab'), findsNothing);
    expect(find.text('Pulau 5: Ujian Akhir'), findsOneWidget);
    expect(find.text('Pulau 6: Ujian Akhir'), findsNothing);

    final activeArtwork = find.byKey(const ValueKey('peta-pulau-1-artwork'));
    final activeIsland = find.byKey(const ValueKey('peta-pulau-1'));
    final adventureAction = find.byKey(const ValueKey('peta-adventure-action'));
    final zaid = find.byKey(const ValueKey('peta-active-avatar'));
    final go = find.byKey(const ValueKey('peta-go-1'));
    expect(
      find.byKey(const ValueKey('peta-adventure-guide')),
      findsNothing,
    );
    expect(adventureAction, findsOneWidget);
    expect(zaid, findsOneWidget);
    expect(go, findsOneWidget);
    expect(
      find.descendant(of: adventureAction, matching: zaid),
      findsOneWidget,
    );
    expect(
      find.descendant(of: adventureAction, matching: go),
      findsOneWidget,
    );
    expect(find.descendant(of: activeIsland, matching: zaid), findsNothing);
    expect(
      find.descendant(of: activeIsland, matching: find.text('GO')),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Zaid siap berpetualang',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('peta-adventure-zaid-paint')),
      findsOneWidget,
    );
    expect(tester.widget<InkWell>(go).onTap, isNotNull);
    final goSize = tester.getSize(go);
    expect(goSize.width, lessThanOrEqualTo(40));
    expect(goSize.height, lessThanOrEqualTo(26));
    final actionRect = tester.getRect(adventureAction);
    final artworkRect = tester.getRect(activeArtwork);
    expect(actionRect.overlaps(artworkRect), isTrue);
    expect(artworkRect.contains(actionRect.topLeft), isTrue);
    expect(artworkRect.contains(actionRect.bottomRight), isTrue);
    expect(
      actionRect.bottom,
      closeTo(artworkRect.top + artworkRect.height * 0.70, 0.001),
    );
    expect(actionRect.center.dx, closeTo(artworkRect.center.dx, 1));

    final regularIslandSize = tester
        .getSize(find.byKey(const ValueKey('peta-pulau-1-artwork')))
        .width;
    final palaceIslandSize = tester
        .getSize(find.byKey(const ValueKey('peta-pulau-6-artwork')))
        .width;
    expect(regularIslandSize, greaterThan(200));
    expect(palaceIslandSize, greaterThan(regularIslandSize));

    double? previousCenterX;
    for (final island in StorageService.activeIslandIds) {
      final artwork = find.byKey(ValueKey('peta-pulau-$island-artwork'));
      final image = tester.widget<Image>(artwork);
      expect(
        (image.image as AssetImage).assetName,
        startsWith('assets/images/pulau_${island}_'),
      );
      final artworkSize = tester.getSize(artwork);
      final artworkRect = tester.getRect(artwork);
      expect(artworkSize.width, closeTo(artworkSize.height, 0.001));
      if (island != 6) {
        expect(artworkSize.width, closeTo(regularIslandSize, 0.001));
      }
      expect(artworkRect.left, greaterThanOrEqualTo(mapRect.left));
      expect(artworkRect.top, greaterThanOrEqualTo(mapRect.top));
      expect(artworkRect.right, lessThanOrEqualTo(mapRect.right));
      expect(artworkRect.bottom, lessThanOrEqualTo(mapRect.bottom));
      if (previousCenterX != null) {
        expect(artworkRect.center.dx, greaterThan(previousCenterX));
      }
      previousCenterX = artworkRect.center.dx;
    }

    final scrollable = find.descendant(
      of: mapScroll,
      matching: find.byType(Scrollable),
    );
    final scrollPosition = tester.state<ScrollableState>(scrollable).position;
    expect(scrollPosition.maxScrollExtent, greaterThan(0));
    final initialOffset = scrollPosition.pixels;
    await tester.drag(mapScroll, const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(scrollPosition.pixels, greaterThan(initialOffset));

    final firstCenter =
        tester.getCenter(find.byKey(const ValueKey('peta-pulau-1-artwork'))).dy;
    final secondCenter =
        tester.getCenter(find.byKey(const ValueKey('peta-pulau-2-artwork'))).dy;
    final thirdCenter =
        tester.getCenter(find.byKey(const ValueKey('peta-pulau-3-artwork'))).dy;
    expect(firstCenter, greaterThan(secondCenter));
    expect(thirdCenter, greaterThan(secondCenter));
    expect(
      find.byKey(const ValueKey('peta-pulau-1-circle')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('every map island shows stars with earned and locked colors',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(960, 540);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      ProgressionFSM.islandKey(1): LevelState.completed.name,
      '${ProgressionFSM.stageKey(1, StorageService.stagesPerIsland)}_bintang':
          2,
      ProgressionFSM.islandKey(2): LevelState.unlocked.name,
      '${ProgressionFSM.stageKey(3, StorageService.stagesPerIsland)}_bintang':
          3,
    });

    await tester.pumpWidget(const MaterialApp(home: PetaScreen()));
    await tester.pumpAndSettle();

    for (final island in StorageService.activeIslandIds) {
      final stars = find.byKey(ValueKey('peta-pulau-$island-stars'));
      expect(stars, findsOneWidget);
      final starIcons = tester.widgetList<Icon>(
        find.descendant(of: stars, matching: find.byIcon(Icons.star)),
      );
      expect(starIcons, hasLength(3));
      final expectedColors = island == 1
          ? [Colors.amber, Colors.amber, Colors.grey[300]]
          : [Colors.grey[300], Colors.grey[300], Colors.grey[300]];
      expect(
        starIcons.map((icon) => icon.color).toList(),
        expectedColors,
        reason:
            'Pulau $island should show its earned stars or light-gray stars',
      );
      final starsRect = tester.getRect(stars);
      final artworkRect = tester.getRect(
        find.byKey(ValueKey('peta-pulau-$island-artwork')),
      );
      expect(starsRect.top, greaterThanOrEqualTo(artworkRect.bottom));
    }
    expect(find.byIcon(Icons.star), findsNWidgets(15));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zaid and GO overlay only the active upper-route island',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      ProgressionFSM.islandKey(1): LevelState.completed.name,
      ProgressionFSM.islandKey(2): LevelState.unlocked.name,
    });

    await tester.pumpWidget(const MaterialApp(home: PetaScreen()));
    await tester.pumpAndSettle();

    final actionRect = tester.getRect(
      find.byKey(const ValueKey('peta-adventure-action')),
    );
    final activeArtworkRect = tester.getRect(
      find.byKey(const ValueKey('peta-pulau-2-artwork')),
    );
    expect(
      find.byKey(const ValueKey('peta-adventure-guide')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('peta-go-2')), findsOneWidget);
    expect(actionRect.overlaps(activeArtworkRect), isTrue);
    expect(
      actionRect.bottom,
      closeTo(activeArtworkRect.top + activeArtworkRect.height * 0.70, 0.001),
    );
    for (final island in StorageService.activeIslandIds) {
      if (island == 2) continue;
      final artworkRect = tester.getRect(
        find.byKey(ValueKey('peta-pulau-$island-artwork')),
      );
      expect(
        actionRect.overlaps(artworkRect),
        isFalse,
        reason: 'Zaid and GO should only overlay active island 2',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('palace Zaid and GO are contained within the largest island',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      for (final island
          in StorageService.activeIslandIds.where((island) => island != 6))
        ProgressionFSM.islandKey(island): LevelState.completed.name,
      ProgressionFSM.islandKey(6): LevelState.unlocked.name,
    });

    await tester.pumpWidget(const MaterialApp(home: PetaScreen()));
    await tester.pumpAndSettle();

    final actionRect = tester.getRect(
      find.byKey(const ValueKey('peta-adventure-action')),
    );
    final artworkRect = tester.getRect(
      find.byKey(const ValueKey('peta-pulau-6-artwork')),
    );
    expect(find.byKey(const ValueKey('peta-go-6')), findsOneWidget);
    expect(actionRect.overlaps(artworkRect), isTrue);
    expect(artworkRect.contains(actionRect.topLeft), isTrue);
    expect(artworkRect.contains(actionRect.bottomRight), isTrue);
    expect(
      actionRect.bottom,
      closeTo(artworkRect.top + artworkRect.height * 0.70, 0.001),
    );
    expect(actionRect.center.dx, closeTo(artworkRect.center.dx, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('map GO button opens the active adventure island',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(960, 540);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            SystemChannels.platform, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: PetaScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('peta-go-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final adventure =
        tester.widget<AdventureScreen>(find.byType(AdventureScreen));
    expect(adventure.pulauId, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('choosing an unlocked map island opens AdventureScreen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(960, 540);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            SystemChannels.platform, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: PetaScreen()));
    await tester.pumpAndSettle();

    final island = find.text('Pulau 1: Pondasi Islam');
    final islandTap = tester.widget<GestureDetector>(
      find
          .ancestor(
            of: island,
            matching: find.byWidgetPredicate(
              (widget) => widget is GestureDetector && widget.onTap != null,
            ),
          )
          .first,
    );
    expect(islandTap.onTap, isNotNull);
    islandTap.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AdventureScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
