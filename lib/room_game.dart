import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Text;
import 'package:flutter/material.dart';

/// Use this as the first screen: home: const RoomScreen()
class RoomScreen extends StatefulWidget {
  final String characterImage;
  final String playerName;
  final bool editWalkability;
  const RoomScreen({
    super.key,
    this.characterImage = 'male_01_2.png',
    this.playerName = 'Player',
    this.editWalkability = false,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late final RoomGame _game;

  @override
  void initState() {
    super.initState();
    _game = RoomGame(
      characterImage: widget.characterImage,
      walkabilityEditing: widget.editWalkability,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                          _game.walkabilityEditing
                              ? 'ROOM WALKABILITY EDITOR'
                              : 'PHASE 1 - START OF ADVENTURE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (_game.walkabilityEditing)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'GREEN: WALKABLE  RED: BLOCKED',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11),
                          ),
                        )
                      else
                        Flexible(
                          child: Text(
                            'Tap to move - ${widget.playerName.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _game.walkabilityEditing =
                                !_game.walkabilityEditing;
                          });
                        },
                        child: Text(
                          _game.walkabilityEditing
                              ? 'DONE'
                              : 'EDIT WALKABLE',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final roomSize = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Center(
                    child: SizedBox(
                      width: roomSize,
                      height: roomSize,
                      child: GameWidget(game: _game),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomGame extends FlameGame with TapCallbacks {
  final String characterImage;
  bool walkabilityEditing;
  static const int gridSize = 10;
  static const double tileSize = 32;
  final List<List<bool>> _walkable = List.generate(
    gridSize,
    (_) => List.filled(gridSize, true),
  );

  RoomGame({
    required this.characterImage,
    this.walkabilityEditing = false,
  });

  late final Player player;

  bool isWalkableAt(int column, int row) {
    if (column < 0 || column >= gridSize || row < 0 || row >= gridSize) {
      return false;
    }
    return _walkable[row][column];
  }

  void toggleWalkableCell(int column, int row) {
    if (column < 0 || column >= gridSize || row < 0 || row >= gridSize) {
      return;
    }
    _walkable[row][column] = !_walkable[row][column];
  }

  bool canWalk(Vector2 position) {
    final halfPlayer = 16.0;
    final left = ((position.x - halfPlayer) / tileSize).floor();
    final right = ((position.x + halfPlayer - 0.001) / tileSize).floor();
    final top = ((position.y - halfPlayer) / tileSize).floor();
    final bottom = ((position.y + halfPlayer - 0.001) / tileSize).floor();
    for (var row = top; row <= bottom; row++) {
      for (var column = left; column <= right; column++) {
        if (!isWalkableAt(column, row)) return false;
      }
    }
    return true;
  }

  @override
  Future<void> onLoad() async {
    final map = await TiledComponent.load(
      'assets/maps/room.tmx',
      Vector2.all(32),
      atlasMaxY: 8192,
      imagesDirectory: 'assets/maps/',
    );
    world.add(map);
    world.add(WalkabilityGrid(this));

    final sheet = SpriteSheet(
      image: await images.load('assets/maps/$characterImage'),
      srcSize: Vector2.all(32),
    );

    player = Player(sheet, canWalk: canWalk)
      ..position = Vector2(176, 240)
      ..anchor = Anchor.center;
    world.add(player);

    camera.viewfinder.position = Vector2(160, 160);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    camera.viewfinder.zoom = math.min(size.x / 320, size.y / 320) * 0.9;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isLoaded) return;
    final position = camera.globalToLocal(event.canvasPosition);
    if (walkabilityEditing) {
      final column = (position.x / tileSize).floor();
      final row = (position.y / tileSize).floor();
      toggleWalkableCell(column, row);
    } else if (canWalk(position)) {
      player.moveTo(position);
    }
  }
}

class WalkabilityGrid extends Component {
  final RoomGame game;

  WalkabilityGrid(this.game);

  @override
  void render(Canvas canvas) {
    if (!game.walkabilityEditing) return;

    final fill = Paint();
    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var row = 0; row < RoomGame.gridSize; row++) {
      for (var column = 0; column < RoomGame.gridSize; column++) {
        fill.color = game.isWalkableAt(column, row)
            ? Colors.green.withValues(alpha: 0.38)
            : Colors.red.withValues(alpha: 0.48);
        final rect = Rect.fromLTWH(
          column * RoomGame.tileSize,
          row * RoomGame.tileSize,
          RoomGame.tileSize,
          RoomGame.tileSize,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, border);
      }
    }
  }
}

class Player extends SpriteAnimationComponent {
  final SpriteSheet sheet;
  final bool Function(Vector2) canWalk;
  Vector2? target;
  static const speed = 90.0;

  Player(this.sheet, {required this.canWalk})
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
    final nextPosition = position + diff.normalized() * speed * dt;
    if (!canWalk(nextPosition)) {
      target = null;
      playing = false;
      return;
    }
    position.setFrom(nextPosition);
  }
}
