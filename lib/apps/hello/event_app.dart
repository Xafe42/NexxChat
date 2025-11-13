// apps/event/event_app.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EventApp {
  static Map<String, dynamic> buildPayload(Map<String, dynamic> data) {
    // expects: title, datetime (DateTime), location, description
    final DateTime? dt = data['datetime'] as DateTime?;
    return {
      'type': 'app',
      'payload': {
        'app': 'event',
        'data': {
          'title': (data['title'] ?? '').toString(),
          'datetime': dt?.toIso8601String(),
          'location': (data['location'] ?? '').toString(),
          'description': (data['description'] ?? '').toString(),
        },
      },
      'time': FieldValue.serverTimestamp(),
    };
  }
}