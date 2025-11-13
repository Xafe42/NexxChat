import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- KONSTANTEN FÜR GOOGLE GEMINI API ---

// ✅ AKTION: Der API-Key bleibt leer (wird vom System im Backend injiziert)
const String apiKey = 'AIzaSyAfv2px4R99wkA2gWgZB-moIuYTiJi9gAM'; 
const String geminiModel = 'gemini-2.5-flash-preview-09-2025';
const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$apiKey';
const String systemPrompt = "Du bist ein hilfreicher, präziser und freundlicher Chat-Assistent.";

// ------------------------------------------

/// Funktion, um KI-Antwort zu holen (jetzt über Gemini API)
Future<String> fetchAi(String prompt) async {
  final url = Uri.parse(geminiApiUrl);
  final trimmedPrompt = prompt.trim();

  if (trimmedPrompt.isEmpty) {
    return 'Fehler: Bitte geben Sie einen Prompt nach /ai ein.';
  }

  final payload = {
    'contents': [{'parts': [{'text': trimmedPrompt}]}],
    'systemInstruction': {'parts': [{'text': systemPrompt}]},
  };

  const maxRetries = 3;
  int retryDelayMs = 1000;

  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Gemini API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final generatedText = result['candidates']?[0]['content']?['parts']?[0]['text'];

        if (generatedText != null) {
          return generatedText.trim();
        }
        return 'Fehler: KI hat keinen Text generiert.';
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unbekannter API-Fehler';

        if (response.statusCode == 429 && attempt < maxRetries - 1) {
          print('Rate limit hit (429). Retrying in ${retryDelayMs / 1000}s...');
          await Future.delayed(Duration(milliseconds: retryDelayMs));
          retryDelayMs *= 2; 
          continue; 
        }
        
        // 🛑 WICHTIG: Wenn der Fehler 403 (Forbidden) weiterhin auftritt,
        // liegt es daran, dass die Umgebung den Schlüssel NICHT bereitstellt.
        if (response.statusCode == 403) {
             return 'KI-Fehler (403): Zugriff verweigert. Der interne API-Schlüssel konnte nicht geladen werden.';
        }

        return 'KI-Fehler (${response.statusCode}): $errorMessage';
      }
    } catch (e) {
      if (attempt < maxRetries - 1) {
        print('Network error: $e. Retrying in ${retryDelayMs / 1000}s...');
        await Future.delayed(Duration(milliseconds: retryDelayMs));
        retryDelayMs *= 2;
        continue;
      }
      return 'Netzwerkfehler: $e';
    }
  }
  return 'KI-Fehler: Maximale Wiederholungsversuche überschritten.';
}
class AiPreview extends StatefulWidget {
  final VoidCallback onCancel;
  final Future<void> Function(String prompt, String response) onSend;

  const AiPreview({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<AiPreview> createState() => _AiPreviewState();
}

class _AiPreviewState extends State<AiPreview> {
  final _ctrl = TextEditingController();
  final List<Map<String, String>> _messages = []; // prompt + response history
  bool _loading = false;
  String? _error;

  Future<void> _sendPrompt() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _messages.add({'role': 'user', 'text': prompt});
      _ctrl.clear();
    });

    try {
      final response = await fetchAi(prompt);
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': response});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendToFirestore() async {
    for (var msg in _messages.where((m) => m['role'] == 'user')) {
      final prompt = msg['text']!;
      final response = _messages.firstWhere(
        (m) => m['role'] == 'ai' && !_messages.contains(m),
        orElse: () => {'text': ''},
      )['text']!;
      await widget.onSend(prompt, response);
    }
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.blueAccent),
              const SizedBox(width: 8),
              const Expanded(child: Text('AI Preview', style: TextStyle(fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: widget.onCancel),
            ],
          ),
          const Divider(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: msg['role'] == 'user' ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['text']!, style: const TextStyle(fontSize: 14)),
                  ),
                );
              },
            ),
          ),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Type your message...'),
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