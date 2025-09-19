// This is a basic Flutter widget test for Rastah app.

import 'package:flutter_test/flutter_test.dart';

import 'package:rastah/main.dart';

void main() {
  testWidgets('Rastah welcome screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(RastaApp());

    // Verify that our welcome screen loads with Urdu logo
    expect(find.text('رستہ'), findsOneWidget);
    expect(find.text('Rastah'), findsOneWidget);
    
    // Verify the start button exists
    expect(find.text('شروع کریں'), findsOneWidget);
    
    // Verify About Rastah link exists
    expect(find.text('About Rastah'), findsOneWidget);
  });
}