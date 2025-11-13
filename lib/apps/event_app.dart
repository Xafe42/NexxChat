import 'package:cloud_firestore/cloud_firestore.dart';

class EventApp {
  static Map<String, dynamic> buildPayload(Map<String, dynamic> data) {
    return {
      'payload': {
        'app': 'event',
        'data': {
          'title': data['title'] ?? '',
          'location': data['location'] ?? '',
          'description': data['description'] ?? '',
          'datetime': data['datetime']?.toIso8601String() ?? '',
          'votes': {
            'yes': [],
            'maybe': [],
            'no': [],
          }
        }
      },
      'type': 'event', 
      'time': FieldValue.serverTimestamp(),
    };
  }
}