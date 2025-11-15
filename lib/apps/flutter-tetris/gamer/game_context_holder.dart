import 'package:flutter/material.dart';
import 'gamer.dart';

/// هذا الويجت يضمن أنّ Game.of(context) يلقى GameControl الصحيح.
/// لازم كل ال Widgets اللي تستعمل Game.of(context)
/// يكونو موجودين *داخل* GameContextHolder.
class GameContextHolder extends StatefulWidget {
  final Widget child;

  const GameContextHolder({super.key, required this.child});

  @override
  State<GameContextHolder> createState() => _GameContextHolderState();
}

class _GameContextHolderState extends State<GameContextHolder> {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final game = context.findAncestorStateOfType<GameControl>();
    if (game != null) {
      game.refreshContext(context);
      print("🔥 GameContextHolder linked successfully");
    } else {
      print("❌ GameContextHolder FAILED (No GameControl found)");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}