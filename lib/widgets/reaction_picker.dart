import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String) onSelect;

  const ReactionPicker({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _emoji("❤️", context),
          _emoji("😂", context),
          _emoji("🔥", context),
          _emoji("😮", context),
          _emoji("😡", context),
          _emoji("👍", context),
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
        padding: const EdgeInsets.all(10),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}