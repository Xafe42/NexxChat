import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexxchat_firebase/screens/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockUser extends Mock implements User {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  group('ChatScreen', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
    });

    testWidgets('renders input field and send button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ChatScreen()));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });

    testWidgets('typing /hello shows preview text', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ChatScreen()));

      final textField = find.byType(TextField);
      await tester.enterText(textField, '/hello Bob');
      await tester.pump();

      expect(find.text('👋 Hello Bob from NexxChat!'), findsOneWidget);
    });
  });
}
