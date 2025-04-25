import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/market_data.dart';
import 'package:finmate/providers/market_provider.dart';
import 'package:finmate/screens/home/market%20screens/market_detail_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class MarketSearchScreen extends ConsumerStatefulWidget {
  const MarketSearchScreen({super.key});

  @override
  ConsumerState<MarketSearchScreen> createState() => _MarketSearchScreenState();
}

class _MarketSearchScreenState extends ConsumerState<MarketSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  String _searchQuery = '';
  bool _isSearching = false;
  final logger = Logger();
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length >= 2) {
      // Only search if query is at least 2 characters
      setState(() {
        _searchQuery = query;
        _isSearching = true;
      });
      
      // Update the searchQueryProvider to trigger the search
      ref.read(searchQueryProvider.notifier).state = query;
    } else {
      setState(() {
        _isSearching = false;
      });
    }
  }
  
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
    ref.read(searchQueryProvider.notifier).state = '';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search stocks, crypto, indices...',
            hintStyle: TextStyle(color: color2.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          style: const TextStyle(color: color1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                setState(() {
                  _searchQuery = _searchController.text.trim();
                  _isSearching = true;
                });
                ref.read(searchQueryProvider.notifier).state = _searchQuery;
              }
            },
          ),
        ],
      ),
      body: _isSearching
          ? _buildSearchResults()
          : _buildSearchSuggestions(),
    );
  }
  
  Widget _buildSearchResults() {
    final searchResultsAsync = ref.watch(marketSearchProvider(_searchQuery));
    
    return searchResultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No results found for "$_searchQuery"',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) => _buildSearchResultCard(results[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        logger.e("Search error", error: error, stackTrace: stack);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error searching: $error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSearchSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Try searching for...',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color1,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildSuggestionChips([
            'NIFTY',
            'RELIANCE',
            'TCS',
            'BTC',
            'GOLD',
            'HDFC',
            'INFY',
          ]),
          const SizedBox(height: 24),
          const Text(
            'Popular categories',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color1,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryList(),
        ],
      ),
    );
  }
  
  Widget _buildSuggestionChips(List<String> suggestions) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: suggestions.map((suggestion) {
        return ActionChip(
          backgroundColor: color4,
          side: BorderSide(color: color3.withOpacity(0.3)),
          label: Text(suggestion),
          labelStyle: TextStyle(color: color3),
          onPressed: () {
            _searchController.text = suggestion;
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildCategoryList() {
    return Column(
      children: [
        _buildCategoryTile(
          'Indian Stocks',
          Icons.business,
          Colors.blue,
          ['.BSE', '.NS', 'RELIANCE', 'TCS', 'INFY'],
        ),
        _buildCategoryTile(
          'Market Indices',
          Icons.trending_up,
          color3,
          ['NIFTY', 'SENSEX', 'BSE', 'NSE'],
        ),
        _buildCategoryTile(
          'Cryptocurrencies',
          Icons.currency_bitcoin,
          Colors.amber,
          ['BTC', 'ETH', 'XRP', 'DOGE'],
        ),
        _buildCategoryTile(
          'Commodities',
          Icons.monetization_on,
          Colors.green,
          ['GOLD', 'SILVER', 'OIL', 'XAU'],
        ),
      ],
    );
  }
  
  Widget _buildCategoryTile(
      String title, IconData icon, Color color, List<String> searchTerms) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Show a bottom sheet with relevant search terms for this category
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Popular $title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: searchTerms.map((term) {
                      return ActionChip(
                        backgroundColor: color.withOpacity(0.1),
                        label: Text(term),
                        labelStyle: TextStyle(color: color),
                        onPressed: () {
                          Navigator.pop(context);
                          _searchController.text = term;
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSearchResultCard(MarketSearchResult result) {
    // Determine icon and color based on entity type
    IconData iconData;
    Color iconColor;
    
    switch (result.type) {
      case 'index':
        iconData = Icons.trending_up;
        iconColor = color3;
        break;
      case 'stock':
        iconData = Icons.business;
        iconColor = Colors.blue;
        break;
      case 'crypto':
        iconData = Icons.currency_bitcoin;
        iconColor = Colors.amber;
        break;
      case 'commodity':
        iconData = Icons.monetization_on;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.show_chart;
        iconColor = Colors.grey;
    }
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigate().push(
          MarketDetailScreen(
            name: result.name,
            symbol: result.symbol,
            type: result.type,
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.symbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color1,
                      ),
                    ),
                    Text(
                      result.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: color2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      result.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: color2.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (result.currentValue > 0) ...[
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(result.currentValue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    if (result.change != 0)
                      Row(
                        children: [
                          Icon(
                            result.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: result.isPositive ? Colors.green : Colors.red,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${result.changePercentage.abs().toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: result.isPositive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
