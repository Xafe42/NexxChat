import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexxchat_firebase/screens/Welcome_Screen.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('renders welcome text and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: WelcomeScreen()));

      expect(find.text('Welcome to NexxChat'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });
  });
}
