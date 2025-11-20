import 'package:flutter/material.dart';

import '../core/chat_theme.dart'; // WICHTIG: Importiere deine existierende ChatTheme Datei

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Immer weiß, da Dark Mode weg ist
      appBar: AppBar(
        title: const Text(
          "Einstellungen",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Überschrift
          const Text(
            "Allgemein",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),

          // Personalisierung Karte
          Card(
            elevation: 0,
            color: Colors.grey[100],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette, color: Colors.orange),
                  title: const Text("Personalisierung"),
                  subtitle: const Text("Chat Hintergrund & Farben anpassen"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    // Öffnet das Design-Menü
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatDesignScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Info Bereich (Optional, sieht aber besser aus wenn nicht leer)
          const Text(
            "Info",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            color: Colors.grey[100],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Icons.info_outline, color: Colors.black54),
              title: Text("App Version"),
              trailing: Text("1.0.0", style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- DER SCREEN ZUM FARBEN EINSTELLEN ---
class ChatDesignScreen extends StatefulWidget {
  const ChatDesignScreen({super.key});

  @override
  State<ChatDesignScreen> createState() => _ChatDesignScreenState();
}

class _ChatDesignScreenState extends State<ChatDesignScreen> {
  
  // Farben für Blasen
  final List<Color> bubbleColors = [
    Colors.blue[800]!, Colors.purple, Colors.orange[800]!, Colors.green[700]!,
    Colors.redAccent, Colors.black87, Colors.teal, Colors.pink,
  ];

  // Farben für Hintergrund
  final List<Color> bgColors = [
    Colors.white, 
    const Color(0xFFF5F5F5), // Hellgrau
    const Color(0xFFE3F2FD), // Hellblau
    const Color(0xFFF3E5F5), // Helllila
    const Color(0xFFFFF3E0), // Hellorange
    const Color(0xFFE8F5E9), // Hellgrün
    const Color(0xFF212121), // Dark Grey
    Colors.black, 
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  void _loadCurrentTheme() async {
    // Lädt die aktuellen Farben, damit die Vorschau stimmt
    await ChatTheme.loadTheme();
    if (mounted) setState(() {});
  }

  void _updateTheme(Color bubble, Color bg) {
    // Speichert die Farben global in deiner ChatTheme Klasse
    ChatTheme.saveTheme(bubble, bg);
    
    // UI aktualisieren (Vorschau)
    setState(() {});
    
    // Feedback für den User
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Design gespeichert!"), 
        duration: Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Design", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- VORSCHAU BEREICH ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ChatTheme.backgroundColor, // Zeigt live den Hintergrund
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                // Beispiel Nachricht von anderen
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
                    ),
                    child: const Text("Wie findest du das neue Design?", style: TextStyle(color: Colors.black87)),
                  ),
                ),
                const SizedBox(height: 10),
                // Beispiel Nachricht von DIR (in gewählter Farbe)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ChatTheme.myBubbleColor, // Zeigt live die Blasenfarbe
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)],
                    ),
                    child: const Text("Das sieht klasse aus!", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // --- FARBWAHL NACHRICHTEN ---
          const Text("Nachrichten Farbe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: bubbleColors.length,
              itemBuilder: (context, index) {
                final color = bubbleColors[index];
                final isSelected = ChatTheme.myBubbleColor.value == color.value;
                
                return GestureDetector(
                  onTap: () => _updateTheme(color, ChatTheme.backgroundColor),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: color, 
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          // --- FARBWAHL HINTERGRUND ---
          const Text("Hintergrund", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: bgColors.length,
              itemBuilder: (context, index) {
                final color = bgColors[index];
                final isSelected = ChatTheme.backgroundColor.value == color.value;
                bool isDark = color.computeLuminance() < 0.5;
                
                return GestureDetector(
                  onTap: () => _updateTheme(ChatTheme.myBubbleColor, color),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: color, 
                      shape: BoxShape.circle, 
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: isSelected ? Icon(Icons.check, color: isDark ? Colors.white : Colors.black) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}