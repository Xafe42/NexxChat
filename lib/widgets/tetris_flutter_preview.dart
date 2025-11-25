import 'package:flutter/material.dart';

class TetrisFlutterPreview extends StatelessWidget {
  final VoidCallback onCancel;
  final void Function() onPlay;

  const TetrisFlutterPreview({
    super.key,
    required this.onCancel,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ---------- HEADER ----------
          Row(
            children: [
              const Icon(Icons.videogame_asset, color: Colors.blueGrey),
              const SizedBox(width: 8),
              const Text(
                "Tetris Game",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: onCancel,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ---------- PREVIEW IMAGE ----------
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.videogame_asset, size: 50, color: Colors.grey),
            ),
          ),

          const SizedBox(height: 14),

          // ---------- TEXT ----------
          const Text(
            "Ready to play Tetris?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          const Text(
            "Click Play to open the full-screen Tetris game.",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),

          const SizedBox(height: 16),

          // ---------- BUTTONS ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onPlay,
                child: const Text("Play"),
              ),
            ],
          )
        ],
      ),
    );
  }
}