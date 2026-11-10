import 'dart:convert';

import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

// --- KONSTANTEN FÜR GOOGLE GEMINI API ---
const String apiKey = ApiConfig.geminiApiKey;
const String geminiModel = 'gemini-2.5-flash-preview-09-2025';
const String geminiApiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$apiKey';
const String systemPrompt =
    "Du bist ein hilfreicher, präziser und freundlicher Chat-Assistent.";

// Funktion, um eine KI-Antwort von der Gemini API zu holen
Future<String> fetchAi(String prompt) async {
  final url = Uri.parse(geminiApiUrl);
  final trimmedPrompt = prompt.trim(); 

  if (trimmedPrompt.isEmpty) {
    return 'Fehler: Bitte geben Sie einen Prompt ein.';
  }

  final payload = {
    'contents': [
      {
        'parts': [
          {'text': trimmedPrompt},
        ],
      },
    ],
    'systemInstruction': {
      'parts': [
        {'text': systemPrompt},
      ],
    },
  };

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final generatedText =
          result['candidates']?[0]['content']?['parts']?[0]['text'];

      return generatedText?.trim() ?? 'KI hat keinen Text generiert.';
    } else {
      return 'KI-Fehler (${response.statusCode})';
    }
  } catch (e) {
    return 'Netzwerkfehler: $e';
  }
}