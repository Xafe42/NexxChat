import 'dart:convert';

import 'package:http/http.dart' as http;

// Dein Hugging Face Token hier einfügen
const String hfToken = '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';

// Modell, das wir nutzen
const String model = 'gpt2';

Future<String> fetchAi(String prompt) async {
  final url = Uri.parse('https://api-inference.huggingface.co/models/$model');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $hfToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'inputs': prompt,
      'options': {'wait_for_model': true},
    }),
  );

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);

    if (jsonData is List && jsonData.isNotEmpty) {
      return jsonData[0]['generated_text'] ?? 'Keine Antwort';
    }
    if (jsonData is Map && jsonData.containsKey('generated_text')) {
      return jsonData['generated_text'] ?? 'Keine Antwort';
    }
    if (jsonData is Map && jsonData.containsKey('error')) {
      return 'Fehler: ${jsonData['error']}';
    }

    return 'Keine Antwort';
  } else {
    return 'Fehler bei der KI-Anfrage: ${response.statusCode}';
  }
}
