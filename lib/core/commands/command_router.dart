import '../models/chat_command.dart';

class CommandRouter {
  // Checks if the entered text corresponds to a known command
  static ChatCommand? detect(String raw) {
    final t = raw.trimRight(); // Removes trailing whitespace

    // Einfaches /hello Kommando → Vorschau "World"
    if (t == '/hello') {
      return ChatCommand(
        type: 'hello', // Command type
        data: {'who': 'World'}, // Data for execution
        previewText: '👋 Hello World from NexxChat!', // Preview text
      );
    }

    // /hello <name...> → Greets the specified person
    if (t.startsWith('/hello ')) {
      final after = t.substring(7).trim(); // Everything after "/hello "
      if (after.isNotEmpty) {
        final who = after.split(' ').first; // First word after the command
        if (who.isNotEmpty) {
          return ChatCommand(
            type: 'hello',
            data: {'who': who}, // Name of the person
            previewText: '👋 Hello $who from NexxChat!', // Preview
          );
        }
      }
    }

    // Tetris
    if (t == '/tetris') {
      return ChatCommand(
        type: 'tetris',
        data: {},
      );
    }
      // event 
    if (t == '/event') {
      return ChatCommand(
        type: 'event',
        data: {},
        previewText: 'Create an event');
    }

    // AI-Befehl: Erfordert '/ai ' gefolgt von einem nicht-leeren Prompt
    if (t.startsWith("/ai ")) {
      final prompt = t.substring(4).trim();
      if (prompt.isNotEmpty) {
        return ChatCommand(
          type: "ai",
          data: {"prompt": prompt},
          previewText: null, // keine Vorschau
        );
      }
    }


    return null; // No known command
  }
}