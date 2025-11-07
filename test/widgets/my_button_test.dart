import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexxchat_firebase/widgets/my_button.dart';

void main() {
  testWidgets('MyButton renders with correct text and color', (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyButton(
            color: Colors.blue,
            titel: 'Click Me',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    final buttonFinder = find.text('Click Me');
    expect(buttonFinder, findsOneWidget);

    await tester.tap(buttonFinder);
    expect(pressed, true);
  });
}
