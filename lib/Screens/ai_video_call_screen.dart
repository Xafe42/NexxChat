import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _AiVideoCallScreenState extends State<AiVideoCallScreen>
    with SingleTickerProviderStateMixin {
  final AiCompanionService _aiService = AiCompanionService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _isAiThinking = false;
  bool _isAiSpeaking = false;
  String _statusText = "Verbindung wird aufgebaut...";
  
  // Neutrale technische Audio-Visualisierungen
  final String _thinkingGif = "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJueXp4bmZ3bm96bmZ3bm96bmZ3/3o7bu3XilJ5BOiSGic/giphy.gif"; 
  final String _speakingGif = "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHNidXU1cWd6bmZ3bm96bmZ3bm96bmZ3/l41lTfO6QJ0w8/giphy.gif"; 
  final String _idleGif = "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM3Z0Z3R6bmZ3bm96bmZ3bm96bmZ3/3o7TKMGpxxXLy/giphy.gif"; 

  String _systemPrompt = "Du bist eine persönliche KI.";

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _loadPresetAndStart();
  }

  Future<void> _loadPresetAndStart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      _systemPrompt = data?['ai_prompt'] ?? "Du bist eine hilfreiche persönliche KI.";
    }

    _aiService.tts.setStartHandler(() {
      if (mounted) setState(() => _isAiSpeaking = true);
    });

    _aiService.tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isAiSpeaking = false);
        _listenToUser();
      }
    });

    await Future.delayed(const Duration(seconds: 1));
    
    // Begrüßung basierend auf Prompt
    String greeting = "System bereit. Wie kann ich dir behilflich sein?";
    if (_systemPrompt.contains("Freundin")) greeting = "Hallo! Schön, dass du anrufst.";
    if (_systemPrompt.contains("Coach")) greeting = "Bereit für das Training? Legen wir los.";
    
    _handleAiResponse(greeting);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _aiService.stop();
    _speech.stop();
    super.dispose();
  }

  void _handleAiResponse(String text) async {
    if (!mounted) return;
    setState(() {
      _isAiThinking = false;
      _statusText = "KI antwortet...";
      _isListening = false;
    });

    await _aiService.speak(text);
  }

  void _listenToUser() async {
    if (_isAiThinking || _isAiSpeaking) return;

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
        });

    if (available) {
      setState(() {
        _isListening = true;
        _statusText = "Ich höre zu...";
      });
      _speech.listen(
        localeId: "de_DE",
        onResult: (val) {
          if (val.finalResult && val.recognizedWords.isNotEmpty) {
            _sendToAi(val.recognizedWords);
          }
        },
      );
    }
  }

  void _sendToAi(String text) async {
    if (_isAiThinking) return; 
    
    _speech.stop();
    setState(() {
      _isListening = false;
      _isAiThinking = true;
      _statusText = "Verarbeitung...";
    });

    final response = await _aiService.getResponse(text, _systemPrompt);
    _handleAiResponse(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Visuelle Darstellung der Person
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                // Wenn die KI spricht, pulsiert das Bild leicht, um Aktivität zu zeigen
                double scale =
                    (_isAiSpeaking && !_isAiThinking)
                        ? 1.0 + (_pulseController.value * 0.05)
                        : 1.0;

                String displayUrl = _idleGif;
                if (_isAiThinking) displayUrl = _thinkingGif;
                if (_isAiSpeaking) displayUrl = _speakingGif;

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: 0.8,
                    child: Image.network(
                      displayUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.graphic_eq, size: 100, color: Colors.white24)),
                    ),
                  ),
                );
              },
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
                  const Text("Deine persönliche KI",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(_statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _isListening ? Colors.greenAccent : Colors.white70,
                          fontSize: 16)),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionBtn(_isListening ? Icons.mic : Icons.mic_off,
                          _isListening ? Colors.green : Colors.white24, () {
                        if (_isListening) {
                          _speech.stop();
                        } else {
                          _listenToUser();
                        }
                      }),
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