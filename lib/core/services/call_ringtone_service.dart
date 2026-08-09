import 'package:audioplayers/audioplayers.dart';
import 'notification_settings.dart';

class RingtoneService {
  static final AudioPlayer _player = AudioPlayer();

  static bool _playing = false;

  static Future startIncoming() async {
    final soundOn = await NotificationSettings.isSoundEnabled();
    if (!soundOn) return;
    if (_playing) return;

    _playing = true;

    await _player.stop();
    await _player.setVolume(1.0);
    await _player.setReleaseMode(ReleaseMode.loop);

    await _player.play(
      AssetSource("audios/incoming.mp3"),
    );
  }

  static Future startOutgoing() async {
  if (_playing) return;

  _playing = true;

  await _player.stop();
  await _player.setVolume(0.8);
  await _player.setReleaseMode(ReleaseMode.loop);

  await _player.play(
    AssetSource("audios/outgoing.mp3"),
  );
}

  static Future stop() async {
    if (!_playing) return;

    _playing = false;
    await _player.stop();
  }
}