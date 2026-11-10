import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

// --- KONSTANTEN FÜR GOOGLE GEMINI API ---
// API-Key für den Zugriff auf die Google Gemini API
const String apiKey = ApiConfig.geminiApiKey;
// Modellname
const String geminiModel = 'gemini-2.5-flash-preview-09-2025';
// URL für die API-Anfrage, inkl. API-Key
const String geminiApiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$apiKey';
// System-Prompt für die KI (z. B. Rollenbeschreibung)
const String systemPrompt =
    "Du bist ein hilfreicher, präziser und freundlicher Chat-Assistent.";

// ------------------------------------------

// Funktion, um eine KI-Antwort von der Gemini API zu holen
Future<String> fetchAi(String prompt) async {
  final url = Uri.parse(geminiApiUrl);
  final trimmedPrompt = prompt.trim(); // Whitespace entfernen

  // Prüfen, ob der Prompt leer ist
  if (trimmedPrompt.isEmpty) {
    return 'Fehler: Bitte geben Sie einen Prompt nach /ai ein.';
  }

  // Payload für die API: enthält Prompt und Systemanweisung
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

  const maxRetries = 3; // maximale Wiederholversuche bei Fehlern
  int retryDelayMs = 1000; // Startverzögerung zwischen Versuchen

  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      // HTTP POST Anfrage an die API
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );


      // Erfolg: 200 OK
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final generatedText =
            result['candidates']?[0]['content']?['parts']?[0]['text'];

        if (generatedText != null) {
          return generatedText.trim(); // KI-Antwort zurückgeben
        }
        return 'Fehler: KI hat keinen Text generiert.';
      } else {
        // Fehlerbehandlung
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error']?['message'] ?? 'Unbekannter API-Fehler';

        // Rate-Limit Fehler: 429 → Retry mit wachsender Verzögerung
        if (response.statusCode == 429 && attempt < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: retryDelayMs));
          retryDelayMs *= 2;
          continue;
        }

        // Zugriff verweigert: 403 → Schlüssel nicht verfügbar
        if (response.statusCode == 403) {
          return 'KI-Fehler (403): Zugriff verweigert. Der interne API-Schlüssel konnte nicht geladen werden.';
        }

        return 'KI-Fehler (${response.statusCode}): $errorMessage';
      }
    } catch (e) {
      // Netzwerkfehler → Retry
      if (attempt < maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: retryDelayMs));
        retryDelayMs *= 2;
        continue;
      }
      return 'Netzwerkfehler: $e';
    }
  }

  // Falls alle Versuche fehlschlagen
  return 'KI-Fehler: Maximale Wiederholungsversuche überschritten.';
}

// Widget für die Vorschau von AI-Nachrichten
class AiPreview extends StatefulWidget {
  final VoidCallback onCancel; // Callback für Abbrechen
  final Future<void> Function(String prompt, String response)
  onSend; // Callback zum Senden

  const AiPreview({super.key, required this.onCancel, required this.onSend});

  @override
  State<AiPreview> createState() => _AiPreviewState();
}

class _AiPreviewState extends State<AiPreview> {
  final _ctrl = TextEditingController(); // Controller für Texteingabe
  final List<Map<String, String>> _messages =
      []; // Verlauf: prompt + KI-Antworten
  bool _loading = false; // Ladeindikator
  String? _error; // Fehleranzeige

  // Funktion, um den Prompt an die KI zu senden
  Future<void> _sendPrompt() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) return;

    // UI-Zustand aktualisieren: Ladezustand, Fehler zurücksetzen, User-Nachricht speichern
    setState(() {
      _loading = true;
      _error = null;
      _messages.add({'role': 'user', 'text': prompt});
      _ctrl.clear();
    });

    try {
      // KI-Antwort holen
      final response = await fetchAi(prompt);
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': response}); // Antwort speichern
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler: $e'; // Fehler anzeigen
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false; // Ladezustand zurücksetzen
        });
      }
    }
  }

  // Funktion, um alle User/KI-Paare an Firestore zu senden

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kopfzeile mit Titel und Abbrechen-Button
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.blueAccent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Preview',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const Divider(),
          // Verlauf der Nachrichten anzeigen
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg['role'] == 'user'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: msg['role'] == 'user'
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg['text']!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),
          // Fehleranzeige
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          // Eingabefeld und Senden-Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                  ),
                  onSubmitted: (_) => _sendPrompt(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _loading ? null : _sendPrompt,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
