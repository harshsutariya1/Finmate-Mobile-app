import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/market_data.dart';
import 'package:finmate/providers/market_provider.dart';
import 'package:finmate/screens/home/market%20screens/market_detail_screen.dart';
import 'package:finmate/screens/home/market%20screens/market_search_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class MarketOverviewScreen extends ConsumerStatefulWidget {
  const MarketOverviewScreen({super.key});

  @override
  ConsumerState<MarketOverviewScreen> createState() => _MarketOverviewScreenState();
}

class _MarketOverviewScreenState extends ConsumerState<MarketOverviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final percentFormat = NumberFormat('+0.00%;-0.00%');
  
  final List<String> _tabs = [
    'Market Indices',
    'Popular Stocks',
    'Cryptocurrencies',
    'Commodities',
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
        title: const Text('Market Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigate().push(const MarketSearchScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshAllData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: color3,
          unselectedLabelColor: color2,
          indicatorColor: color3,
          indicatorWeight: 3.0,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarketIndicesTab(),
          _buildPopularStocksTab(),
          _buildCryptocurrenciesTab(),
          _buildCommoditiesTab(),
        ],
      ),
    );
  }
  
  void _refreshAllData() {
    ref.invalidate(marketIndicesProvider);
    ref.invalidate(popularStocksProvider);
    ref.invalidate(cryptocurrenciesProvider);
    ref.invalidate(commoditiesProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing market data...'))
    );
  }
  
  Widget _buildMarketIndicesTab() {
    final indicesAsync = ref.watch(marketIndicesProvider);
    
    return indicesAsync.when(
      data: (indices) => indices.isEmpty
          ? _buildEmptyState('No market indices available')
          : _buildListView(
              itemCount: indices.length,
              itemBuilder: (context, index) => _buildMarketIndexCard(indices[index]),
            ),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState('Error loading indices: $error'),
    );
  }
  
  Widget _buildPopularStocksTab() {
    final stocksAsync = ref.watch(popularStocksProvider);
    
    return stocksAsync.when(
      data: (stocks) => stocks.isEmpty
          ? _buildEmptyState('No stocks available')
          : _buildListView(
              itemCount: stocks.length,
              itemBuilder: (context, index) => _buildStockCard(stocks[index]),
            ),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState('Error loading stocks: $error'),
    );
  }
  
  Widget _buildCryptocurrenciesTab() {
    final cryptosAsync = ref.watch(cryptocurrenciesProvider);
    
    return cryptosAsync.when(
      data: (cryptos) => cryptos.isEmpty
          ? _buildEmptyState('No cryptocurrencies available')
          : _buildListView(
              itemCount: cryptos.length,
              itemBuilder: (context, index) => _buildCryptocurrencyCard(cryptos[index]),
            ),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState('Error loading cryptocurrencies: $error'),
    );
  }
  
  Widget _buildCommoditiesTab() {
    final commoditiesAsync = ref.watch(commoditiesProvider);
    
    return commoditiesAsync.when(
      data: (commodities) => commodities.isEmpty
          ? _buildEmptyState('No commodities available')
          : _buildListView(
              itemCount: commodities.length,
              itemBuilder: (context, index) => _buildCommodityCard(commodities[index]),
            ),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState('Error loading commodities: $error'),
    );
  }
  
  Widget _buildListView({required int itemCount, required Widget Function(BuildContext, int) itemBuilder}) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshAllData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
  
  Widget _buildEmptyState(String message) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshAllData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 3),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshAllData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color3,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }
  
  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 10,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshAllData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 3),
          Center(
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
                  'Failed to Load Market Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().contains('Alpha Vantage') 
                      ? 'API rate limit reached or invalid symbols. Please try again in a minute.'
                      : error,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshAllData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color3,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMarketIndexCard(MarketIndex index) {
    return _buildMarketEntityCard(
      onTap: () => Navigate().push(
        MarketDetailScreen(
          name: index.name,
          symbol: index.symbol,
          type: 'index',
        ),
      ),
      symbol: index.symbol,
      name: index.name,
      currentValue: index.currentValue,
      change: index.change,
      changePercentage: index.changePercentage,
      additionalInfo: index.type,
      leadingWidget: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color3.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.show_chart,
          size: 24,
          color: color3,
        ),
      ),
    );
  }
  
  Widget _buildStockCard(Stock stock) {
    return _buildMarketEntityCard(
      onTap: () => Navigate().push(
        MarketDetailScreen(
          name: stock.name,
          symbol: stock.symbol,
          type: 'stock',
        ),
      ),
      symbol: stock.symbol,
      name: stock.name,
      currentValue: stock.currentValue,
      change: stock.change,
      changePercentage: stock.changePercentage,
      additionalInfo: stock.sector,
      leadingWidget: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.business,
          size: 24,
          color: Colors.blue,
        ),
      ),
    );
  }
  
  Widget _buildCryptocurrencyCard(Cryptocurrency crypto) {
    return _buildMarketEntityCard(
      onTap: () => Navigate().push(
        MarketDetailScreen(
          name: crypto.name,
          symbol: crypto.symbol,
          type: 'crypto',
        ),
      ),
      symbol: crypto.symbol,
      name: crypto.name,
      currentValue: crypto.currentValue,
      change: crypto.change,
      changePercentage: crypto.changePercentage,
      additionalInfo: crypto.volume24h > 0 ? 'Vol: ${NumberFormat.compact().format(crypto.volume24h)}' : '',
      leadingWidget: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.currency_bitcoin,
          size: 24,
          color: Colors.amber,
        ),
      ),
    );
  }
  
  Widget _buildCommodityCard(Commodity commodity) {
    return _buildMarketEntityCard(
      onTap: () => Navigate().push(
        MarketDetailScreen(
          name: commodity.name,
          symbol: commodity.symbol,
          type: 'commodity',
        ),
      ),
      symbol: commodity.symbol,
      name: commodity.name,
      currentValue: commodity.currentValue,
      change: commodity.change,
      changePercentage: commodity.changePercentage,
      additionalInfo: 'Unit: ${commodity.unit}',
      leadingWidget: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getCommodityColor(commodity.name).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _getCommodityIcon(commodity.name),
      ),
    );
  }
  
  Widget _buildMarketEntityCard({
    required VoidCallback onTap,
    required String symbol,
    required String name,
    required double currentValue,
    required double change,
    required double changePercentage,
    String? additionalInfo,
    Widget? leadingWidget,
  }) {
    final isPositive = change >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color1,
                      ),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: color2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                    if (additionalInfo != null && additionalInfo.isNotEmpty)
                      Text(
                        additionalInfo,
                        style: TextStyle(
                          fontSize: 12,
                          color: color2.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(currentValue),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color1,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: changeColor,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${change.abs().toStringAsFixed(2)} (${changePercentage.abs().toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getCommodityColor(String name) {
    switch (name.toLowerCase()) {
      case 'gold':
        return Colors.amber.shade700;
      case 'silver':
        return Colors.blueGrey.shade200;
      case 'crude oil':
      case 'crude oil (brent)':
        return Colors.brown.shade700;
      default:
        return Colors.green;
    }
  }
  
  Widget _getCommodityIcon(String name) {
    IconData iconData;
    Color iconColor;
    
    switch (name.toLowerCase()) {
      case 'gold':
        iconData = Icons.monetization_on;
        iconColor = Colors.amber.shade700;
        break;
      case 'silver':
        iconData = Icons.brightness_medium;
        iconColor = Colors.blueGrey.shade200;
        break;
      case 'crude oil':
      case 'crude oil (brent)':
        iconData = Icons.local_gas_station;
        iconColor = Colors.brown.shade700;
        break;
      default:
        iconData = Icons.grain;
        iconColor = Colors.green;
    }
    
    return Icon(
      iconData,
      size: 24,
      color: iconColor,
    );
  }
}
