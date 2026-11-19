import 'package:codenect_project/room_game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('walkability cells toggle and ignore out-of-bounds coordinates', () {
    final game = RoomGame(
      characterImage: 'male_01_2.png',
      walkabilityEditing: true,
    );

    expect(game.isWalkableAt(2, 3), isTrue);
    game.toggleWalkableCell(2, 3);
    expect(game.isWalkableAt(2, 3), isFalse);

    game.toggleWalkableCell(-1, 3);
    game.toggleWalkableCell(2, 10);
    expect(game.isWalkableAt(2, 3), isFalse);
  });

  test('blocked tiles and positions outside the room cannot be entered', () {
    final game = RoomGame(characterImage: 'male_01_2.png');

    expect(game.canWalk(Vector2(176, 240)), isTrue);
    game.toggleWalkableCell(5, 7);
    expect(game.canWalk(Vector2(176, 240)), isFalse);
    expect(game.canWalk(Vector2(-1, 160)), isFalse);
  });
}
