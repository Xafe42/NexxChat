import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/core/services/notification_settings.dart';
import 'in_app_banner.dart';
import 'package:audioplayers/audioplayers.dart';

class BannerService {
  static final List<_BannerItem> _queue = [];
  static bool _showing = false;
  static final AudioPlayer _player = AudioPlayer();

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required String? avatarUrl,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    _queue.add(
      _BannerItem(
        context: context,
        title: title,
        message: message,
        avatarUrl: avatarUrl,
        onTap: onTap,
        duration: duration,
      ),
    );

    _tryShowNext();
  }

  static Future<void> _tryShowNext() async {
    if (_showing || _queue.isEmpty) return;

    final item = _queue.removeAt(0);
    final overlay = Navigator.of(item.context).overlay;
    if (overlay == null) return;

    _showing = true;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: InAppBanner(
          title: item.title,
          message: item.message,
          avatarUrl: item.avatarUrl,
          onTap: () {
            if (entry.mounted) entry.remove();
            _showing = false;
            item.onTap?.call();
            _tryShowNext();
          },
        ),
      ),
    );

    overlay.insert(entry);

    // SOUND
    final soundEnabled =
        await NotificationSettings.isSoundEnabled();

    if (soundEnabled) {
      try {
        await _player.stop();
        await _player.setVolume(0.6);
        await _player.play(
          AssetSource('audios/notify.mp3'),
        );
      } catch (_) {}
    }

    Future.delayed(item.duration, () {
      if (entry.mounted) entry.remove();
      _showing = false;
      _tryShowNext();
    });
  }
}

class _BannerItem {
  final BuildContext context;
  final String title;
  final String message;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final Duration duration;

  _BannerItem({
    required this.context,
    required this.title,
    required this.message,
    required this.avatarUrl,
    required this.onTap,
    required this.duration,
  });
}