import 'package:flutter/material.dart';
import '../constants.dart';
import '../panel/controller.dart';
import '../panel/screen.dart';

class PagePortrait extends StatelessWidget {
  const PagePortrait({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenW = size.width * 0.8;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Spacer(),
          _ScreenDecoration(child: Screen(width: screenW)),
          const Spacer(),
          const GameController(),
        ],
      ),
    );
  }
}

class _ScreenDecoration extends StatelessWidget {
  final Widget child;

  const _ScreenDecoration({required this.child});

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
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black54),
        ),
        padding: const EdgeInsets.all(3),
        color: screenBackground,
        child: child,
      ),
    );
  }
}