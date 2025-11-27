import 'package:flutter/widgets.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/gamer/gamer.dart';


class Game extends InheritedWidget {
  final GameState state;

  const Game({
    super.key,
    required this.state,
    required super.child,
  });

  static GameState of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<Game>();
    assert(widget != null, 'Game widget not found in widget tree.');
    return widget!.state;
  }

  @override
  bool updateShouldNotify(Game oldWidget) => oldWidget.state != state;
}