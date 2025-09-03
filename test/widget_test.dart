import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kitbash_flutter/main.dart';
import 'package:kitbash_flutter/services/game_service.dart';
import 'package:kitbash_flutter/services/deck_service.dart';
import 'package:kitbash_flutter/services/card_service.dart';
import 'package:kitbash_flutter/models/deck.dart';
import 'package:kitbash_flutter/models/card.dart';

class _FakeGameService extends GameService {
  @override
  Future<List<dynamic>> findGames() async => [];
}

class _FakeCardService extends CardService {
  final Map<String, GameCard> _fakeCards = {};
  
  _FakeCardService() {
    // Add some fake cards for testing
    _fakeCards['test_card_1'] = const GameCard(
      id: 'test_card_1',
      name: 'Test Card',
      description: 'Test description',
      goldCost: 1,
      manaCost: 0,
      type: CardType.unit,
      color: CardColor.red,
    );
  }
  
  @override
  List<GameCard> get allCards => _fakeCards.values.toList();
  
  @override
  bool get isLoading => false;
  
  @override
  String? get error => null;
  
  @override
  int get totalCards => _fakeCards.length;
  
  @override
  List<GameCard> get redCards => [];
  
  @override
  List<GameCard> get purpleCards => [];
  
  @override
  List<GameCard> get unitCards => [];
  
  @override
  List<GameCard> get spellCards => [];
  
  @override
  Future<void> refreshCards() async {}
}

class _FakeDeckService extends DeckService {
  final List<Deck> _fakeDecks = [
    Deck(
      id: 'test_deck_1',
      name: 'Test Deck',
      color: 'red',
      description: 'Test deck description',
    ),
  ];
  
  @override
  List<Deck> get availableDecks => _fakeDecks;
  
  @override
  Deck? get selectedDeck => _fakeDecks.first;
  
  @override
  bool get isLoading => false;
  
  @override
  String? get error => null;
  
  @override
  Future<void> loadDecks() async {}
}

void main() {
  testWidgets('App launches and shows title', (WidgetTester tester) async {
    // Build app with required providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameService>(
            create: (_) => _FakeGameService(),
          ),
          ChangeNotifierProvider<CardService>(
            create: (_) => _FakeCardService(),
          ),
          ChangeNotifierProvider<DeckService>(
            create: (_) => _FakeDeckService(),
          ),
        ],
        child: const KitbashApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the app title is shown in the AppBar
    expect(find.text('Kitbash CCG'), findsOneWidget);

    // Verify that main buttons are present
    expect(find.text('Create Game'), findsOneWidget);
    expect(find.text('Play vs CPU'), findsOneWidget);
    expect(find.text('View Collection'), findsOneWidget);
    expect(find.text('Find Games'), findsOneWidget);

    // Verify deck selector is present
    expect(find.text('Select Your Deck'), findsOneWidget);
  });
}
