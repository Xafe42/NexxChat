import 'package:flutter/material.dart';
import '../constants.dart';

import '../panel/controller.dart';
import '../panel/screen.dart';

part 'page_land.dart';

class PagePortrait extends StatelessWidget {
  const PagePortrait({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenW = size.width * 0.8;

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,   // ← FIXED
        ),
        child: Padding(
          padding: MediaQuery.of(context).padding,
          child: Column(
            children: <Widget>[
              const Spacer(),
              _ScreenDecoration(child: Screen(width: screenW)),
              const Spacer(flex: 2),
              const GameController(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenDecoration extends StatelessWidget {
  final Widget child;

  const _ScreenDecoration({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF987f0f), width: screenBorderWidth),
          left: BorderSide(color: Color(0xFF987f0f), width: screenBorderWidth),
          right: BorderSide(color: Color(0xFFfae36c), width: screenBorderWidth),
          bottom: BorderSide(color: Color(0xFFfae36c), width: screenBorderWidth),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: screenBackground,            // ← FIXED
          border: Border.all(color: Colors.black54),
        ),
        child: child,
      ),
    );
  }
}