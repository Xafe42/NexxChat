import 'package:flutter_test/flutter_test.dart';
import 'package:nexxchat_firebase/core/commands/command_router.dart';
import 'package:nexxchat_firebase/core/models/chat_command.dart';

void main() {
  group('CommandRouter.detect', () {
    test('detects /hello correctly', () {
      final result = CommandRouter.detect('/hello');

      // Prüfen, ob ein ChatCommand zurückkommt
      expect(result, isA<ChatCommand>());

      // Inhalt prüfen
      expect(result?.type, 'hello');
      expect(result?.data['who'], 'World');
      expect(result?.previewText, '👋 Hello World from NexxChat!');
    });

    test('detects /hello <name> correctly', () {
      final result = CommandRouter.detect('/hello Alice');

      expect(result, isA<ChatCommand>());
      expect(result?.type, 'hello');
      expect(result?.data['who'], 'Alice');
      expect(result?.previewText, '👋 Hello Alice from NexxChat!');
    });

    test('returns null for unknown commands', () {
      final result = CommandRouter.detect('/unknown');

      expect(result, null);
    });

    test('returns null for empty string', () {
      final result = CommandRouter.detect('');

      expect(result, null);
    });

    test('trims trailing spaces', () {
      final result = CommandRouter.detect('/hello    ');

      expect(result, isA<ChatCommand>());
      expect(result?.data['who'], 'World');
    });
  });
}
