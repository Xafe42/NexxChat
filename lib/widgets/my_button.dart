import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Color color;
  final String titel;
  final VoidCallback onPressed;

  const MyButton({
    required this.color,
    required this.titel,
    required this.onPressed,
    super.key, // ✅ super.key statt key: key
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Material(
        elevation: 5,
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: MaterialButton(
          onPressed: onPressed,
          minWidth: 200,
          height: 42,
          child: Text(
            titel,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}