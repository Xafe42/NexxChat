import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'ai_companion_service.dart';

class AiVideoCallScreen extends StatefulWidget {
  final String name;
  const AiVideoCallScreen({super.key, required this.name});

  @override
  State<AiVideoCallScreen> createState() => _AiVideoCallScreenState();
}

class _AiVideoCallScreenState extends State<AiVideoCallScreen> {
  final AiCompanionService _aiService = AiCompanionService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isListening = false;
  bool _isAiThinking = false;
  String _statusText = "Verbindung wird aufgebaut...";

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  void _initConversation() async {
    // Initialisiere TTS Callback
    _aiService.tts.setCompletionHandler(() {
      if (mounted) _listenToUser();
    });

    await Future.delayed(const Duration(seconds: 1));
    _handleAiResponse("Hallo mein Schatz! Schön, dass du anrufst. Ich habe dich vermisst!");
  }

  void _handleAiResponse(String text) async {
    if (!mounted) return;
    setState(() {
      _isAiThinking = false;
      _statusText = "Bärbel spricht...";
      _isListening = false;
    });
    
    await _aiService.speak(text);
  }

  void _listenToUser() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      setState(() => _statusText = "Mikrofon-Zugriff verweigert");
      return;
    }

    bool available = await _speech.initialize(
      onError: (val) => setState(() => _isListening = false),
      onStatus: (val) {
        if (val == "listening") setState(() => _isListening = true);
        if (val == "notListening") setState(() => _isListening = false);
      }
    );

    if (available) {
      setState(() {
        _isListening = true;
        _statusText = "Ich höre dir zu...";
      });
      _speech.listen(
        localeId: "de_DE",
        onResult: (val) {
          if (val.finalResult && val.recognizedWords.isNotEmpty) {
            _sendToAi(val.recognizedWords);
          }
        },
      );
    } else {
      setState(() => _statusText = "Spracherkennung nicht bereit");
    }
  }

  void _sendToAi(String text) async {
    _speech.stop();
    setState(() {
      _isListening = false;
      _isAiThinking = true;
      _statusText = "Überlegt...";
    });
    final response = await _aiService.getResponse(text);
    _handleAiResponse(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.network(
                _isAiThinking 
                  ? "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJueXp4bmZ3bm96bmZ3bm96bmZ3/3o7bu3XilJ5BOiSGic/giphy.gif" 
                  : "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJueXp4bmZ3bm96bmZ3bm96bmZ3/l41lTfO6QJ0w8/giphy.gif",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.person, size: 100, color: Colors.white)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(_statusText, textAlign: TextAlign.center, style: TextStyle(color: _isListening ? Colors.greenAccent : Colors.white70, fontSize: 16)),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionBtn(
                        _isListening ? Icons.mic : Icons.mic_off, 
                        _isListening ? Colors.green : Colors.white24, 
                        () {
                          if (_isListening) {
                            _speech.stop();
                          } else {
                            _listenToUser();
                          }
                        }
                      ),
                      _actionBtn(Icons.call_end, Colors.red, () {
                        _aiService.stop();
                        _speech.stop();
                        Navigator.pop(context);
                      }),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: CircleAvatar(
        radius: 35,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}