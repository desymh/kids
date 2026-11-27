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
  static const double groundYRatio = 0.80;
  static const double playerHeightRatio = 0.46;
  static const double guardianHeightRatio = 0.52;
  static const double gateHeightRatio = 0.74;
  static const double playerStartX = 130;
  static const double gateX = 1700;
  static const double gateGroundOffset = 6;
  static const double actorGroundOffset = 4;
  static const double guardianGateOffset = 85;
  static const double guardianCollisionDistance = 45;
  static const double roadHeightRatio = 0.28;
  static const double roadTileOverlap = 16;
  static const double parallaxSpeed = 24;
  static const double parallaxDamping = 8;
  static const double walkStepTime = 0.18;
  static const double walkBobFrequency = 10;
  static const double walkBobAmplitudeRatio = 0.006;
  static const double skySeamBlendRatio = 0.10;
  static const String skyAsset = 'bg_langit_masjid.png';
  static const String skyAssetFallback = 'bg_langit_masjid.jpeg';

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
  static const int backgroundTileCount = 5;
  static const double backgroundTileOverlap = roadTileOverlap;
  static const double guardianGateOffsetRatio = guardianGateOffset / gateX;

  final void Function() onGateTriggered;
  final void Function()? onGateOpened;
  final AdventureFSM fsm = AdventureFSM();

  bool _moveLeft = false;
  bool _moveRight = false;
  bool _loaded = false;
  bool _wasTouchingGuardian = false;
  double _walkClock = 0;
  double _cameraX = 0;
  double _parallaxVelocityX = 0;

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

  QalbuKidsAdventureGame({
    required this.onGateTriggered,
    this.onGateOpened,
  }) : super(camera: CameraComponent());

  AdventurePlayer get player => _player;
  AdventureGate get gate => _gate;
  AdventureGuardian get guardian => _guardian;
  ParallaxComponent get skyParallax => _skyParallax;
  AdventureBackdropWash get backdropWash => _backdropWash;
  Iterable<AdventureBackgroundTile> get backgroundTiles => _backgroundTiles;
  Iterable<AdventureCloud> get clouds => const [];
  int get cloudCount => 0;
  double get cameraBoundsWidth => worldWidth;

  double get _screenHeight => size.y > 0 ? size.y : 540;
  double get _groundY => _screenHeight * groundYRatio;

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
    final road = await Flame.images.load('ground_jalan.png');

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
      position: Vector2(gateX, _groundY + gateGroundOffset),
    )..flipHorizontallyAroundCenter();
    _player = AdventurePlayer(
      idleAnimation: idleAnimation,
      walkAnimation: walkAnimation,
      position: Vector2(playerStartX, _groundY + actorGroundOffset),
      groundY: _groundY + actorGroundOffset,
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
      position: Vector2(
        gateX - guardianGateOffset,
        _groundY + actorGroundOffset,
      ),
    );

    world.add(_gate);
    world.add(_guardian);
    world.add(_player);

    camera.viewfinder.anchor = Anchor.topLeft;
    _layoutScene();
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

  void completeQuiz(int skor) {
    final opened = fsm.finishQuiz(skor: skor);
    if (opened) {
      _gate.sprite = _openGateSprite;
    }
    _player.setMovementState(fsm.playerState);
    if (opened) onGateOpened?.call();
  }

  void cancelQuiz() {
    stopMoving();
    fsm.cancelQuiz();
    _player.setMovementState(fsm.playerState);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_loaded) return;

    final moveDirection = (_moveRight ? 1.0 : 0.0) - (_moveLeft ? 1.0 : 0.0);
    final targetParallaxVelocity = moveDirection * parallaxSpeed;
    final parallaxBlend = dt > 0 ? 1 - math.exp(-parallaxDamping * dt) : 1;
    _parallaxVelocityX +=
        (targetParallaxVelocity - _parallaxVelocityX) * parallaxBlend;
    _skyParallax.parallax?.baseVelocity.setValues(_parallaxVelocityX, 0);

    if (fsm.gateState == GateState.quizActive) {
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
      _player.setWalkBob(
        math.sin(_walkClock * walkBobFrequency).abs() * walkBobAmplitudeRatio,
      );
      _player.position.y = _player.groundY;
    } else {
      _walkClock = 0;
      _player.setWalkBob(0);
      _player.position.y = _player.groundY;
    }

    _updateCamera(dt);

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

  Future<String> _resolveSkyAssetPath() async {
    try {
      await Flame.bundle.load('${Flame.images.prefix}$skyAsset');
      return skyAsset;
    } catch (_) {
      return skyAssetFallback;
    }
  }

  void _layoutScene() {
    final screenHeight = _screenHeight;
    final groundY = _groundY;

    _player.groundY = groundY + actorGroundOffset;
    _player.position.y = _player.groundY;
    _player.resizeToHeight(
      screenHeight * playerHeightRatio,
      aspectRatio: _playerAspectRatio,
    );

    _gate.position.setValues(gateX, groundY + gateGroundOffset);
    _gate.resizeToHeight(
      screenHeight * gateHeightRatio,
      aspectRatio: _gateAspectRatio,
    );

    _guardian.position.setValues(
      gateX - guardianGateOffset,
      groundY + actorGroundOffset,
    );
    _guardian.resizeToHeight(
      screenHeight * guardianHeightRatio,
      aspectRatio: _guardianAspectRatio,
    );

    for (final tile in _backgroundTiles) {
      tile.removeFromParent();
    }
    _backgroundTiles.clear();

    final roadHeight = screenHeight * roadHeightRatio;
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
    camera.viewfinder.position = Vector2(_cameraX, 0);
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
