import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

// Hugging Face Token 
const String hfToken = ApiConfig.huggingFaceToken;
// Modell auswählen
const String model = 'distilgpt2';

/// Funktion, um KI-Antwort zu holen und den Prompt-Präfix zu entfernen.
Future<String> fetchAi(String prompt) async {
  final url = Uri.parse('https://api-inference.huggingface.co/models/$model');
  final trimmedPrompt = prompt.trim();

  // Prüfen, ob der Prompt überhaupt existiert
  if (trimmedPrompt.isEmpty) {
    return 'Fehler: Bitte geben Sie einen Prompt nach /ai ein.';
  }

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $hfToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': trimmedPrompt,
        // Model-Loading abwarten
        'options': {'wait_for_model': true}, 
      }),
    );

    // 👉 Debug-Ausgabe

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData is List && jsonData.isNotEmpty) {
        final String fullResponse = jsonData[0]['generated_text'] ?? '';
        
        // Entferne den ursprünglichen Prompt aus der Antwort
        if (fullResponse.trim().toLowerCase().startsWith(trimmedPrompt.toLowerCase())) {
          return fullResponse.substring(trimmedPrompt.length).trim();
        }
        
        return fullResponse.trim();
      }

      // Fehler, wenn 200, aber leere oder falsche Struktur

      return 'Fehler: Unerwartetes Antwortformat (kein Text gefunden).';
      
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? 'Unbekannter API-Fehler.'; 
        return 'KI-Fehler (${response.statusCode}): $errorMsg';
      } catch (e) {
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
    // Ruft die KI nur auf, wenn der Prompt nicht leer ist
    if (widget.prompt.isNotEmpty) {
      final result = await fetchAi(widget.prompt);
      setState(() {
        _response = result;
        _loading = false;
      });
    } else {
      setState(() {
        _response = 'Fehler: Kein Prompt eingegeben.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8.0), // Kleiner Abstand zum Input
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.blueAccent),
              const SizedBox(width: 8),
              // Zeigt an, welches Modell verwendet wird
              Text('AI Preview ($model)', style: const TextStyle(fontWeight: FontWeight.bold)), 
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const Divider(height: 10),
          // Scrollbarer Bereich für die Antwort
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: _loading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.blueAccent),
                    ))
                  : Text(_response ?? 'Keine Antwort', style: const TextStyle(fontSize: 14)),
            ),
          ),
          
          if (!_loading && _response != null && !_response!.startsWith('KI-Fehler'))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_response != null) {
                        await widget.onSend(_response!);
                      }
                    },
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}