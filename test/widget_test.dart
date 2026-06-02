import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/customer/screens/welcome_screen.dart';

void main() {
  testWidgets('Welcome screen UI renders correctly', (WidgetTester tester) async {
    // Build WelcomeScreen wrapped in MaterialApp
    await tester.pumpWidget(const MaterialApp(
      home: WelcomeScreen(),
    ));

    // Verify that the title and description are present
    expect(find.text("Sonnas"), findsOneWidget);
    expect(find.text("Cakes & desserts"), findsOneWidget);

    // Verify the buttons are rendered
    expect(find.text("ENTER PATISSERIE"), findsOneWidget);
    expect(find.text("Staff & Management Portal"), findsOneWidget);
  });
}
