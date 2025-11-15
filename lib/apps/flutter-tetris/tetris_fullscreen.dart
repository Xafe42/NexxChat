import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/panel/page_portrait.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/gamer/gamer.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/material/audios.dart';

class TetrisFullScreen extends StatelessWidget {
  const TetrisFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Sound(
          child: Game(
            child: const PagePortrait(),
          ),
        ),
      ),
    );
  }
}