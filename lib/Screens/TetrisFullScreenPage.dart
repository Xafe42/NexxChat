import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/material/audios.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/gamer/gamer.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/material/keyboard.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/panel/page_portrait.dart';

class TetrisFullScreenPage extends StatelessWidget {
  final void Function(int score) onFinish;

  const TetrisFullScreenPage({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tetris")),

      body: Sound(
        child: Game(
          child: KeyboardController(
            child: const PagePortrait(),   
          ),
        ),
      ),
    );
  }
}