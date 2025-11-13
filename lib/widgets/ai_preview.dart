import 'package:flutter/material.dart';


// Beispiel für eine Dummy-Funktion => richtige Ki fehlt noch
// https://huggingface.co/docs/inference-providers/index
Future<String> fetchAi(String prompt) async {
  await Future.delayed(const Duration(seconds: 2)); // Simuliert Wartezeit
  return "Antwort der KI auf: $prompt"; // Dummy-Antwort
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
    final result = await fetchAi(widget.prompt); // Dein Backend/API
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
            Text(_response ?? 'Keine Antwort'),
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
