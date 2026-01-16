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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              // 👤 Avatar + Name
              Column(
                children: [
                  CircleAvatar(
  radius: 55,
  backgroundColor: Colors.white24,
  child: Text(
    title.isNotEmpty ? title[0].toUpperCase() : "?",
    style: const TextStyle(
      fontSize: 42,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
),

const SizedBox(height: 20),

Text(
  title,
  textAlign: TextAlign.center,
  style: const TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.w600,
  ),
),

const SizedBox(height: 8),

const Text(
  "Incoming video call",
  style: TextStyle(
    color: Colors.white70,
    fontSize: 16,
  ),
),
                ],
              ),

              // 🟢🔴 Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 🔴 Decline
                    GestureDetector(
                      onTap: onDecline,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),

                    // 🟢 Accept
                    GestureDetector(
                      onTap: onAccept,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}