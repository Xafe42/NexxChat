import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexxchat_firebase/screens/signin_screen.dart';

void main() {
  group('SignInScreen', () {
    testWidgets('renders email, password fields and sign in button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignInScreen()));

      expect(find.byType(TextField), findsNWidgets(2)); // email + password
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
