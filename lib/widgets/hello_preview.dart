import 'package:flutter/material.dart';

class HelloPreview extends StatelessWidget {
  final String text;       // Vorschautext des Kommandos
  final VoidCallback onCancel; // Funktion bei Abbrechen
  final VoidCallback onSend;   // Funktion bei Senden

  const HelloPreview({
    super.key,
    required this.text,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180), // Animation beim Ein-/Ausblenden
      curve: Curves.easeInOut, // Animationskurve
      color: Colors.grey[100], // Hintergrundfarbe
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Innenabstand
      child: Row(
        children: [
          Expanded(
            child: Text(
              text, // Zeigt den Vorschautext
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: onCancel, // Abbrechen-Button
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 4), // Abstand zwischen Buttons
          ElevatedButton(
            onPressed: onSend, // Senden-Button
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
