import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/painting.dart' show Alignment, ImageRepeat;

import '../core/fsm/adventure_fsm.dart';

class QalbuKidsAdventureGame extends FlameGame {
  static const double worldWidth = 3000;
  static const double playerSpeed = 190;
  static const double cameraFocusRatio = 0.25;
  static const double cameraDamping = 12;
  static const double groundHeightRatio = 0.24;
  static const double surfaceDepthRatio = 0.68;
  static const double surfaceYRatio = 1 - groundHeightRatio * surfaceDepthRatio;
  // Kept as a compatibility alias for existing adventure callers.
  static const double groundYRatio = surfaceYRatio;
  static const double playerHeightRatio = 0.38;
  static const double guardianHeightRatio = 0.44;
  static const double gateHeightRatio = 0.64;
  static const double playerStartX = 130;
  static const double gateX = worldWidth - 260;
  static const double gateGroundOffset = 4;
  static const double actorGroundOffset = 0;
  static const double guardianCollisionDistance = 45;
  static const double roadHeightRatio = groundHeightRatio;
  static const double roadTileOverlap = 16;
  static const double parallaxSpeed = 24;
  static const double parallaxDamping = 8;
  static const double walkStepTime = 0.18;
  static const double walkBobFrequency = 10;
  static const double walkBobAmplitudeRatio = 0.006;
  static const double jumpVelocity = -520.0;
  static const double treasureChestMinSpacing = 300;
  static const List<double> treasureChestSlots = [
    450,
    850,
    1250,
    1650,
    2050,
    2350,
  ];
  static const double floatingChestHeightRatio = 0.30;
  static const double lowCoinHeightRatio = 0.14;
  static const double jumpArcStartHeightRatio = 0.22;
  static const double jumpArcPeakHeightRatio = 0.38;
  static const int obstacleCount = 3;
  static const double obstacleStartClearance = 260;
  static const double obstacleGuardianClearance = 150;
  static const double obstacleChestClearance = 90;
  static const double obstaclePatrolMargin = 32;
  static const double obstacleMinSpacing = 180;
  static const double obstacleFallbackMinSpacing = 130;
  static const double obstacleJumpGraceDuration = 0.12;
  static const double obstacleShakeDuration = 0.34;
  static const double obstacleShakeAmplitude = 4.5;
  static const double playerBodyWidthRatio = 0.38;
  static const double playerBodyHeightRatio = 0.50;
  static const int coinPatternCount = 4;
  static const int coinCount = 16;
  static const double skySeamBlendRatio = 0.10;
  static const String skyAsset = 'bg_langit_masjid.png';
  static const String skyAssetFallback = 'bg_langit_masjid.jpeg';
  static const String roadAsset = 'ground_jalan.png';

  static const int playerFrameCount = 4;
  static const double playerContentLeft = 12;
  static const double playerContentTop = 65;
  static const double playerContentWidth = 129;
  static const double playerContentHeight = 225;
  static const double guardianContentLeft = 65;
  static const double guardianContentTop = 90;
  static const double guardianContentWidth = 217;
  static const double guardianContentHeight = 498;
  static const double gateContentLeft = 202;
  static const double gateContentTop = 27;
  static const double gateContentWidth = 304;
  static const double gateContentHeight = 307;
  static const double roadContentTop = 146;
  static const double roadContentWidth = 677;
  static const double roadContentHeight = 149;

  // Kept for compatibility with existing adventure visual tests.
  static const int backgroundTileCount = 6;
  static const double backgroundTileOverlap = roadTileOverlap;

  final int pulauId;
  final void Function() onGateTriggered;
  final void Function()? onGateOpened;
  final void Function()? onCoinCollected;
  final void Function(TreasureChestComponent chest)? onTreasureChestTriggered;
  final void Function()? onObstacleHit;
  final bool obstaclesEnabled;
  final List<List<Map<String, dynamic>>> treasureQuestionGroups;
  final AdventureFSM fsm = AdventureFSM();

  double velocityY = 0.0;
  double gravity = 1150.0;
  bool isOnGround = true;

  bool _moveLeft = false;
  bool _moveRight = false;
  bool _loaded = false;
  bool _wasTouchingGuardian = false;
  double _walkClock = 0;
  double _cameraX = 0;
  double _parallaxVelocityX = 0;
  int _collectedCoins = 0;
  TreasureChestComponent? _activeTreasureChest;
  final List<ObstacleComponent> _obstacles = [];
  double _jumpGraceRemaining = 0;
  double _shakeRemaining = 0;

  late ParallaxComponent _skyParallax;
  late AdventureBackdropWash _backdropWash;
  ui.Image? _seamlessSkyImage;
  late Sprite _openGateSprite;
  late Sprite _roadSprite;
  late double _playerAspectRatio;
  late double _gateAspectRatio;
  late double _guardianAspectRatio;
  late AdventurePlayer _player;
  late AdventureGate _gate;
  late AdventureGuardian _guardian;
  final List<AdventureBackgroundTile> _backgroundTiles = [];
  final List<CoinComponent> _coins = [];
  final List<TreasureChestComponent> _treasureChests = [];

  // Four patterns: two low road rows and two parabolic jump arcs.
  static const List<({double x, double heightRatio})> _coinLayout = [
    (x: 230, heightRatio: lowCoinHeightRatio),
    (x: 280, heightRatio: lowCoinHeightRatio),
    (x: 330, heightRatio: lowCoinHeightRatio),
    (x: 550, heightRatio: jumpArcStartHeightRatio),
    (x: 600, heightRatio: 0.30),
    (x: 650, heightRatio: jumpArcPeakHeightRatio),
    (x: 700, heightRatio: 0.30),
    (x: 750, heightRatio: jumpArcStartHeightRatio),
    (x: 950, heightRatio: lowCoinHeightRatio),
    (x: 1000, heightRatio: lowCoinHeightRatio),
    (x: 1050, heightRatio: lowCoinHeightRatio),
    (x: 1350, heightRatio: jumpArcStartHeightRatio),
    (x: 1400, heightRatio: 0.30),
    (x: 1450, heightRatio: jumpArcPeakHeightRatio),
    (x: 1500, heightRatio: 0.30),
    (x: 1550, heightRatio: jumpArcStartHeightRatio),
  ];

  QalbuKidsAdventureGame({
    this.pulauId = 1,
    required this.onGateTriggered,
    this.onGateOpened,
    this.onCoinCollected,
    this.onTreasureChestTriggered,
    this.onObstacleHit,
    this.obstaclesEnabled = false,
    this.treasureQuestionGroups = const [],
  }) : super(camera: CameraComponent());

  AdventurePlayer get player => _player;
  AdventureGate get gate => _gate;
  AdventureGuardian get guardian => _guardian;
  ParallaxComponent get skyParallax => _skyParallax;
  AdventureBackdropWash get backdropWash => _backdropWash;
  Iterable<AdventureBackgroundTile> get backgroundTiles => _backgroundTiles;
  Iterable<CoinComponent> get coins => _coins;
  Iterable<TreasureChestComponent> get treasureChests => _treasureChests;
  Iterable<ObstacleComponent> get obstacles => _obstacles;
  TreasureChestComponent? get activeTreasureChest => _activeTreasureChest;
  bool get isShaking => _shakeRemaining > 0;
  int get collectedCoins => _collectedCoins;
  Iterable<AdventureCloud> get clouds => const [];
  int get cloudCount => 0;
  double get cameraBoundsWidth => worldWidth;

  String get selectedSkyAsset {
    if (pulauId == 2) return 'bg_pulau_2.png';
    if (pulauId == 3) return 'bg_pulau_3.png';
    if (pulauId == 4) return 'bg_pulau_4.png';
    return skyAsset;
  }

  String get selectedSkyAssetFallback {
    if (pulauId == 2) return 'bg_pulau_2.jpeg';
    if (pulauId == 3) return 'bg_pulau_3.jpeg';
    if (pulauId == 4) return 'bg_pulau_4.jpeg';
    return skyAssetFallback;
  }

  String get selectedRoadAsset {
    if (pulauId == 2) return 'ground_pulau_2.png';
    if (pulauId == 3) return 'ground_pulau_3.png';
    if (pulauId == 4) return 'ground_pulau_4.png';
    return roadAsset;
  }

  double get _screenHeight => size.y > 0 ? size.y : 540;
  double get groundHeight => _screenHeight * groundHeightRatio;
  double get surfaceY => _screenHeight - (groundHeight * surfaceDepthRatio);
  double get groundY => surfaceY;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final skyPath = await _resolveSkyAssetPath();
    final sky = await Parallax.load(
      [ParallaxImageData(skyPath)],
      repeat: ImageRepeat.repeatX,
      fill: LayerFill.height,
      filterQuality: ui.FilterQuality.medium,
    );
    final skyRenderer = sky.layers.single.parallaxRenderer;
    _seamlessSkyImage = await _createSeamlessSkyImage(skyRenderer.image);
    sky.layers[0] = AdventureSkyParallaxLayer(
      ParallaxImage(
        _seamlessSkyImage!,
        repeat: ImageRepeat.repeatX,
        alignment: Alignment.bottomLeft,
        fill: LayerFill.height,
        filterQuality: ui.FilterQuality.medium,
      ),
      velocityMultiplier: Vector2(0.25, 0),
    );
    _skyParallax = ParallaxComponent(parallax: sky, priority: 0);
    _backdropWash = AdventureBackdropWash();
    camera.backdrop = Component()..addAll([_skyParallax, _backdropWash]);

    final playerSheet = await Flame.images.load('zaid_spritesheet.png');
    final closedGate = await Flame.images.load('gerbang_tertutup.png');
    final openGate = await Flame.images.load('gerbang_terbuka.png');
    final guardian = await Flame.images.load('ustadz_penjaga.png');
    final roadPath = await _resolveRoadAssetPath();
    final road = await Flame.images.load(roadPath);

    _openGateSprite = _croppedSprite(
      openGate,
      const ui.Rect.fromLTWH(
        gateContentLeft,
        gateContentTop,
        gateContentWidth,
        gateContentHeight,
      ),
    );
    _roadSprite = _croppedSprite(
      road,
      const ui.Rect.fromLTWH(
        0,
        roadContentTop,
        roadContentWidth,
        roadContentHeight,
      ),
    );
    _gateAspectRatio = gateContentWidth / gateContentHeight;
    _guardianAspectRatio = guardianContentWidth / guardianContentHeight;
    _playerAspectRatio = playerContentWidth / playerContentHeight;

    final frameWidth = playerSheet.width / playerFrameCount;
    final playerFrames = List.generate(playerFrameCount, (index) {
      return _croppedSprite(
        playerSheet,
        ui.Rect.fromLTWH(
          index * frameWidth + playerContentLeft,
          playerContentTop,
          playerContentWidth,
          playerContentHeight,
        ),
      );
    });
    final idleAnimation = SpriteAnimation.spriteList(
      [playerFrames.first],
      stepTime: walkStepTime,
      loop: false,
    );
    final walkAnimation = SpriteAnimation.spriteList(
      playerFrames,
      stepTime: walkStepTime,
      loop: true,
    );

    _gate = AdventureGate(
      sprite: _croppedSprite(
        closedGate,
        const ui.Rect.fromLTWH(
          gateContentLeft,
          gateContentTop,
          gateContentWidth,
          gateContentHeight,
        ),
      ),
      position: Vector2(gateX, surfaceY + gateGroundOffset),
    );
    _player = AdventurePlayer(
      idleAnimation: idleAnimation,
      walkAnimation: walkAnimation,
      position: Vector2(playerStartX, surfaceY),
      groundY: surfaceY,
    );
    _guardian = AdventureGuardian(
      sprite: _croppedSprite(
        guardian,
        const ui.Rect.fromLTWH(
          guardianContentLeft,
          guardianContentTop,
          guardianContentWidth,
          guardianContentHeight,
        ),
      ),
      position: Vector2(gateX, surfaceY),
    );

    world.add(_gate);
    world.add(_guardian);
    world.add(_player);
    _spawnCoins();

    camera.viewfinder.anchor = Anchor.topLeft;
    _layoutScene();
    _spawnTreasureChests();
    _layoutTreasureChests();
    _spawnObstacles();
    _layoutObstacles();
    _loaded = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_loaded) _layoutScene();
  }

  @override
  void onRemove() {
    _seamlessSkyImage?.dispose();
    _seamlessSkyImage = null;
    super.onRemove();
  }

  void setMoveLeft(bool value) {
    _moveLeft = value;
    if (!value && !_moveRight) fsm.updateMovement(false);
  }

  void setMoveRight(bool value) {
    _moveRight = value;
    if (!value && !_moveLeft) fsm.updateMovement(false);
  }

  void stopMoving() {
    _moveLeft = false;
    _moveRight = false;
    fsm.updateMovement(false);
    if (_loaded) _player.setMovementState(fsm.playerState);
  }

  void jump() {
    if (!_loaded ||
        !isOnGround ||
        _activeTreasureChest != null ||
        fsm.playerState == PlayerState.interact) {
      return;
    }
    velocityY = jumpVelocity;
    isOnGround = false;
    _jumpGraceRemaining = obstacleJumpGraceDuration;
  }

  void _landPlayer() {
    velocityY = 0;
    isOnGround = true;
    _jumpGraceRemaining = 0;
    _player.groundY = surfaceY;
    _player.position.y = surfaceY;
    _player.setWalkBob(0);
  }

  void completeQuiz(int skor, {int? jumlahBenar}) {
    final wasQuizActive = fsm.gateState == GateState.quizActive;
    final opened = fsm.finishQuiz(skor: skor, jumlahBenar: jumlahBenar);
    if (opened) {
      _gate.sprite = _openGateSprite;
      _landPlayer();
    } else if (wasQuizActive) {
      _resetPlayerToStart();
    }
    _player.setMovementState(fsm.playerState);
    if (opened) onGateOpened?.call();
  }

  void _resetPlayerToStart() {
    stopMoving();
    _player.position.setValues(playerStartX, _player.groundY);
    velocityY = 0;
    isOnGround = true;
    _jumpGraceRemaining = 0;
    _player.faceDirection(1);
    _player.setWalkBob(0);
    _walkClock = 0;
    _parallaxVelocityX = 0;
    _shakeRemaining = 0;
    _skyParallax.parallax?.baseVelocity.setValues(0, 0);
    _wasTouchingGuardian = false;
    _updateCamera();
  }

  void cancelQuiz() {
    stopMoving();
    fsm.cancelQuiz();
    _landPlayer();
    _player.setMovementState(fsm.playerState);
  }

  void completeTreasureChest(TreasureChestComponent chest) {
    if (!identical(_activeTreasureChest, chest)) return;
    chest.open();
    _activeTreasureChest = null;
    stopMoving();
    _player.setMovementState(PlayerState.idle);
  }

  void cancelTreasureChest(TreasureChestComponent chest) {
    if (!identical(_activeTreasureChest, chest)) return;
    _activeTreasureChest = null;
    stopMoving();
    _player.setMovementState(PlayerState.idle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_loaded) return;
    if (_shakeRemaining > 0) {
      _shakeRemaining = math.max(0.0, _shakeRemaining - dt);
    }
    if (_jumpGraceRemaining > 0) {
      _jumpGraceRemaining = math.max(0.0, _jumpGraceRemaining - dt);
    }

    final moveDirection = (_moveRight ? 1.0 : 0.0) - (_moveLeft ? 1.0 : 0.0);
    final targetParallaxVelocity = moveDirection * parallaxSpeed;
    final parallaxBlend = dt > 0 ? 1 - math.exp(-parallaxDamping * dt) : 1;
    _parallaxVelocityX +=
        (targetParallaxVelocity - _parallaxVelocityX) * parallaxBlend;
    _skyParallax.parallax?.baseVelocity.setValues(_parallaxVelocityX, 0);

    if (fsm.gateState == GateState.quizActive || _activeTreasureChest != null) {
      stopMoving();
      _player.setMovementState(PlayerState.interact);
      _updateCamera(dt);
      return;
    }

    final moving = moveDirection != 0 && fsm.canMove;
    fsm.updateMovement(moving);
    _player.setMovementState(fsm.playerState);

    if (moving) {
      _walkClock += dt;
      _player.position.x =
          (_player.position.x + moveDirection * playerSpeed * dt)
              .clamp(48, worldWidth - 48)
              .toDouble();
      _player.faceDirection(moveDirection.toInt());
    } else {
      _walkClock = 0;
    }
    _player.setWalkBob(
      moving && isOnGround
          ? math.sin(_walkClock * walkBobFrequency).abs() *
              walkBobAmplitudeRatio
          : 0,
    );

    _updateJumpPhysics(dt);
    _updateCamera(dt);
    _collectTouchedCoins();
    _triggerTouchedTreasureChest();
    if (_activeTreasureChest != null) return;
    if (_checkObstacleCollision()) return;

    final touchesGuardian = _touchesGuardian();
    if (!touchesGuardian) _wasTouchingGuardian = false;
    if (fsm.gateState == GateState.locked &&
        touchesGuardian &&
        !_wasTouchingGuardian) {
      _wasTouchingGuardian = true;
      stopMoving();
      if (fsm.beginQuiz()) {
        _player.setMovementState(PlayerState.interact);
        onGateTriggered();
      }
    }
  }

  void _updateJumpPhysics(double dt) {
    if (isOnGround) {
      _player.position.y = surfaceY;
      velocityY = 0;
      return;
    }

    velocityY += gravity * dt;
    _player.position.y += velocityY * dt;
    if (_player.position.y >= surfaceY) {
      _player.position.y = surfaceY;
      velocityY = 0;
      isOnGround = true;
      _jumpGraceRemaining = 0;
      _player.setWalkBob(0);
    }
  }

  void _spawnCoins() {
    final diameter = (_screenHeight * 0.075).clamp(30.0, 42.0).toDouble();
    for (var i = 0; i < _coinLayout.length; i++) {
      final spawn = _coinLayout[i];
      final heightAboveGround = _screenHeight * spawn.heightRatio;
      final coin = CoinComponent(
        basePosition: Vector2(spawn.x, surfaceY - heightAboveGround),
        heightRatio: spawn.heightRatio,
        heightAboveGround: heightAboveGround,
        phase: i * 0.83,
        size: Vector2.all(diameter),
      );
      _coins.add(coin);
      world.add(coin);
    }
  }

  void _layoutCoins() {
    final diameter = (_screenHeight * 0.075).clamp(30.0, 42.0).toDouble();
    for (var i = 0; i < _coins.length; i++) {
      final coin = _coins[i];
      final spawn = _coinLayout[i];
      coin.size.setAll(diameter);
      coin.heightAboveGround = _screenHeight * spawn.heightRatio;
      coin.basePosition.y = surfaceY - coin.heightAboveGround;
      coin.position.y = coin.basePosition.y;
      coin.scale.setAll(1);
    }
  }

  double _chestX(int index, int chestCount) {
    if (chestCount <= 1) return treasureChestSlots[2];

    final lastSlot = treasureChestSlots.length - 1;
    final List<int> indices;
    switch (chestCount) {
      case 2:
        indices = [0, lastSlot];
        break;
      case 3:
        indices = [0, 2, lastSlot];
        break;
      case 4:
        indices = [0, 1, 3, lastSlot];
        break;
      default:
        if (chestCount <= treasureChestSlots.length) {
          return treasureChestSlots[index];
        }
        final progress = index / (chestCount - 1);
        return treasureChestSlots.first +
            (treasureChestSlots.last - treasureChestSlots.first) * progress;
    }
    return treasureChestSlots[indices[index]];
  }

  void _spawnTreasureChests() {
    final chestCount = treasureQuestionGroups.length;
    if (chestCount == 0) return;

    for (var i = 0; i < chestCount; i++) {
      final isFloating = chestCount > 1 && i.isOdd;
      final heightRatio = isFloating ? floatingChestHeightRatio : 0.0;
      final heightAboveGround = _screenHeight * heightRatio;
      final chest = TreasureChestComponent(
        questions: treasureQuestionGroups[i],
        basePosition: Vector2(
          _chestX(i, chestCount),
          surfaceY - heightAboveGround,
        ),
        heightRatio: heightRatio,
        heightAboveGround: heightAboveGround,
        size: Vector2.all(1),
        phase: i * 0.83,
      );
      _treasureChests.add(chest);
      world.add(chest);
    }
  }

  void _layoutTreasureChests() {
    final height = (_screenHeight * 0.15).clamp(58.0, 92.0).toDouble();
    for (final chest in _treasureChests) {
      chest.size.setValues(height * 1.24, height);
      chest.heightAboveGround = _screenHeight * chest.heightRatio;
      chest.basePosition.y = surfaceY - chest.heightAboveGround;
      chest.position.setFrom(chest.basePosition);
    }
  }

  void _spawnObstacles() {
    if (!obstaclesEnabled) return;

    final random = math.Random();
    final minX = playerStartX + obstacleStartClearance;
    final maxX =
        _guardian.position.x - _guardian.size.x / 2 - obstacleGuardianClearance;
    if (maxX <= minX) return;

    final blockedIntervals = <({double start, double end})>[];
    for (final chest in _treasureChests) {
      if (chest.isFloating) continue;
      blockedIntervals.add((
        start: chest.position.x - obstacleChestClearance - obstaclePatrolMargin,
        end: chest.position.x + obstacleChestClearance + obstaclePatrolMargin,
      ));
    }

    final candidates = <double>[];
    for (var x = minX; x <= maxX; x += 10) {
      final blocked = blockedIntervals.any(
        (interval) => x >= interval.start && x <= interval.end,
      );
      if (!blocked) candidates.add(x);
    }
    if (candidates.length < obstacleCount) return;

    List<double> selectObstacles(double spacing) {
      List<double>? bestPath;
      var bestBalance = -1.0;
      for (var start = 0; start < candidates.length; start++) {
        final path = <double>[candidates[start]];
        for (var i = start + 1;
            i < candidates.length && path.length < obstacleCount;
            i++) {
          if (candidates[i] - path.last >= spacing) {
            path.add(candidates[i]);
          }
        }
        if (path.length < obstacleCount) continue;

        final balance = math.min(path.first - minX, maxX - path.last);
        if (bestPath == null ||
            path.length > bestPath.length ||
            (path.length == bestPath.length && balance > bestBalance)) {
          bestPath = path;
          bestBalance = balance;
        }
      }
      return bestPath ?? const [];
    }

    var selected = <double>[];
    for (var spacing = obstacleMinSpacing;
        spacing >= obstacleFallbackMinSpacing;
        spacing -= 10) {
      selected = selectObstacles(spacing);
      if (selected.length >= obstacleCount) break;
    }
    if (selected.length < obstacleCount) return;

    const obstacleKinds = [
      ObstacleKind.rollingLantern,
      ObstacleKind.thornyBush,
      ObstacleKind.gardenRock,
    ];
    final kinds = List<ObstacleKind>.generate(
      selected.length,
      (index) => obstacleKinds[index % obstacleKinds.length],
    )..shuffle(random);

    for (var i = 0; i < selected.length; i++) {
      final kind = kinds[i];
      final moving = kind == ObstacleKind.rollingLantern;
      final obstacle = ObstacleComponent(
        kind: kind,
        basePosition: Vector2(selected[i], surfaceY),
        size: Vector2.all(1),
        patrolRange: moving ? 26 + random.nextDouble() * 4 : 0,
        speed: 0.75 + random.nextDouble() * 0.45,
        phase: random.nextDouble() * math.pi * 2,
      );
      _obstacles.add(obstacle);
      world.add(obstacle);
    }
  }

  void _layoutObstacles() {
    for (final obstacle in _obstacles) {
      final heightRatio =
          obstacle.kind == ObstacleKind.thornyBush ? 0.085 : 0.075;
      final height = (_screenHeight * heightRatio).clamp(30.0, 46.0).toDouble();
      final widthRatio = obstacle.kind == ObstacleKind.gardenRock ? 1.28 : 1.12;
      obstacle.size.setValues(height * widthRatio, height);
      obstacle.basePosition.y = surfaceY;
      obstacle.position.y = surfaceY;
    }
  }

  bool _checkObstacleCollision() {
    if (!obstaclesEnabled ||
        fsm.gateState != GateState.locked ||
        _jumpGraceRemaining > 0) {
      return false;
    }
    final playerBounds = _playerBodyBounds();
    for (final obstacle in _obstacles) {
      if (!playerBounds.overlaps(obstacle.hitBounds)) continue;
      final obstacleTop = obstacle.hitBounds.top;
      if (_player.position.y <= obstacleTop + 8) continue;

      _resetPlayerToStart();
      _shakeRemaining = obstacleShakeDuration;
      _updateCamera();
      onObstacleHit?.call();
      return true;
    }
    return false;
  }

  ui.Rect _playerBodyBounds() {
    final width = _player.size.x * playerBodyWidthRatio;
    final height =
        _player.size.y * playerBodyHeightRatio * _player.scale.y.abs();
    final bottom = _player.position.y - _player.size.y * 0.02;
    return ui.Rect.fromLTWH(
      _player.position.x - width / 2,
      bottom - height,
      width,
      height,
    );
  }

  ui.Rect _treasureChestBounds(TreasureChestComponent chest) {
    if (chest.isFloating) {
      return ui.Rect.fromCenter(
        center: ui.Offset(
          chest.position.x,
          chest.position.y - chest.size.y * 0.5,
        ),
        width: chest.size.x * 0.72,
        height: chest.size.y * 0.52,
      );
    }
    return ui.Rect.fromLTWH(
      chest.position.x - chest.size.x * 0.42,
      chest.position.y - chest.size.y * 0.94,
      chest.size.x * 0.84,
      chest.size.y * 0.94,
    );
  }

  void _triggerTouchedTreasureChest() {
    if (_activeTreasureChest != null ||
        fsm.gateState != GateState.locked ||
        onTreasureChestTriggered == null) {
      return;
    }
    final playerBounds = _playerBodyBounds();
    for (final chest in _treasureChests) {
      if (chest.state != TreasureChestState.closed) continue;
      if (!playerBounds.overlaps(_treasureChestBounds(chest))) continue;

      _activeTreasureChest = chest;
      stopMoving();
      _player.setMovementState(PlayerState.interact);
      onTreasureChestTriggered!(chest);
      return;
    }
  }

  void _collectTouchedCoins() {
    final playerBounds = _playerBodyBounds();
    for (final coin in _coins) {
      if (coin.isCollected) continue;
      final radius = coin.size.x * 0.36;
      final coinBounds = ui.Rect.fromCircle(
        center: ui.Offset(coin.position.x, coin.position.y),
        radius: radius,
      );
      if (!playerBounds.overlaps(coinBounds)) continue;

      _collectedCoins++;
      coin.collect();
      onCoinCollected?.call();
    }
  }

  Future<String> _resolveSkyAssetPath() {
    return _resolveAssetPath(
      preferred: selectedSkyAsset,
      fallback: selectedSkyAssetFallback,
    );
  }

  Future<String> _resolveRoadAssetPath() {
    return _resolveAssetPath(
      preferred: selectedRoadAsset,
      fallback: roadAsset,
    );
  }

  Future<String> _resolveAssetPath({
    required String preferred,
    required String fallback,
  }) async {
    try {
      await Flame.bundle.load('${Flame.images.prefix}$preferred');
      return preferred;
    } catch (_) {
      if (fallback == preferred) rethrow;
      await Flame.bundle.load('${Flame.images.prefix}$fallback');
      return fallback;
    }
  }

  void _layoutScene() {
    final screenHeight = _screenHeight;
    final surfaceY = this.surfaceY;

    _player.groundY = surfaceY;
    velocityY = 0;
    isOnGround = true;
    _player.position.y = surfaceY;
    _player.resizeToHeight(
      screenHeight * playerHeightRatio,
      aspectRatio: _playerAspectRatio,
    );

    _gate.position.setValues(gateX, surfaceY + gateGroundOffset);
    _gate.resizeToHeight(
      screenHeight * gateHeightRatio,
      aspectRatio: _gateAspectRatio,
    );

    _guardian.resizeToHeight(
      screenHeight * guardianHeightRatio,
      aspectRatio: _guardianAspectRatio,
    );
    _guardian.position.setValues(
      _gate.position.x - (_gate.size.x * 0.38),
      surfaceY,
    );

    _layoutCoins();
    _layoutTreasureChests();
    _layoutObstacles();

    for (final tile in _backgroundTiles) {
      tile.removeFromParent();
    }
    _backgroundTiles.clear();

    final roadHeight = groundHeight;
    final roadAspectRatio = _roadSprite.srcSize.x / _roadSprite.srcSize.y;
    final tileWidth = roadHeight * roadAspectRatio;
    final tileStride = tileWidth - roadTileOverlap;
    final tileCount = ((worldWidth - roadTileOverlap) / tileStride).ceil();

    for (var i = 0; i < tileCount; i++) {
      final tile = AdventureBackgroundTile(
        tileIndex: i,
        sprite: _roadSprite,
        position: Vector2(i * tileStride, screenHeight),
        size: Vector2(tileWidth, roadHeight),
        anchor: Anchor.bottomLeft,
        scale: Vector2.all(1),
        priority: 5,
        seamBlendWidth: roadTileOverlap,
      );
      _backgroundTiles.add(tile);
      world.add(tile);
    }

    _updateCamera();
  }

  void _updateCamera([double dt = 0]) {
    final targetCamX = (_player.position.x - size.x * cameraFocusRatio)
        .clamp(0.0, worldWidth - size.x)
        .toDouble();
    if (dt > 0) {
      final blend = 1 - math.exp(-cameraDamping * dt);
      _cameraX += (targetCamX - _cameraX) * blend;
    } else {
      _cameraX = targetCamX;
    }
    final shakeRatio = _shakeRemaining / obstacleShakeDuration;
    final shakeX = shakeRatio > 0
        ? math.sin(_shakeRemaining * 92) * obstacleShakeAmplitude * shakeRatio
        : 0.0;
    final shakeY = shakeRatio > 0
        ? math.cos(_shakeRemaining * 74) *
            obstacleShakeAmplitude *
            0.55 *
            shakeRatio
        : 0.0;
    camera.viewfinder.position = Vector2(_cameraX + shakeX, shakeY);
  }

  bool _touchesGuardian() {
    return _player.position.x >=
        _guardian.position.x - guardianCollisionDistance;
  }
}

Sprite _croppedSprite(ui.Image image, ui.Rect source) {
  return Sprite(
    image,
    srcPosition: Vector2(source.left, source.top),
    srcSize: Vector2(source.width, source.height),
  );
}

Future<ui.Image> _createSeamlessSkyImage(ui.Image image) async {
  final blendWidth = (image.width * QalbuKidsAdventureGame.skySeamBlendRatio)
      .round()
      .clamp(1, image.width ~/ 2)
      .toInt();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
  final fullImage = ui.Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );
  final leftStrip = ui.Rect.fromLTWH(
    0,
    0,
    blendWidth.toDouble(),
    image.height.toDouble(),
  );
  final rightStrip = ui.Rect.fromLTWH(
    (image.width - blendWidth).toDouble(),
    0,
    blendWidth.toDouble(),
    image.height.toDouble(),
  );

  canvas.drawImageRect(image, fullImage, fullImage, paint);
  canvas.save();
  canvas.translate(blendWidth.toDouble(), 0);
  canvas.scale(-1, 1);
  canvas.drawImageRect(image, rightStrip, leftStrip, paint);
  canvas.restore();

  canvas.saveLayer(leftStrip, ui.Paint());
  canvas.drawImageRect(image, leftStrip, leftStrip, paint);
  final fade = ui.Paint()
    ..blendMode = ui.BlendMode.dstIn
    ..shader = ui.Gradient.linear(
      ui.Offset.zero,
      ui.Offset(blendWidth.toDouble(), 0),
      const [ui.Color(0x00000000), ui.Color(0xFF000000)],
    );
  canvas.drawRect(leftStrip, fade);
  canvas.restore();

  return recorder.endRecording().toImage(image.width, image.height);
}

class AdventurePlayer extends SpriteAnimationComponent {
  double groundY;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _walkAnimation;
  bool _facingRight = true;

  AdventurePlayer({
    required SpriteAnimation idleAnimation,
    required SpriteAnimation walkAnimation,
    required super.position,
    required this.groundY,
  })  : _idleAnimation = idleAnimation,
        _walkAnimation = walkAnimation,
        super(
          animation: idleAnimation,
          playing: false,
          size: Vector2.zero(),
          anchor: Anchor.bottomCenter,
          priority: 30,
        );

  void setMovementState(PlayerState state) {
    final walking = state == PlayerState.walk;
    animation = walking ? _walkAnimation : _idleAnimation;
    playing = walking;
  }

  void faceDirection(int direction) {
    final facingRight = direction >= 0;
    if (facingRight == _facingRight) return;
    flipHorizontallyAroundCenter();
    _facingRight = facingRight;
  }

  void setWalkBob(double amount) {
    scale.y = 1 - amount.clamp(0.0, 0.02).toDouble();
  }

  void resizeToHeight(double height, {required double aspectRatio}) {
    size.setValues(height * aspectRatio, height);
  }
}

enum TreasureChestState { closed, opened }

class TreasureChestComponent extends PositionComponent {
  final List<Map<String, dynamic>> questions;
  final double heightRatio;
  double heightAboveGround;
  final double phase;
  Vector2 basePosition;
  TreasureChestState _state = TreasureChestState.closed;
  double _clock = 0;

  TreasureChestComponent({
    required this.questions,
    required Vector2 basePosition,
    required this.heightRatio,
    required this.heightAboveGround,
    required this.phase,
    required super.size,
  })  : basePosition = basePosition.clone(),
        super(
          position: basePosition.clone(),
          anchor: Anchor.bottomCenter,
          priority: 15,
        );

  TreasureChestState get state => _state;
  bool get isOpened => _state == TreasureChestState.opened;
  bool get isFloating => heightRatio > 0;

  void open() {
    _state = TreasureChestState.opened;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
  }

  @override
  void render(ui.Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    final width = size.x;
    final height = size.y;
    final glow = (math.sin(_clock * 3.4 + phase) + 1) / 2;
    canvas.save();

    if (isFloating || isOpened) {
      canvas.drawCircle(
        ui.Offset(width / 2, height * 0.52),
        width * (0.48 + glow * 0.05),
        ui.Paint()
          ..color = const ui.Color(0xFFFFD54F)
              .withAlpha((isOpened ? 42 : 24) + (glow * 18).round()),
      );
    }
    if (!isFloating) {
      canvas.drawOval(
        ui.Rect.fromLTWH(
            width * 0.08, height * 0.91, width * 0.84, height * 0.12),
        ui.Paint()..color = const ui.Color(0x553B2A16),
      );
    }

    final bodyRect = ui.Rect.fromLTWH(
      width * 0.08,
      height * 0.43,
      width * 0.84,
      height * 0.48,
    );
    final woodPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, bodyRect.top),
        ui.Offset(0, bodyRect.bottom),
        const [ui.Color(0xFFB96F32), ui.Color(0xFF7A3E1D)],
      );
    final outline = ui.Paint()
      ..color = const ui.Color(0xFF4E2A17)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3;

    if (isOpened) {
      canvas.drawOval(
        ui.Rect.fromLTWH(
            width * 0.14, height * 0.34, width * 0.72, height * 0.18),
        ui.Paint()..color = const ui.Color(0xFF2E1B10),
      );
      for (var i = 0; i < 5; i++) {
        final coinX = width * (0.25 + i * 0.125);
        final coinY = height * (0.42 + (i.isEven ? 0.02 : 0));
        canvas.drawCircle(
          ui.Offset(coinX, coinY),
          height * 0.055,
          ui.Paint()..color = const ui.Color(0xFFFFD54F),
        );
      }
    }

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(bodyRect, ui.Radius.circular(height * 0.06)),
      woodPaint,
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(bodyRect, ui.Radius.circular(height * 0.06)),
      outline,
    );

    final lidPath = ui.Path()
      ..moveTo(width * 0.08, height * 0.45)
      ..quadraticBezierTo(
          width * 0.16, height * 0.08, width * 0.5, height * 0.08)
      ..quadraticBezierTo(
          width * 0.84, height * 0.08, width * 0.92, height * 0.45)
      ..close();
    if (isOpened) {
      canvas.save();
      canvas.translate(width * 0.10, height * 0.38);
      canvas.rotate(-0.28);
      canvas.translate(-width * 0.10, -height * 0.38);
      canvas.drawPath(lidPath, woodPaint);
      canvas.drawPath(lidPath, outline);
      canvas.restore();
    } else {
      canvas.drawPath(lidPath, woodPaint);
      canvas.drawPath(lidPath, outline);
    }

    final gold = ui.Paint()..color = const ui.Color(0xFFF7C948);
    final goldDark = ui.Paint()..color = const ui.Color(0xFFB67A16);
    for (final bandX in [0.25, 0.73]) {
      canvas.drawRect(
        ui.Rect.fromLTWH(
            width * bandX, height * 0.43, width * 0.075, height * 0.48),
        gold,
      );
      canvas.drawRect(
        ui.Rect.fromLTWH(
            width * bandX, height * 0.43, width * 0.075, height * 0.03),
        goldDark,
      );
    }
    canvas.drawRect(
      ui.Rect.fromLTWH(
          width * 0.08, height * 0.77, width * 0.84, height * 0.07),
      gold,
    );

    if (!isOpened) {
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(
              width * 0.41, height * 0.40, width * 0.18, height * 0.24),
          ui.Radius.circular(height * 0.035),
        ),
        gold,
      );
      canvas.drawCircle(
        ui.Offset(width * 0.5, height * 0.50),
        height * 0.035,
        ui.Paint()..color = const ui.Color(0xFF6B4712),
      );
    }

    _drawSparkle(
      canvas,
      ui.Offset(width * 0.84, height * 0.18 + glow * height * 0.04),
      height * (0.055 + glow * 0.015),
      _clock * 0.4,
      ui.Paint()..color = const ui.Color(0xFFFFF8D6),
    );
    canvas.restore();
  }
}

enum ObstacleKind { gardenRock, thornyBush, rollingLantern }

class ObstacleComponent extends PositionComponent {
  final ObstacleKind kind;
  final double patrolRange;
  final double speed;
  final double phase;
  Vector2 basePosition;
  double _clock = 0;
  double _roll = 0;

  ObstacleComponent({
    required this.kind,
    required Vector2 basePosition,
    required this.patrolRange,
    required this.speed,
    required this.phase,
    required super.size,
  })  : basePosition = basePosition.clone(),
        super(
          position: Vector2(
            basePosition.x + math.sin(phase) * patrolRange,
            basePosition.y,
          ),
          anchor: Anchor.bottomCenter,
          priority: 21,
        );

  bool get isMoving => kind == ObstacleKind.rollingLantern;

  ui.Rect get hitBounds => ui.Rect.fromLTWH(
        position.x - size.x * 0.32,
        position.y - size.y * 0.78,
        size.x * 0.64,
        size.y * 0.72,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
    if (!isMoving || patrolRange <= 0) return;

    final previousX = position.x;
    position.x =
        basePosition.x + math.sin(_clock * speed + phase) * patrolRange;
    _roll += (position.x - previousX) / math.max(size.x * 0.42, 1);
  }

  @override
  void render(ui.Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    canvas.save();
    if (!isMoving) {
      canvas.drawOval(
        ui.Rect.fromLTWH(
          size.x * 0.08,
          size.y * 0.86,
          size.x * 0.84,
          size.y * 0.16,
        ),
        ui.Paint()..color = const ui.Color(0x553B2A16),
      );
    }

    switch (kind) {
      case ObstacleKind.gardenRock:
        _renderGardenRock(canvas);
        break;
      case ObstacleKind.thornyBush:
        _renderThornyBush(canvas);
        break;
      case ObstacleKind.rollingLantern:
        _renderRollingLantern(canvas);
        break;
    }
    canvas.restore();
  }

  void _renderGardenRock(ui.Canvas canvas) {
    final width = size.x;
    final height = size.y;
    final rock = ui.Path()
      ..moveTo(width * 0.08, height * 0.84)
      ..quadraticBezierTo(
          width * 0.02, height * 0.58, width * 0.24, height * 0.42)
      ..quadraticBezierTo(
          width * 0.38, height * 0.12, width * 0.60, height * 0.18)
      ..quadraticBezierTo(
          width * 0.88, height * 0.24, width * 0.94, height * 0.62)
      ..quadraticBezierTo(
          width * 0.98, height * 0.86, width * 0.82, height * 0.90)
      ..close();
    canvas.drawPath(
      rock,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(width * 0.2, height * 0.16),
          ui.Offset(width * 0.8, height * 0.92),
          const [ui.Color(0xFFB8C2B4), ui.Color(0xFF778477)],
        ),
    );
    canvas.drawPath(
      rock,
      ui.Paint()
        ..color = const ui.Color(0xFF59665A)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawOval(
      ui.Rect.fromLTWH(
          width * 0.12, height * 0.72, width * 0.52, height * 0.18),
      ui.Paint()..color = const ui.Color(0xFF6F9B58),
    );
    canvas.drawCircle(
      ui.Offset(width * 0.36, height * 0.40),
      width * 0.055,
      ui.Paint()..color = const ui.Color(0xFFD7DFD2),
    );
    canvas.drawCircle(
      ui.Offset(width * 0.70, height * 0.57),
      width * 0.035,
      ui.Paint()..color = const ui.Color(0xFF657166),
    );
  }

  void _renderThornyBush(ui.Canvas canvas) {
    final width = size.x;
    final height = size.y;
    final leafPaint = ui.Paint()..color = const ui.Color(0xFF4F8F4B);
    final lightLeafPaint = ui.Paint()..color = const ui.Color(0xFF73B85D);
    for (final center in [
      ui.Offset(width * 0.28, height * 0.62),
      ui.Offset(width * 0.50, height * 0.48),
      ui.Offset(width * 0.72, height * 0.64),
    ]) {
      canvas.drawCircle(center, height * 0.30, leafPaint);
      canvas.drawCircle(
        center + ui.Offset(-width * 0.05, -height * 0.08),
        height * 0.18,
        lightLeafPaint,
      );
    }

    final thornPaint = ui.Paint()..color = const ui.Color(0xFFD8E68B);
    for (final x in [0.20, 0.40, 0.60, 0.80]) {
      final thorn = ui.Path()
        ..moveTo(width * x, height * 0.44)
        ..lineTo(width * (x + 0.045), height * 0.20)
        ..lineTo(width * (x + 0.09), height * 0.46)
        ..close();
      canvas.drawPath(thorn, thornPaint);
    }

    for (final flower in [
      ui.Offset(width * 0.30, height * 0.36),
      ui.Offset(width * 0.68, height * 0.40),
    ]) {
      canvas.drawCircle(flower, height * 0.065,
          ui.Paint()..color = const ui.Color(0xFFFFD1DC));
      canvas.drawCircle(flower, height * 0.025,
          ui.Paint()..color = const ui.Color(0xFFFFC857));
    }
  }

  void _renderRollingLantern(ui.Canvas canvas) {
    final width = size.x;
    final height = size.y;
    final center = ui.Offset(width / 2, height / 2);
    final radius = width * 0.40;
    final glow = (math.sin(_clock * 3 + phase) + 1) / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_roll);
    canvas.drawCircle(
      ui.Offset.zero,
      radius * (1.22 + glow * 0.08),
      ui.Paint()
        ..color =
            const ui.Color(0xFFFFD54F).withAlpha(28 + (glow * 22).round()),
    );
    canvas.drawCircle(
      ui.Offset.zero,
      radius + 2,
      ui.Paint()..color = const ui.Color(0xFF9A6416),
    );
    canvas.drawCircle(
      ui.Offset.zero,
      radius,
      ui.Paint()
        ..shader = ui.Gradient.radial(
          ui.Offset(-radius * 0.35, -radius * 0.40),
          radius * 1.35,
          const [
            ui.Color(0xFFFFF3B0),
            ui.Color(0xFFFFC857),
            ui.Color(0xFFE89B2E),
          ],
          const [0, 0.58, 1],
        ),
    );
    canvas.drawCircle(
      ui.Offset.zero,
      radius * 0.78,
      ui.Paint()
        ..color = const ui.Color(0xFFA86B1D)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final ribPaint = ui.Paint()
      ..color = const ui.Color(0xFFB77A24)
      ..strokeWidth = 2;
    canvas.drawLine(
      ui.Offset(-radius * 0.72, 0),
      ui.Offset(radius * 0.72, 0),
      ribPaint,
    );
    canvas.drawLine(
      ui.Offset(0, -radius * 0.72),
      ui.Offset(0, radius * 0.72),
      ribPaint,
    );
    canvas.drawPath(
      _starPath(radius * 0.34, radius * 0.15, 5),
      ui.Paint()..color = const ui.Color(0xFFFFF7D6),
    );
    canvas.restore();
  }
}

class CoinComponent extends PositionComponent {
  final double heightRatio;
  double heightAboveGround;
  final double phase;
  Vector2 basePosition;
  double _clock = 0;
  bool _collected = false;

  CoinComponent({
    required Vector2 basePosition,
    required this.heightRatio,
    required this.heightAboveGround,
    required this.phase,
    required super.size,
  })  : basePosition = basePosition.clone(),
        super(
          position: basePosition.clone(),
          anchor: Anchor.center,
          priority: 12,
        );

  bool get isCollected => _collected;

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    _clock += dt;
    position.y = basePosition.y + math.sin(_clock * 3.2 + phase) * 4;
    final pulse = 1 + math.sin(_clock * 4.5 + phase) * 0.045;
    scale.setAll(pulse);
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    parent?.add(
      CoinCollectionEffect(
        position: position.clone(),
        size: Vector2(size.x * 3, size.y * 3),
      ),
    );
    removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    final center = ui.Offset(size.x / 2, size.y / 2);
    final radius = size.x * 0.40;
    final shimmer = (math.sin(_clock * 5 + phase) + 1) / 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);

    canvas.drawCircle(
      ui.Offset.zero,
      radius * 1.32,
      ui.Paint()
        ..color =
            const ui.Color(0xFFFFD54F).withAlpha(35 + (shimmer * 35).round()),
    );
    canvas.drawCircle(
      ui.Offset.zero,
      radius + 2.5,
      ui.Paint()..color = const ui.Color(0xFFB86F00),
    );
    canvas.drawCircle(
      ui.Offset.zero,
      radius,
      ui.Paint()
        ..shader = ui.Gradient.radial(
          ui.Offset(-radius * 0.35, -radius * 0.40),
          radius * 1.30,
          const [
            ui.Color(0xFFFFF6B0),
            ui.Color(0xFFFFD54F),
            ui.Color(0xFFF2A900),
          ],
          const [0, 0.58, 1],
        ),
    );
    canvas.drawCircle(
      ui.Offset.zero,
      radius * 0.76,
      ui.Paint()
        ..color = const ui.Color(0xFFFFE98A)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawPath(
      _starPath(radius * 0.46, radius * 0.21, 5),
      ui.Paint()..color = const ui.Color(0xFFC47B00),
    );
    canvas.drawPath(
      _starPath(radius * 0.46, radius * 0.21, 5),
      ui.Paint()
        ..color = const ui.Color(0xFFFFE59A)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawArc(
      ui.Rect.fromCircle(center: ui.Offset.zero, radius: radius * 0.84),
      -math.pi * 0.88,
      math.pi * 0.34,
      false,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFDE0)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = ui.StrokeCap.round,
    );
    _drawSparkle(
      canvas,
      ui.Offset(radius * 0.62, -radius * 0.66),
      size.x * (0.075 + shimmer * 0.025),
      shimmer * 0.5,
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    _drawSparkle(
      canvas,
      ui.Offset(-radius * 0.62, radius * 0.48),
      size.x * (0.040 + shimmer * 0.015),
      -shimmer * 0.4,
      ui.Paint()..color = const ui.Color(0xFFFFF8D6),
    );
    canvas.restore();
  }
}

class CoinCollectionEffect extends PositionComponent {
  static const double duration = 0.45;
  final List<_CoinSpark> _sparks = [];
  double _elapsed = 0;

  CoinCollectionEffect({
    required super.position,
    required super.size,
  }) : super(anchor: Anchor.center, priority: 35) {
    for (var i = 0; i < 10; i++) {
      _sparks.add(
        _CoinSpark(
          angle: math.pi * 2 * i / 10,
          distance: size.x * (0.34 + (i % 3) * 0.035),
          radius: size.x * (i.isEven ? 0.052 : 0.034),
          delay: i * 0.006,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    final center = ui.Offset(size.x / 2, size.y / 2);
    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    final opacity = 1 - progress;
    canvas.save();
    canvas.translate(center.dx, center.dy);

    canvas.drawCircle(
      ui.Offset.zero,
      size.x * (0.10 + progress * 0.24),
      ui.Paint()
        ..color = const ui.Color(0xFFFFE082).withAlpha((180 * opacity).round())
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.5 * opacity + 0.5,
    );
    for (final spark in _sparks) {
      final localProgress =
          ((progress - spark.delay) / (1 - spark.delay)).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;
      final travel = 1 - math.pow(1 - localProgress, 2).toDouble();
      final sparkOpacity = opacity * (1 - localProgress * 0.35);
      _drawSparkle(
        canvas,
        ui.Offset(
          math.cos(spark.angle) * spark.distance * travel,
          math.sin(spark.angle) * spark.distance * travel,
        ),
        spark.radius * (1 - localProgress * 0.25),
        spark.angle + progress,
        ui.Paint()
          ..color = const ui.Color(0xFFFFD54F)
              .withAlpha((255 * sparkOpacity).round()),
      );
    }
    canvas.restore();
  }
}

class _CoinSpark {
  final double angle;
  final double distance;
  final double radius;
  final double delay;

  const _CoinSpark({
    required this.angle,
    required this.distance,
    required this.radius,
    required this.delay,
  });
}

ui.Path _starPath(double outerRadius, double innerRadius, int points) {
  final path = ui.Path();
  for (var i = 0; i < points * 2; i++) {
    final angle = -math.pi / 2 + i * math.pi / points;
    final radius = i.isEven ? outerRadius : innerRadius;
    final point = ui.Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}

void _drawSparkle(
  ui.Canvas canvas,
  ui.Offset center,
  double radius,
  double rotation,
  ui.Paint paint,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(rotation);
  canvas.drawPath(_starPath(radius, radius * 0.22, 4), paint);
  canvas.restore();
}

class AdventureGate extends SpriteComponent {
  AdventureGate({
    required super.sprite,
    required super.position,
  }) : super(
          size: Vector2.zero(),
          anchor: Anchor.bottomCenter,
          priority: 10,
        );

  void resizeToHeight(double height, {required double aspectRatio}) {
    size.setValues(height * aspectRatio, height);
  }
}

class AdventureGuardian extends SpriteComponent {
  AdventureGuardian({
    required super.sprite,
    required super.position,
  }) : super(
          size: Vector2.zero(),
          anchor: Anchor.bottomCenter,
          scale: Vector2(-1, 1),
          priority: 20,
        );

  void resizeToHeight(double height, {required double aspectRatio}) {
    size.setValues(height * aspectRatio, height);
  }
}

class AdventureBackgroundTile extends SpriteComponent {
  final int tileIndex;
  final double seamBlendWidth;

  AdventureBackgroundTile({
    required this.tileIndex,
    required super.sprite,
    required super.position,
    required super.size,
    required super.anchor,
    required super.scale,
    required super.priority,
    this.seamBlendWidth = 0,
  });

  bool get isMirrored => scale.x < 0;
  double get visualLeft => position.x - (isMirrored ? size.x : 0);
  double get visualRight => visualLeft + size.x;

  @override
  void render(ui.Canvas canvas) {
    if (tileIndex == 0 || seamBlendWidth <= 0) {
      super.render(canvas);
      return;
    }

    final bounds = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.saveLayer(bounds, ui.Paint());
    super.render(canvas);
    final fade = ui.Paint()
      ..blendMode = ui.BlendMode.dstIn
      ..shader = ui.Gradient.linear(
        ui.Offset.zero,
        ui.Offset(seamBlendWidth, 0),
        const [ui.Color(0x00000000), ui.Color(0xFF000000)],
      );
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, seamBlendWidth, size.y),
      fade,
    );
    canvas.restore();
  }
}

class AdventureSkyParallaxLayer extends ParallaxLayer {
  AdventureSkyParallaxLayer(
    super.parallaxRenderer, {
    required super.velocityMultiplier,
  });
}

class AdventureBackdropWash extends PositionComponent {
  AdventureBackdropWash() : super(priority: 1);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size.setFrom(size);
  }

  @override
  void render(ui.Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final paint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset.zero,
        ui.Offset(0, size.y),
        const [
          ui.Color(0x66EAF2F4),
          ui.Color(0x40F7F3EA),
        ],
      );
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }
}

class AdventureCloud extends PositionComponent {
  final double driftSpeed;
  final double parallaxFactor;

  AdventureCloud({
    required super.position,
    required super.size,
    required this.driftSpeed,
    required this.parallaxFactor,
  }) : super(priority: -6);

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= driftSpeed * dt;
  }

  @override
  void render(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF).withAlpha(145)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7);
    final width = size.x;
    final height = size.y;
    canvas.drawOval(
      ui.Rect.fromLTWH(0, height * 0.34, width, height * 0.52),
      paint,
    );
    canvas.drawCircle(
      ui.Offset(width * 0.28, height * 0.38),
      height * 0.30,
      paint,
    );
    canvas.drawCircle(
      ui.Offset(width * 0.50, height * 0.27),
      height * 0.42,
      paint,
    );
    canvas.drawCircle(
      ui.Offset(width * 0.73, height * 0.40),
      height * 0.29,
      paint,
    );
  }
}
