import 'dart:ui' as ui;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
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

Future<void> _pumpQuiz(
  WidgetTester tester, {
  required int nyawa,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdventureQuizDialog(
          pulauId: 1,
          namaPulau: 'Pondasi Islam',
          initialNyawa: nyawa,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<QalbuKidsAdventureGame> _pumpAdventureGame(
  WidgetTester tester, {
  void Function()? onGateTriggered,
  void Function()? onGateOpened,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(960, 540);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final game = QalbuKidsAdventureGame(
    onGateTriggered: onGateTriggered ?? () {},
    onGateOpened: onGateOpened,
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

    test('canceling a quiz returns the gate to locked', () {
      final fsm = AdventureFSM()..beginQuiz();
      fsm.cancelQuiz();
      expect(fsm.gateState, GateState.locked);
      expect(fsm.playerState, PlayerState.idle);
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
    for (var i = 0; i < 80 && triggers == 0; i++) {
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
    expect(game.player.position.y, game.player.groundY);
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
        closeTo(groundY + QalbuKidsAdventureGame.gateGroundOffset, 0.001),
      );
      final gateLeft = game.gate.position.x - game.gate.size.x / 2;
      final guardianRight = game.guardian.position.x + game.guardian.size.x / 2;
      expect(
        guardianRight + QalbuKidsAdventureGame.guardianGateGap,
        closeTo(gateLeft, 0.001),
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
      expect(footLift, 0);
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
      final gateLeft = game.gate.position.x - game.gate.size.x / 2;
      final guardianRight = game.guardian.position.x + game.guardian.size.x / 2;

      expect(game.player.position.x, lessThan(game.guardian.position.x));
      expect(game.guardian.position.x, lessThan(game.gate.position.x));
      expect(guardianRight, lessThan(gateLeft));
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

  test('passing the adventure exam unlocks the badge and next island',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    await unlockAdventureIslandProgress(
      storage: storage,
      pulauId: 1,
      skor: 60,
      nyawa: 2,
    );

    final states = await storage.getFsmStates();
    expect(states[ProgressionFSM.islandKey(1)], LevelState.completed);
    expect(states[ProgressionFSM.badgeKey(1)], LevelState.unlocked);
    expect(states[ProgressionFSM.islandKey(2)], LevelState.unlocked);
    expect(states[ProgressionFSM.stageKey(2, 1)], LevelState.unlocked);
    expect(states[ProgressionFSM.badgeKey(2)], LevelState.locked);
    expect((await storage.getLencana()).first, isTrue);
  });

  test('failing the adventure exam does not unlock progression', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    await unlockAdventureIslandProgress(
      storage: storage,
      pulauId: 1,
      skor: 59,
      nyawa: 5,
    );

    final states = await storage.getFsmStates();
    expect(states[ProgressionFSM.islandKey(1)], LevelState.unlocked);
    expect(states[ProgressionFSM.badgeKey(1)], LevelState.locked);
    expect(states[ProgressionFSM.islandKey(2)], LevelState.locked);
    expect((await storage.getLencana()).first, isFalse);
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

  testWidgets('answering every adventure question correctly passes the exam',
      (tester) async {
    SharedPreferences.setMockInitialValues({StorageService.keyNyawa: 5});
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
                  builder: (_) => const AdventureQuizDialog(
                    pulauId: 1,
                    namaPulau: 'Pondasi Islam',
                    initialNyawa: 5,
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

    for (var i = 0; i < 6; i++) {
      final correct = _optionForCurrentQuestion(tester, correct: true);
      await tester.tap(find.widgetWithText(ElevatedButton, correct));
      await tester.pumpAndSettle();
      await tester.tap(find.text(i == 5 ? 'Lihat Hasil' : 'Lanjut'));
      await tester.pumpAndSettle();
    }

    expect(result, isNotNull);
    expect(result!.passed, isTrue);
    expect(result!.skor, 100);
    expect(result!.nyawa, 11);
    expect(await storage.getNyawa(), 11);
  });

  testWidgets('tapping an unlocked map island opens AdventureScreen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
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
    await tester.ensureVisible(island);
    await tester.pumpAndSettle();
    await tester.tap(island);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AdventureScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
