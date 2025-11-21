import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/chat_theme.dart'; 

class SupportBotScreen extends StatefulWidget {
  static const String screenRoute = "support_bot_screen";
  const SupportBotScreen({super.key});

  @override
  State<SupportBotScreen> createState() => _SupportBotScreenState();
}

class _SupportBotScreenState extends State<SupportBotScreen> {
  // Controller für das Textfeld und das automatische Scrollen
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); 

  // Liste der Chat-Nachrichten. Hier wird der Verlauf gespeichert.
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Hallo! Ich bin dein Support Bot. Wie kann ich helfen?'}
  ];
  
  bool _isLoading = false; // Zeigt an, ob die KI gerade "denkt"

  // --- API KONFIGURATION ---
  // Hier werden die Schlüssel und die URL für Gemini definiert
  static const String apiKey = 'AIzaSyAfv2px4R99wkA2gWgZB-moIuYTiJi9gAM'; 
  static const String geminiModel = 'gemini-2.5-flash-preview-09-2025';
  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$apiKey';

  // --- THEME LOGIK ---
  // Lädt beim Start die gespeicherten Farben aus dem Speicher
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

  // --- GEMINI KI LOGIK ---
  // Diese Funktion sendet den Chatverlauf an Google und holt die Antwort
  Future<String> _fetchAiResponse() async {
    try {
      // 1. Verlauf für die API formatieren (User & Model Rollen)
      List<Map<String, dynamic>> apiHistory = _messages.map((msg) {
        return {
          'role': msg['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': msg['text']}
          ]
        };
      }).toList();

      // 2. Datenpaket schnüren (Verlauf + Systemanweisung)
      final payload = {
        'contents': apiHistory,
        'systemInstruction': {
          'parts': [{'text': "Du bist ein hilfreicher Bot der alle Fragen zu Themen knapp und Hilfreich beantwortet."}],
        },
      };

      // 3. Anfrage an den Google Server senden
      final response = await http.post(
        Uri.parse(geminiApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // 4. Antwort auswerten
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Den Text aus der verschachtelten JSON-Antwort herausfischen
        return result['candidates']?[0]['content']?['parts']?[0]['text'] ?? "Keine Antwort.";
      }
      return "Fehler: ${response.statusCode}";
    } catch (e) {
      return "Verbindungsfehler: $e";
    }
  }

  // Scrollt die Liste automatisch ganz nach unten
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

  // Wird ausgeführt, wenn der Senden-Button gedrückt wird
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 1. Eigene Nachricht anzeigen & Ladezustand aktivieren
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // 2. Auf Antwort der KI warten
    final response = await _fetchAiResponse();

    // 3. Antwort anzeigen & Ladezustand beenden
    if (mounted) {
      setState(() {
        _messages.add({'role': 'ai', 'text': response});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Hintergrundfarbe wird aus den Chat-Einstellungen geladen
      backgroundColor: ChatTheme.backgroundColor,
      
      // --- APP BAR ---
      // Spezielles Design für den Support Bot (Orange/Gelb)
      appBar: AppBar(
        backgroundColor: Colors.yellow[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Das Roboter-Logo im Kreis
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.purple,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Support Bot",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      
      // --- HAUPTINHALT ---
      body: Column(
        children: [
          // 1. Die Liste der Nachrichten
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['role'] == 'user';
                
                // Bubble Design
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    // Nachricht rechts (User) oder links (Bot) ausrichten
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? "Du" : "Support Bot",
                        style: TextStyle(fontSize: 12, color: Colors.yellow[900]),
                      ),
                      const SizedBox(height: 2),
                      Material(
                        elevation: 5,
                        // Runde Ecken anpassen je nach Sender
                        borderRadius: isMe
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              )
                            : const BorderRadius.only(
                                topRight: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                        // Farbe aus Theme laden
                        color: isMe ? ChatTheme.myBubbleColor : Colors.white,
                        
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          child: Text(
                            msg['text'] ?? "",
                            style: TextStyle(
                              fontSize: 15,
                              color: isMe ? Colors.white : Colors.black54,
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

          // 2. Lade-Indikator ("Schreibt...")
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("Schreibt...", style: TextStyle(color: Colors.grey)),
                ),
              ),
            ),

          // 3. Eingabefeld unten
          Container(
            // Passt Hintergrundfarbe an Dark Mode an
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, 
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    // Das Textfeld
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: "Frag mich was du möchtest",
                          hintStyle: TextStyle(color: isDarkMode ? Colors.grey : Colors.black54),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : const Color(0xFFF0F0F0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Senden Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChatTheme.myBubbleColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        "Senden",
                        style: TextStyle(color: Colors.white),
                      ),
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