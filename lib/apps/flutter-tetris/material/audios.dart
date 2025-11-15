import 'package:flutter/material.dart';

class Sound extends StatefulWidget {
  final Widget child;

  const Sound({super.key, required this.child});

  @override
  SoundState createState() => SoundState();

  static SoundState of(BuildContext context) {
    final state = context.findAncestorStateOfType<SoundState>();
    assert(state != null, 'Sound widget not found in widget tree');
    return state!;
  }
}

// نحافظ على أسماء الأصوات باش الكود الباقي ما يطيحش
const sounds = [
  'clean.mp3',
  'drop.mp3',
  'explosion.mp3',
  'move.mp3',
  'rotate.mp3',
  'start.mp3',
];

class SoundState extends State<Sound> {
  bool mute = false;

  @override
  Widget build(BuildContext context) {
    // اللعبة تخدم عادي
    return widget.child;
  }

  // هذه توظّف نفس الـ API بصوت صامت
  void _log(String name) {
    debugPrint("🔇 Sound disabled: $name");
  }

  void start() => _log('start.mp3');
  void clear() => _log('clean.mp3');
  void fall() => _log('drop.mp3');
  void rotate() => _log('rotate.mp3');
  void move() => _log('move.mp3');
}