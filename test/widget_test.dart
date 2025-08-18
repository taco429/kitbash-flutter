import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/main.dart';

void main() {
  testWidgets('App launches and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KitbashApp());

    // Verify that the app title is shown
    expect(find.text('Kitbash CCG'), findsOneWidget);
    expect(find.text('Welcome to Kitbash CCG'), findsOneWidget);

    // Verify that main buttons are present
    expect(find.text('Deck Builder'), findsOneWidget);
    expect(find.text('Find Games'), findsOneWidget);
  });
} 