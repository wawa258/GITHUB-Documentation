import 'package:flutter/material.dart';

import 'room_game.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0D0620),
      ),
      home: RoomScreen(playerName: 'Editor', editWalkability: true),
    ),
  );
}
