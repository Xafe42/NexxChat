import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexxchat_firebase/screens/registration_screen.dart';

void main() {
  group('RegistrationScreen', () {
    testWidgets('renders email, password fields and register button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: RegistrationScreen()));

      expect(find.byType(TextField), findsNWidgets(2)); // email + password
      expect(find.text('Register'), findsOneWidget);
    });
  });
}
