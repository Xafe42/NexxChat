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
    // Optimierung für eine „echtere“ Stimme
    _tts.setSpeechRate(0.45); // Etwas langsamer wirkt oft natürlicher
    _tts.setPitch(1.0);       // Neutraler Pitch
    _tts.setVolume(1.0);
  }

  FlutterTts get tts => _tts;

  // Akzeptiert jetzt userText UND den systemPrompt
  Future<String> getResponse(String userText, String systemPrompt) async {
    try {
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
                  '$systemPrompt Deine Antworten müssen IMMER extrem kurz sein (maximal 1 bis 2 Sätze). '
                  'Antworte als deine persönliche KI. '
                  'WICHTIG: Benutze NIEMALS Smileys, Emojis oder Sonderzeichen wie :) oder :D in deinen Antworten.'
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
            "Ich höre dir zu.";
      } else {
        print("API Fehler: ${res.statusCode}");
        if (res.statusCode == 429) return "Zu viele Anfragen. Bitte warte kurz.";
        return "Ich hab gerade ein technisches Problem.";
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