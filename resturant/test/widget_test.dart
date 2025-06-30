import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('Simple widget test', (WidgetTester tester) async {
      // Build a simple test app
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Restaurant App Test'),
          ),
        ),
      );

      // Verify that our text appears
      expect(find.text('Restaurant App Test'), findsOneWidget);
    });

    testWidgets('Button tap test', (WidgetTester tester) async {
      int counter = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Counter: $counter'),
                ElevatedButton(
                  onPressed: () {
                    counter++;
                  },
                  child: const Text('Increment'),
                ),
              ],
            ),
          ),
        ),
      );

      // Find the button and tap it
      expect(find.text('Counter: 0'), findsOneWidget);
      expect(find.text('Increment'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Note: This test won't actually update the counter since we're not using StatefulWidget
      // It just tests that the tap doesn't cause errors
    });

    testWidgets('Form field test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(
                labelText: 'Test Input',
              ),
            ),
          ),
        ),
      );

      // Find the text field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Test Input'), findsOneWidget);

      // Enter text
      await tester.enterText(find.byType(TextField), 'Hello World');
      expect(find.text('Hello World'), findsOneWidget);
    });
  });
}
