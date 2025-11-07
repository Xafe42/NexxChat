import '../models/chat_command.dart';

class CommandRouter {
  static ChatCommand? detect(String raw) {
    final value = raw;                
    final t = raw.trimRight();         
    // /hello → Preview "World"
    if (t == '/hello') {
      return ChatCommand(
        type: 'hello',
        data: {'who': 'World'},
        previewText: '👋 Hello World from NexxChat!',
      );
    }

    // /hello <name...>  
    if (t.startsWith('/hello ')) {
      final after = t.substring(7);
      if (after.isNotEmpty) {
        final who = after.split(' ').first;
        if (who.isNotEmpty) {
          return ChatCommand(
            type: 'hello',
            data: {'who': who},
            previewText: '👋 Hello $who from NexxChat!',
          );
        }
      }
    }

    
    return null;
  }
}
