import 'package:flutter/material.dart';

import '../core/services/chat_theme.dart'; 

class ImageBotScreen extends StatefulWidget {
  static const String screenRoute = "image_bot_screen";
  const ImageBotScreen({super.key});

  @override
  State<ImageBotScreen> createState() => _ImageBotScreenState();
}

class _ImageBotScreenState extends State<ImageBotScreen> {
  // Controller für das Eingabefeld und die Scroll-Position der Liste
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Liste zur Speicherung des Chatverlaufs.
  // 'type' unterscheidet zwischen Textnachrichten ('text') und generierten Bildern ('image').
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': 'Hallo! Ich bin dein KI Image Bot.\nSchreibe einfach, was ich erstellen soll und ich erstelle das Bild für dich!',
      'type': 'text' 
    }
  ];

  bool _isLoading = false; // Status für den Ladeindikator

  @override
  void initState() {
    super.initState();
    _loadTheme(); // Lädt das gespeicherte App-Theme beim Start
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  // Erstellt die URL für die Pollinations.ai API
  String _generateImageUrl(String prompt) {
    // Kodiert den Eingabetext URL-konform
    final encodedPrompt = Uri.encodeComponent(prompt);

    // Baut die URL zusammen:
    // model=flux: Verwendet das Flux-Modell für die Generierung.
    // seed=...: Fügt einen Zeitstempel hinzu, um Caching zu verhindern und neue Bilder zu erzwingen.
    return "https://pollinations.ai/p/$encodedPrompt?width=800&height=800&seed=${DateTime.now().millisecondsSinceEpoch}&model=flux";
  }

  // Scrollt die Chat-Liste automatisch zur neuesten Nachricht
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

  // Verarbeitet das Senden einer Nachricht
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    // 1. Fügt die Benutzernachricht zur Liste hinzu und aktualisiert die UI
    setState(() {
      _messages.add({'role': 'user', 'text': text, 'type': 'text'});
      _isLoading = true;
    });
    _scrollToBottom();
    
    // Simuliert eine kurze Verzögerung für besseres Feedback
    await Future.delayed(const Duration(seconds: 1));
    
    // Generiert die Bild-URL basierend auf dem Text
    final imageUrl = _generateImageUrl(text);

    if (mounted) {
      setState(() {
        // Fügt die Antwort der KI als Bild-Typ hinzu
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
        backgroundColor: Colors.pink[800], 
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
                Icons.palette_rounded,
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
          // Chat-Verlauf
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['role'] == 'user';
                final isImage = msg['type'] == 'image'; // Prüft den Nachrichtentyp

                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Absender-Label
                      Text(
                        isMe ? "Dein Motiv" : "Generiertes Bild",
                        style: TextStyle(fontSize: 12, color: Colors.pink[800]),
                      ),
                      const SizedBox(height: 2),
                      
                      // Nachrichten-Bubble
                      Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(30),
                        color: isMe ? ChatTheme.myBubbleColor : Colors.white,
                        
                        child: Padding(
                          padding: isImage 
                              ? const EdgeInsets.all(5) 
                              : const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          
                          child: isImage
                              // Bild-Anzeige: Lädt das Bild asynchron über die URL
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.network(
                                    msg['text']!, // URL des Bildes
                                    width: 280,
                                    height: 280,
                                    fit: BoxFit.cover,
                                    
                                    // Zeigt einen Ladeindikator während des Downloads
                                    loadingBuilder: (ctx, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return SizedBox(
                                        width: 280, height: 280,
                                        child: Center(child: CircularProgressIndicator(color: Colors.pink)),
                                      );
                                    },
                                    // Fehlerbehandlung beim Laden
                                    errorBuilder: (ctx, err, stack) => Container(
                                       width: 280, height: 280,
                                       color: Colors.grey[300],
                                       child: const Column(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: [
                                           Icon(Icons.broken_image, color: Colors.grey, size: 50),
                                           Text("Fehler beim Laden", style: TextStyle(fontSize: 12)),
                                         ],
                                       ),
                                    ),
                                  ),
                                )
                              // Text-Anzeige
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

          // Ladeindikator (nur sichtbar während der Generierung)
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
                      const Text("Generiere Bild...", style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            ),

          // Eingabebereich
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