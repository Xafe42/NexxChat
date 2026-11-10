import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

import '../core/services/chat_theme.dart'; 

class ImageBotScreen extends StatefulWidget {
  static const String screenRoute = "image_bot_screen";
  const ImageBotScreen({super.key});

  @override
  State<ImageBotScreen> createState() => _ImageBotScreenState();
}

class _ImageBotScreenState extends State<ImageBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();


  final String _apiKey = ApiConfig.huggingFaceToken; 
  
  final String _apiUrl = "https://router.huggingface.co/hf-inference/models/stabilityai/stable-diffusion-xl-base-1.0";

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'ai',
      'text': 'Hallo! Ich bin dein KI Image Bot.\nSchreibe einfach, was ich erstellen soll und ich erstelle das Bild für dich!',
      'type': 'text' 
    }
  ];

  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _loadTheme(); 
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  Future<Uint8List?> _generateImage(String prompt) async {
    try {
      print("Sende Anfrage an Hugging Face Router (SDXL Base)...");
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"inputs": prompt}),
      );

      if (response.statusCode == 200) {
        print("Bild erfolgreich geladen!");
        return response.bodyBytes;
      } else {
        print("Fehler API: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Fehler Netzwerk: $e");
      return null;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text, 'type': 'text'});
      _isLoading = true;
    });
    _scrollToBottom();
    
    final imageBytes = await _generateImage(text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (imageBytes != null) {
          _messages.add({'role': 'ai', 'data': imageBytes, 'type': 'image'});
        } else {
          // Fehlerbehandlung für den User sichtbar machen
          _messages.add({
            'role': 'ai', 
            'text': 'Fehler beim Laden. Wenn du "Model is loading" in der Konsole siehst, warte bitte 30 Sekunden und versuche es erneut.', 
            'type': 'text'
          });
        }
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ChatTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.pink[800], 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          "AI Image Generator",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['role'] == 'user';
                final isImage = msg['type'] == 'image'; 

                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? "Dein Motiv" : "Generiertes Bild",
                        style: TextStyle(fontSize: 12, color: Colors.pink[800]),
                      ),
                      const SizedBox(height: 2),
                      Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(30),
                        color: isMe ? ChatTheme.myBubbleColor : Colors.white,
                        child: Padding(
                          padding: isImage 
                              ? const EdgeInsets.all(5) 
                              : const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          child: isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.memory(
                                    msg['data'] as Uint8List,
                                    width: 280,
                                    height: 280,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 280, height: 280,
                                        color: Colors.grey[300],
                                        child: const Center(child: Icon(Icons.error)),
                                      );
                                    },
                                  ),
                                )
                              : Text(
                                  msg['text'] ?? "",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink)),
                      const SizedBox(width: 10),
                      const Text("KI denkt nach...", style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            ),
          Container(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.pink.shade200, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: "Beschreibe ein Bild...",
                          hintStyle: TextStyle(color: isDarkMode ? Colors.grey : Colors.black54),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : const Color(0xFFF2F2F2),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      backgroundColor: ChatTheme.myBubbleColor,
                      child: const Icon(Icons.brush_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}