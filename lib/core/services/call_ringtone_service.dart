import 'package:audioplayers/audioplayers.dart';

class RingtoneService {
  static final _player = AudioPlayer();

  static Future startIncoming() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource("audios/incoming.mp3"));
  }

  static Future startOutgoing() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource("audios/outgoing.mp3"));
  }

  static Future stop() async {
    await _player.stop();
  }
}