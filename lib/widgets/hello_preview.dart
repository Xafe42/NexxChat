import 'package:flutter/material.dart';

class HelloPreview extends StatelessWidget {
  final String text;       
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const HelloPreview({
    super.key,
    required this.text,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
          const SizedBox(width: 4),
          ElevatedButton(onPressed: onSend, child: const Text('Send')),
        ],
      ),
    );
  }
}
