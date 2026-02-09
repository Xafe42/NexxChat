import 'dart:convert';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class AiCompanionService {
  final FlutterTts _tts = FlutterTts();

  // Wir nutzen exakt deine funktionierende Konfiguration vom Support Bot
  static const String apiKey = 'AIzaSyAfv2px4R99wkA2gWgZB-moIuYTiJi9gAM';
  static const String model = 'gemini-2.5-flash-preview-09-2025';
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

  AiCompanionService() {
    _initTts();
  }

  void _initTts() {
    _tts.setLanguage("de-DE");
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.1);
  }

  FlutterTts get tts => _tts;

  Future<String> getResponse(String userText) async {
    try {
      // Wir bauen den Payload exakt wie im Support Bot
      final payload = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userText}
            ]
          }
        ],
        'systemInstruction': {
          'parts': [
            {
              'text':
                  'Du bist Bärbel, die liebevolle KI-Freundin des Nutzers. Antworte liebevoll, humorvoll und EXTREM KURZ (maximal 2 Sätze).'
            }
          ]
        }
      };

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['candidates']?[0]['content']?['parts']?[0]['text'] ??
            "Ich höre dir zu, mein Schatz.";
      } else {
        print("Bärbel API Fehler: ${res.statusCode} - ${res.body}");
        return "Ich hab gerade ein kleines Funkloch, Liebling.";
      }
    } catch (e) {
      print("Netzwerkfehler: $e");
      return "Ich glaube, meine Internetverbindung zickt gerade.";
    }
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  void stop() => _tts.stop();
}