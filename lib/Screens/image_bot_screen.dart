import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  // HuggingFace API
  final String _apiKey = "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";
  final String _apiUrl =
      "https://router.huggingface.co/hf-inference/models/stabilityai/stable-diffusion-xl-base-1.0";

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'ai',
      'text':
          'Hallo! Ich bin dein KI Image Bot.\nSchreibe einfach, was ich erstellen soll und ich erstelle das Bild für dich!',
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

  // -------------------------------
  // 🔥 رفع الصورة إلى Firebase
  // -------------------------------
  Future<String?> _uploadToFirebase(Uint8List bytes) async {
    try {
      final fileName = "ai_${DateTime.now().millisecondsSinceEpoch}.png";
      final ref =
          FirebaseStorage.instance.ref().child("chat_images/$fileName");

      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/png'),
      );

      return await ref.getDownloadURL();
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // -------------------------------
  // 🔥 توليد صورة من HuggingFace
  // -------------------------------
  Future<Uint8List?> _generateImage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"inputs": prompt}),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print("API error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("API network error: $e");
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

  // -------------------------------
  // 🔥 إرسال رسالة طلب صورة
  // -------------------------------
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
          _messages.add({
            'role': 'ai',
            'data': imageBytes,
            'type': 'image',
            'prompt': text,
          });
        } else {
          _messages.add({
            'role': 'ai',
            'text':
                "Fehler beim Laden. Falls 'Model is loading' erscheint, warte 30 Sekunden.",
            'type': 'text'
          });
        }
      });
      _scrollToBottom();
    }
  }

  // -------------------------------
  // UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ChatTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.pink[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text(
          "AI Image Generator",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // MESSAGES LIST
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
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? "Dein Prompt" : "Generiertes Bild",
                        style: TextStyle(
                            color: Colors.pink[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),

                      //
                      // IMAGE
                      //
                      if (isImage)
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(
                                msg['data'],
                                width: 300,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 🔥 زر Send to Chat
                            ElevatedButton.icon(
                              onPressed: () async {
                                final url =
                                    await _uploadToFirebase(msg['data']);

                                if (url != null) {
                                  Navigator.pop(context, url);
                                }
                              },
                              icon: const Icon(Icons.send),
                              label: const Text("Send to Chat"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
                        )
                      //
                      // TEXT
                      //
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? ChatTheme.myBubbleColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            msg['text'] ?? "",
                            style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // LOADING INDICATOR
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.pink)),
                  const SizedBox(width: 10),
                  Text(
                    "KI denkt nach...",
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  )
                ],
              ),
            ),

          // INPUT
          Container(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Beschreibe ein Bild...",
                        filled: true,
                        fillColor:
                            isDarkMode ? Colors.grey[800] : const Color(0xFFF2F2F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    backgroundColor: Colors.pink[700],
                    child: const Icon(Icons.brush_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}