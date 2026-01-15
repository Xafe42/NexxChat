import 'package:flutter/material.dart';


class IncomingCallScreen extends StatelessWidget {
  final String callId;
  final String title;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.title,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: onDecline,
                  child: const Icon(Icons.call_end),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: onAccept,
                  child: const Icon(Icons.call),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}