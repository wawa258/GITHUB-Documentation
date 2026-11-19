import 'package:flutter/material.dart';

import '../create_player_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.player});

  final PlayerConfig player;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Welcome, ${player.name}!',
          style: px(20, cGold),
        ),
      ),
    );
  }
}
