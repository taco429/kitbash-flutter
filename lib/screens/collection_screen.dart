import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/card_service.dart';
import '../services/deck_service.dart';
import '../models/card.dart';
import '../widgets/card_widget.dart';

/// Screen for viewing the card collection and deck contents
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Collection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Cards', icon: Icon(Icons.collections)),
            Tab(text: 'Red Deck', icon: Icon(Icons.local_fire_department)),
            Tab(text: 'Purple Deck', icon: Icon(Icons.auto_awesome)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllCardsTab(),
          _buildDeckTab('red_deck_001'),
          _buildDeckTab('purple_deck_001'),
        ],
      ),
    );
  }

  Widget _buildAllCardsTab() {
    return Consumer<CardService>(
      builder: (context, cardService, child) {
        // Handle loading state
        if (cardService.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading cards from server...'),
              ],
            ),
          );
        }
        
        // Handle error state
        if (cardService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load cards',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  cardService.error ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => cardService.refreshCards(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final allCards = cardService.allCards;
        
        if (allCards.isEmpty) {
          return const Center(
            child: Text('No cards available'),
          );
        }

        return Column(
          children: [
            // Collection stats
            Container(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collection Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Total Cards: ${cardService.totalCards}'),
                      Text('Red Cards: ${cardService.redCards.length}'),
                      Text('Purple Cards: ${cardService.purpleCards.length}'),
                      Text('Unit Cards: ${cardService.getCardsByType(CardType.unit).length}'),
                      Text('Spell Cards: ${cardService.getCardsByType(CardType.spell).length}'),
                    ],
                  ),
                ),
              ),
            ),
            
            // Cards grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: allCards.length,
                  itemBuilder: (context, index) {
                    final card = allCards[index];
                    return CardWidget(
                      card: card,
                      onTap: () => _showCardDetails(context, card),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeckTab(String deckId) {
    return Consumer<DeckService>(
      builder: (context, deckService, child) {
        // Handle loading state
        if (deckService.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading decks from server...'),
              ],
            ),
          );
        }
        
        // Handle error state
        if (deckService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load decks',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  deckService.error ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => deckService.loadDecks(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final deck = deckService.availableDecks
            .where((d) => d.id == deckId)
            .isNotEmpty 
            ? deckService.availableDecks.where((d) => d.id == deckId).first
            : null;
            
        if (deck == null) {
          return const Center(
            child: Text('Deck not found'),
          );
        }

        return Column(
          children: [
            // Deck info
            Container(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deck.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: deck.color == 'red' 
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${deck.color.toUpperCase()} DECK',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                                              color: deck.color == 'red' 
                                  ? Colors.red.shade700
                                  : Colors.purple.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${deck.cardCount} cards',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Deck cards
            Expanded(
              child: deck.allCards.isEmpty
                  ? const Center(child: Text('No cards in deck'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: deck.allCards.length,
                      itemBuilder: (context, index) {
                        final deckCard = deck.allCards[index];
                        return Card(
                          child: ListTile(
                            leading: SizedBox(
                              width: 60,
                              child: CardWidget(
                                card: deckCard.card,
                                isCompact: true,
                              ),
                            ),
                            title: Text(deckCard.card.name),
                            subtitle: Text(
                              '${deckCard.card.description}\n'
                              'Gold: ${deckCard.card.goldCost} | Mana: ${deckCard.card.manaCost} | '
                              '${deckCard.card.type.displayName}',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'x${deckCard.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap: () => _showCardDetails(context, deckCard.card),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showCardDetails(BuildContext context, GameCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardWidget(card: card),
            const SizedBox(height: 16),
            Text('Gold Cost: ${card.goldCost}'),
            Text('Mana Cost: ${card.manaCost}'),
            Text('Type: ${card.type.displayName}'),
            Text('Color: ${card.color.displayName}'),
            if (card.isUnit && card.unitStats != null) ...[
              Text('Attack: ${card.unitStats!.attack}'),
              Text('Health: ${card.unitStats!.health}'),
              Text('Armor: ${card.unitStats!.armor}'),
              Text('Speed: ${card.unitStats!.speed}'),
              Text('Range: ${card.unitStats!.range}'),
            ],
            if (card.isSpell && card.spellEffect != null) ...[
              Text('Target: ${card.spellEffect!.targetType}'),
              Text('Effect: ${card.spellEffect!.effect}'),
            ],
            if (card.abilities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Abilities: ${card.abilities.join(', ')}'),
            ],
            if (card.flavorText != null) ...[
              const SizedBox(height: 8),
              Text(
                card.flavorText!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}