import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/gamer/gamer.dart';


class MobileControls extends StatelessWidget {
  const MobileControls({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Game.of(context); 

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
       
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _controlCircle(
              label: '⟳',
              onTap: game.rotate,
            ),
          ],
        ),
        const SizedBox(height: 16),

        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _controlCircle(label: '◀', onTap: game.left),
            const SizedBox(width: 16),
            _controlCircle(label: '▼', onTap: game.down),
            const SizedBox(width: 16),
            _controlCircle(label: '▶', onTap: game.right),
            const SizedBox(width: 16),
            _controlCircle(label: '⤓', onTap: game.drop),
          ],
        ),
        const SizedBox(height: 16),

        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _controlCircle(
              label: 'P',
              onTap: game.pauseOrResume,
              small: true,
            ),
            const SizedBox(width: 12),
            _controlCircle(
              label: 'S',
              onTap: game.soundSwitch,
              small: true,
            ),
            const SizedBox(width: 12),
            _controlCircle(
              label: 'R',
              onTap: game.reset,
              small: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _controlCircle({
    required String label,
    required VoidCallback onTap,
    bool small = false,
  }) {
    final double size = small ? 44 : 64;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}