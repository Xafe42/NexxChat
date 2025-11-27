import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Color color; // Farbe des Buttons
  final String titel; // Text des Buttons
  final VoidCallback onPressed; // Funktion bei Klick

  const MyButton({
    required this.color,
    required this.titel,
    required this.onPressed,
    super.key, // super.key für StatelessWidget
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10), // Abstand oben/unten
      child: Material(
        elevation: 5, // Schatten
        color: color, // Hintergrundfarbe
        borderRadius: BorderRadius.circular(10), // Abgerundete Ecken
        child: MaterialButton(
          onPressed: onPressed, // Klick-Funktion
          minWidth: 200, // Mindestbreite
          height: 42, // Höhe
          child: Text(
            titel, // Button-Text
            style: const TextStyle(color: Colors.white), // Textfarbe
          ),
        ),
      ),
    );
  }
}
