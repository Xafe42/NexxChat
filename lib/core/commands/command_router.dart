import '../models/chat_command.dart';

class CommandRouter {
  // Prüft, ob der eingegebene Text einem bekannten Kommando entspricht
  static ChatCommand? detect(String raw) {
    final t = raw.trimRight(); // Entfernt überflüssige Leerzeichen am Ende

    // Einfaches /hello Kommando → Vorschau "World"
    if (t == '/hello') {
      return ChatCommand(
        type: 'hello', // Kommando-Typ
        data: {'who': 'World'}, // Daten für die Ausführung
        previewText: '👋 Hello World from NexxChat!', // Vorschautext
      );
    }

    // /hello <name...> → Begrüßt die angegebene Person
    if (t.startsWith('/hello ')) {
      final after = t.substring(7); // Alles nach "/hello "
      if (after.isNotEmpty) {
        final who = after.split(' ').first; // Erstes Wort nach dem Befehl
        if (who.isNotEmpty) {
          return ChatCommand(
            type: 'hello',
            data: {'who': who}, // Name der Person
            previewText: '👋 Hello $who from NexxChat!', // Vorschau
          );
        }
      }
    }

    // Tetris
    if (t == '/tetris') {
      return ChatCommand(
        type: 'tetris',
        data: {},
        previewText: '🎮 Starte Tetris!',
      );
    }
      // event 
    if (t == '/event') {
      return ChatCommand(
        type: 'event',
        data: {},
        previewText: 'Create an event');
    }

    return null; // Kein bekanntes Kommando
  }
}
