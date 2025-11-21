import 'package:flutter/material.dart';

import '../core/chat_theme.dart'; 

class ImageBotScreen extends StatefulWidget {
  static const String screenRoute = "image_bot_screen";
  const ImageBotScreen({super.key});

  @override
  State<ImageBotScreen> createState() => _ImageBotScreenState();
}

class _ImageBotScreenState extends State<ImageBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Startnachricht angepasst für den reinen Bild-Modus
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': 'Hallo! Ich bin dein KI Image Bot.\nSchreibe einfach, was ich erstellen soll und ich erstelle das Bild für dich!',
      'type': 'text' // Die Begrüßung bleibt Text
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

  // --- LOGIK: BILD URL ERSTELLEN (Pollinations.ai) ---
  String _generateImageUrl(String prompt) {
    // Encode den Prompt für die URL, damit Leerzeichen etc. funktionieren
    final encodedPrompt = Uri.encodeComponent(prompt);

    return "https://pollinations.ai/p/$encodedPrompt?width=800&height=800&seed=${DateTime.now().millisecondsSinceEpoch}&model=flux";
  }
  // --------------------------------------------------


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

    // 1. User Nachricht anzeigen (Das ist der Prompt als Text)
    setState(() {
      _messages.add({'role': 'user', 'text': text, 'type': 'text'});
      _isLoading = true;
    });
    _scrollToBottom();
    
    // Kurze künstliche Pause, damit es sich "arbeitend" anfühlt
    await Future.delayed(const Duration(seconds: 1));
    
    final imageUrl = _generateImageUrl(text);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'ai', 'text': imageUrl, 'type': 'image'});
        _isLoading = false;
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
        backgroundColor: Colors.pink[800], // Andere Farbe für den Bild-Bot (Pink/Magenta)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.palette_rounded, // Maler-Palette Icon statt Roboter
                color: Colors.pink,    
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "AI Image Generator",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
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
                // Prüfen, ob die Nachricht ein Bild sein soll
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
                        
                        // --- INHALT DER BUBBLE ---
                        child: Padding(
                          padding: isImage 
                              ? const EdgeInsets.all(5) // Weniger Padding bei Bildern
                              : const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          child: isImage
                              // A) BILD ANZEIGEN (Wenn Typ 'image')
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.network(
                                    msg['text']!, // Hier steht die URL drin
                                    // Größere Darstellung für Bilder
                                    width: 280,
                                    height: 280,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (ctx, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      // Lade-Kringel während das Bild aus dem Netz kommt
                                      return SizedBox(
                                        width: 280, height: 280,
                                        child: Center(child: CircularProgressIndicator(color: Colors.pink)),
                                      );
                                    },
                                    errorBuilder: (ctx, err, stack) => Container(
                                       width: 280, height: 280,
                                       color: Colors.grey[300],
                                       child: const Column(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: [
                                           Icon(Icons.broken_image, color: Colors.grey, size: 50),
                                           Text("Bild konnte nicht geladen werden", style: TextStyle(fontSize: 12)),
                                         ],
                                       ),
                                    ),
                                  ),
                                )
                              // B) TEXT ANZEIGEN (Nur für User-Nachrichten & Begrüßung)
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
                      const Text("Malt gerade...", style: TextStyle(color: Colors.black54)),
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
                  border: Border(
                    top: BorderSide(color: Colors.pink.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: "Schreib hier was ich für ein Bild generieren soll",
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
                      elevation: 2,
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