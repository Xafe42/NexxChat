import 'package:audioplayers/audioplayers.dart';
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

class SoundState extends State<Sound> {
  bool mute = false;

  final Map<String, AssetSource> _assetCache = {};

 
  Future<AssetSource> _loadAsset(String name) async {
    if (_assetCache.containsKey(name)) {
      return _assetCache[name]!;
    }

    final src = AssetSource('audios/$name');
    _assetCache[name] = src;

    return src;
  }

  
  Future<void> _play(String name) async {
    if (mute) {
      debugPrint("🔇 Sound disabled: $name");
      return;
    }

    try {
      final player = AudioPlayer();
      final asset = await _loadAsset(name);

      await player.play(asset);

      
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint("❌ SOUND ERROR: $e");
    }
  }

  void start() => _play('start.mp3');
  void clear() => _play('clean.mp3');
  void fall() => _play('drop.mp3');
  void rotate() => _play('rotate.mp3');
  void move() => _play('move.mp3');

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}