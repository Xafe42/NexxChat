import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Dein Hugging Face Token hier einfügen
const String hfToken = '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';

// Modell auswählen
const String model = 'gpt2';

/// Funktion, um KI-Antwort zu holen und den Prompt-Präfix zu entfernen.
Future<String> fetchAi(String prompt) async {
  final url = Uri.parse('https://api-inference.huggingface.co/models/$model');
  final trimmedPrompt = prompt.trim();

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $hfToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': trimmedPrompt,
        // Model-Loading abwarten, falls es gerade erst gestartet wird
        'options': {'wait_for_model': true}, 
      }),
    );

    // 👉 Debug-Ausgabe
    print('Response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData is List && jsonData.isNotEmpty) {
        final String fullResponse = jsonData[0]['generated_text'] ?? '';
        
        // **Wichtige Korrektur:** Entferne den ursprünglichen Prompt aus der Antwort.
        // T5-Modelle fügen den Prompt oft an den Anfang der generierten Ausgabe.
        if (fullResponse.trim().toLowerCase().startsWith(trimmedPrompt.toLowerCase())) {
          return fullResponse.substring(trimmedPrompt.length).trim();
        }
        
        return fullResponse.trim();
      }
      
      // Fehler, wenn 200, aber leere oder falsche Struktur
      return 'Fehler: Unerwartetes Antwortformat (kein Text gefunden).';
      
    } else {
      // Verbesserte Fehlerbehandlung für non-200 Statuscodes
      try {
        final errorData = jsonDecode(response.body);
        // Hugging Face Fehlerantworten enthalten oft einen 'error'-Schlüssel
        final errorMsg = errorData['error'] ?? 'Unbekannter API-Fehler.';
        return 'KI-Fehler (${response.statusCode}): $errorMsg';
      } catch (e) {
        // Wenn die Antwort kein lesbares JSON ist (z.B. bei einem Timeout)
        return 'Fehler bei der KI-Anfrage (${response.statusCode}).';
      }
    }
  } catch (e) {
    return 'Netzwerkfehler: $e';
  }
}

class AiPreview extends StatefulWidget {
  final String prompt;
  final VoidCallback onCancel;
  final Future<void> Function(String response) onSend;

  const AiPreview({
    super.key,
    required this.prompt,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<AiPreview> createState() => _AiPreviewState();
}

class _AiPreviewState extends State<AiPreview> {
  String? _response;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAiResponse();
  }

  Future<void> _fetchAiResponse() async {
    setState(() {
      _loading = true;
    });
    final result = await fetchAi(widget.prompt);
    setState(() {
      _response = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy),
              const SizedBox(width: 8),
              const Text('AI Preview'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const CircularProgressIndicator()
          else
            // Text-Widget mit angepasstem Padding für bessere Lesbarkeit
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(_response ?? 'Keine Antwort'),
            ),
          if (!_loading)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_response != null) {
                      await widget.onSend(_response!);
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}