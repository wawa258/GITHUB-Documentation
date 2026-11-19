import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Text;
import 'package:flutter/material.dart';

/// Use this as the first screen: home: const RoomScreen()
class RoomScreen extends StatelessWidget {
  final String characterImage;
  final String playerName;
  const RoomScreen({
    super.key,
    this.characterImage = 'male_01_2.png',
    this.playerName = 'Player',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(game: RoomGame(characterImage: characterImage)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xCC0D0620)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Return to lobby',
                        onPressed: () {
                          Navigator.of(context).maybePop();
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          'PHASE 1 - START OF ADVENTURE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'Tap to move - ${playerName.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoomGame extends FlameGame with TapCallbacks {
  final String characterImage;
  RoomGame({required this.characterImage});

  late final Player player;

  @override
  Future<void> onLoad() async {
    final map = await TiledComponent.load(
      'assets/maps/room.tmx',
      Vector2.all(32),
      imagesDirectory: 'assets/maps/',
    );
    world.add(map);

    final sheet = SpriteSheet(
      image: await images.load('assets/maps/$characterImage'),
      srcSize: Vector2.all(32),
    );

    player = Player(sheet)
      ..position = Vector2(160, 224)
      ..anchor = Anchor.center;
    world.add(player);

    camera.viewfinder.position = Vector2(160, 160);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    camera.viewfinder.zoom = math.min(size.x / 320, size.y / 320);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isLoaded) {
      player.moveTo(camera.globalToLocal(event.canvasPosition));
    }
  }
}

class Player extends SpriteAnimationComponent {
  final SpriteSheet sheet;
  Vector2? target;
  static const speed = 90.0;

  Player(this.sheet)
    : super(
        animation: sheet.createAnimation(row: 0, stepTime: 0.2, to: 3),
        size: Vector2.all(32),
        playing: false,
      );

  void moveTo(Vector2 p) => target = p;

  @override
  void update(double dt) {
    super.update(dt);
    final t = target;
    if (t == null) return;
    final diff = t - position;
    if (diff.length < 2) {
      target = null;
      playing = false;
      return;
    }
    final row = diff.x.abs() > diff.y.abs()
        ? (diff.x > 0 ? 2 : 1)
        : (diff.y > 0 ? 0 : 3);
    animation = sheet.createAnimation(row: row, stepTime: 0.2, to: 3);
    playing = true;
    position += diff.normalized() * speed * dt;
  }
}
