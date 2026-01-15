import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String) onSelect;

  const ReactionPicker({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 15), 
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SingleChildScrollView( // Falls es mal mehr Emojis werden
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _emoji("❤️", context),
                _emoji("😂", context),
                _emoji("🔥", context),
                _emoji("😮", context),
                _emoji("😡", context),
                _emoji("👍", context),
                const SizedBox(width: 10),
                // Button zum Löschen aller eigenen Reaktionen
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onSelect("REMOVE_ALL"); // Spezial-Key zum Löschen
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _emoji(String emoji, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onSelect(emoji);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}