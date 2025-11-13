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
    
    if (widget.prompt.isNotEmpty) {
      final result = await fetchAi(widget.prompt);
      
      // Korrektur: Prüfen, ob das Widget noch im Baum ist (mounted)
      if (mounted) { 
        setState(() {
          _response = result;
          _loading = false;
        });
      }
    } else {
      // Korrektur: Prüfen, ob das Widget noch im Baum ist (mounted)
      if (mounted) {
        setState(() {
          _response = 'Fehler: Kein Prompt eingegeben.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8.0), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
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
              // Korrektur: Expanded behebt den RenderFlex Overflow
              Expanded( 
                child: Text(
                  'AI Preview (${geminiModel})', 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis, // Verhindert horizontalen Overflow
                ),
              ), 
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