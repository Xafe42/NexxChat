import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/chat_theme.dart';

class SupportBotScreen extends StatefulWidget {
  static const String screenRoute = "support_bot_screen";
  const SupportBotScreen({super.key});

  @override
  State<SupportBotScreen> createState() => _SupportBotScreenState();
}

class _SupportBotScreenState extends State<SupportBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': '👋 Hi!\nIch bin dein Support Bot.\nWie kann ich dir helfen?'
    }
  ];

  bool _isLoading = false;

  //Gemini Config
  static const String apiKey = 'AIzaSyAfv2px4R99wkA2gWgZB-moIuYTiJi9gAM';
  static const String model = 'gemini-2.5-flash-preview-09-2025';
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  //AI CALL
  Future<String> _fetchAiResponse() async {
    try {
      final history = _messages.map((msg) {
        return {
          'role': msg['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': msg['text']}
          ]
        };
      }).toList();

      final payload = {
        'contents': history,
        'systemInstruction': {
          'parts': [
            {
              'text':
                  'Du bist ein hilfreicher Support Bot. Antworte kurz, klar und hilfreich.'
            }
          ]
        }
      };

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['candidates']?[0]['content']?['parts']?[0]['text'] ??
            "Keine Antwort.";
      }
      return "⚠️ Fehler ${res.statusCode}";
    } catch (e) {
      return "🌐 Verbindungsfehler";
    }
  }

  //SEND 
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    _controller.clear();
    _scrollDown();

    final reply = await _fetchAiResponse();

    if (!mounted) return;

    setState(() {
      _messages.add({'role': 'ai', 'text': reply});
      _isLoading = false;
    });

    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ChatTheme.backgroundColor,

      //  APP BAR 
      appBar: AppBar(
        backgroundColor: ChatTheme.myBubbleColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: const [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.support_agent,
                  size: 18, color: Colors.black),
            ),
            SizedBox(width: 10),
            Text(
              "Support Bot",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // CHAT 
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isMe = msg['role'] == 'user';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.smart_toy,
                              size: 18, color: Colors.black),
                        ),
                      if (!isMe) const SizedBox(width: 8),

                      Flexible(
                        child: _bubble(
                          text: msg['text'] ?? "",
                          isMe: isMe,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // TYPING 
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 8),
              child: Row(
                children: const [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.smart_toy, size: 12),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Support Bot schreibt…",
                    style: TextStyle(
                        fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          //INPUT
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Schreibe eine Frage…",
                        filled: true,
                        fillColor:
                            isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ChatTheme.myBubbleColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BUBBLE
  Widget _bubble({
    required String text,
    required bool isMe,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe
            ? ChatTheme.myBubbleColor
            : (isDark ? Colors.grey[850] : Colors.white),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
      ),
    );
  }
}