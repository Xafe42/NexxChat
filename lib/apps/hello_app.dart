import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HelloApp {
  static Map<String, dynamic> buildPayload(Map<String, dynamic> data) {
    final who = (data['who'] ?? 'World').toString();
    return {
      'type': 'app',
      'payload': {
        'app': 'hello',
        'data': {'who': who},
      },
      'time': FieldValue.serverTimestamp(),
    };
  }

  
  static Widget buildCard(String who) {
    return Card(
      color: Colors.amber[100],
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '👋 Hello $who from NexxChat!',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
