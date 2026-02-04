import 'package:flutter/material.dart';
import 'in_app_banner.dart';

class BannerService {
  static OverlayEntry? _current;

static void show(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onTap,
  Duration duration = const Duration(seconds: 4),
}) {
  if (_current != null) return;

  final overlay = Navigator.of(context).overlay;

  if (overlay == null) {
    print("❌ NO OVERLAY FOUND");
    return;
  }

  _current = OverlayEntry(
    builder: (_) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: InAppBanner(
        title: title,
        message: message,
        onTap: () {
          hide();
          onTap?.call();
        },
      ),
    ),
  );

  overlay.insert(_current!);

  Future.delayed(duration, hide);
}

  static void hide() {
    _current?.remove();
    _current = null;
  }
}