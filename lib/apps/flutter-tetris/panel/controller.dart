// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import '../gamer/gamer.dart';

/// أحجام الأزرار
const Size directionButtonSize = Size(60, 60);
const Size smallButtonSize = Size(45, 45);

/// =====================================================
///  الحاوية الرئيسية للكنترولز
/// =====================================================
class GameController extends StatelessWidget {
  const GameController({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        children: const [
          Expanded(child: LeftController()),
          Expanded(child: DirectionController()),
        ],
      ),
    );
  }
}

/// =====================================================
///  أزرار الجهة اليسار (Sounds - Pause - Reset - Drop)
/// =====================================================
class LeftController extends StatelessWidget {
  const LeftController({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // يخلي التنسيق أجمل
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SystemButtonGroup(),
          SizedBox(height: 25),
          DropButton(),
        ],
      ),
    );
  }
}

class SystemButtonGroup extends StatelessWidget {
  const SystemButtonGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Game.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _systemBtn(
          label: "Sounds",
          color: Colors.blue,
          onTap: () => game.soundSwitch(),
        ),
        _systemBtn(
          label: "Pause",
          color: Colors.amber,
          onTap: () => game.pauseOrResume(),
        ),
        _systemBtn(
          label: "Reset",
          color: Colors.red,
          onTap: () => game.reset(),
        ),
      ],
    );
  }

  Widget _systemBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => onTap(),
          child: Container(
            width: smallButtonSize.width,
            height: smallButtonSize.height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class DropButton extends StatelessWidget {
  const DropButton({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Game.of(context);

    return Column(
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => game.drop(),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: const Icon(Icons.arrow_downward, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 6),
        const Text("Drop"),
      ],
    );
  }
}

/// =====================================================
///  أزرار الاتجاهات (D-Pad)
/// =====================================================
class DirectionController extends StatelessWidget {
  const DirectionController({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Game.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dirBtn(Icons.keyboard_arrow_up, () => game.rotate()),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dirBtn(Icons.keyboard_arrow_left, () => game.left()),
            const SizedBox(width: 25),
            _dirBtn(Icons.keyboard_arrow_right, () => game.right()),
          ],
        ),

        const SizedBox(height: 10),
        _dirBtn(Icons.keyboard_arrow_down, () => game.down()),
      ],
    );
  }
}

Widget _dirBtn(IconData icon, VoidCallback onTap) {
  return Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: (_) => onTap(),
    child: Container(
      width: directionButtonSize.width,
      height: directionButtonSize.height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 32),
    ),
  );
}