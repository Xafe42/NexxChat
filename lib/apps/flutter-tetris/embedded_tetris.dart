import 'package:flutter/material.dart';
import 'material/audios.dart';
import 'gamer/gamer.dart';
import 'material/keyboard.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/panel/page_portrait.dart';

class EmbeddedTetrisGame extends StatelessWidget {
  final void Function(int score) onFinish;

  const EmbeddedTetrisGame({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tetris"),
        backgroundColor: Colors.blue,
      ),

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