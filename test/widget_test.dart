import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kitbash_flutter/main.dart';
import 'package:kitbash_flutter/services/game_service.dart';

class _FakeGameService extends GameService {
  @override
  Future<List<dynamic>> findGames() async => [];
}

void main() {
  testWidgets('App launches and shows title', (WidgetTester tester) async {
    // Build app with required providers
    await tester.pumpWidget(
      ChangeNotifierProvider<GameService>(
        create: (_) => _FakeGameService(),
        child: const KitbashApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the app title is shown
    expect(find.text('Kitbash CCG'), findsOneWidget);
    expect(find.text('Welcome to Kitbash CCG'), findsOneWidget);

    // Verify that main buttons are present
    expect(find.text('Deck Builder'), findsOneWidget);
    expect(find.text('Find Games'), findsOneWidget);
  });
}
