import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/market_data.dart';
import 'package:finmate/providers/market_provider.dart';
import 'package:finmate/screens/home/market%20screens/market_detail_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MarketOverviewScreen extends ConsumerStatefulWidget {
  const MarketOverviewScreen({super.key});

  @override
  ConsumerState<MarketOverviewScreen> createState() => _MarketOverviewScreenState();
}

class _MarketOverviewScreenState extends ConsumerState<MarketOverviewScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final percentFormat = NumberFormat('+0.00%;-0.00%');
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(stockSearchQueryProvider.notifier).state = _searchController.text;
      setState(() {
        _showSearchResults = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
        title: const Text(
          'Market Overview',
          style: TextStyle(fontWeight: FontWeight.bold, color: color1),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _showSearchResults
                ? _buildSearchResults()
                : _buildMarketOverview(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search stocks, indices...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _showSearchResults = false;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ref.watch(stockSearchResultsProvider).when(
          data: (stocks) => stocks.isEmpty
              ? Center(
                  child: Text(
                    'No results found for "${_searchController.text}"',
                    style: TextStyle(color: color2),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: stocks.length,
                  itemBuilder: (context, index) => _buildStockListItem(stocks[index]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Error searching stocks: $error',
              style: TextStyle(color: color2),
            ),
          ),
        );
  }

  Widget _buildMarketOverview() {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(marketIndicesProvider);
        ref.invalidate(popularStocksProvider);
        ref.invalidate(cryptocurrenciesProvider);
        ref.invalidate(commoditiesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildMarketIndicesSection(),
          sbh20,
          _buildPopularStocksSection(),
          sbh20,
          _buildCryptocurrenciesSection(),
          sbh20,
          _buildCommoditiesSection(),
        ],
      ),
    );
  }

  Widget _buildMarketIndicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Indices',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color1,
          ),
        ),
        sbh10,
        ref.watch(marketIndicesProvider).when(
              data: (indices) => Column(
                children: indices.map((index) => _buildIndexCard(index)).toList(),
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Center(
                child: Text('Error loading market indices: $error'),
              ),
            ),
      ],
    );
  }

  Widget _buildIndexCard(MarketIndex index) {
    return GestureDetector(
      onTap: () => Navigate().push(
        MarketDetailScreen(
          name: index.name,
          symbol: index.symbol,
          type: 'index',
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      index.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    Text(
                      index.symbol,
                      style: TextStyle(
                        fontSize: 14,
                        color: color2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(index.currentValue).replaceAll('.00', ''),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          index.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: index.isPositive ? Colors.green : Colors.red,
                        ),
                        Text(
                          '${index.changePercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: index.isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                height: 40,
                child: _buildMiniChart(index.historicalData, index.isPositive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularStocksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Stocks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color1,
          ),
        ),
        sbh10,
        ref.watch(popularStocksProvider).when(
              data: (stocks) => Column(
                children: stocks.map((stock) => _buildStockListItem(stock)).toList(),
              ),
              loading: () => const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Center(
                child: Text('Error loading popular stocks: $error'),
              ),
            ),
      ],
    );
  }

  Widget _buildStockListItem(Stock stock) {
    return GestureDetector(
      onTap: () => Navigate().push(
        MarketDetailScreen(
          name: stock.name,
          symbol: stock.symbol,
          type: 'stock',
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: stock.companyLogo.isNotEmpty
                    ? Image.network(
                        stock.companyLogo,
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.business,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.business,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    Text(
                      stock.symbol,
                      style: TextStyle(
                        fontSize: 14,
                        color: color2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(stock.currentPrice),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          stock.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: stock.isPositive ? Colors.green : Colors.red,
                        ),
                        Text(
                          '${stock.changePercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: stock.isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                height: 40,
                child: _buildMiniChart(stock.historicalData, stock.isPositive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCryptocurrenciesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cryptocurrencies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color1,
          ),
        ),
        sbh10,
        ref.watch(cryptocurrenciesProvider).when(
              data: (cryptos) => Column(
                children: cryptos.map((crypto) => _buildCryptoCard(crypto)).toList(),
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Center(
                child: Text('Error loading cryptocurrencies: $error'),
              ),
            ),
      ],
    );
  }

  Widget _buildCryptoCard(Cryptocurrency crypto) {
    return GestureDetector(
      onTap: () => Navigate().push(
        MarketDetailScreen(
          name: crypto.name,
          symbol: crypto.symbol,
          type: 'crypto',
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: crypto.image.isNotEmpty
                    ? Image.network(
                        crypto.image,
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.currency_bitcoin,
                          size: 40,
                          color: Colors.amber,
                        ),
                      )
                    : const Icon(
                        Icons.currency_bitcoin,
                        size: 40,
                        color: Colors.amber,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crypto.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    Text(
                      crypto.symbol,
                      style: TextStyle(
                        fontSize: 14,
                        color: color2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(crypto.currentPrice),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          crypto.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: crypto.isPositive ? Colors.green : Colors.red,
                        ),
                        Text(
                          '${crypto.changePercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: crypto.isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                height: 40,
                child: _buildMiniChart(crypto.historicalData, crypto.isPositive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommoditiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commodities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color1,
          ),
        ),
        sbh10,
        ref.watch(commoditiesProvider).when(
              data: (commodities) => Column(
                children: commodities.map((commodity) => _buildCommodityCard(commodity)).toList(),
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Center(
                child: Text('Error loading commodities: $error'),
              ),
            ),
      ],
    );
  }

  Widget _buildCommodityCard(Commodity commodity) {
    return GestureDetector(
      onTap: () => Navigate().push(
        MarketDetailScreen(
          name: commodity.name,
          symbol: commodity.symbol,
          type: 'commodity',
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getCommodityIcon(commodity.name),
                size: 40,
                color: _getCommodityColor(commodity.name),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commodity.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    Text(
                      'per ${commodity.unit}',
                      style: TextStyle(
                        fontSize: 14,
                        color: color2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(commodity.currentPrice),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          commodity.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: commodity.isPositive ? Colors.green : Colors.red,
                        ),
                        Text(
                          '${commodity.changePercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: commodity.isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                height: 40,
                child: _buildMiniChart(commodity.historicalData, commodity.isPositive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChart(List<ChartDataPoint> data, bool isPositive) {
    if (data.isEmpty) {
      return const SizedBox();
    }

    // Calculate min and max values
    final List<double> values = data.map((point) => point.value).toList();
    final double minValue = values.reduce((a, b) => a < b ? a : b);
    final double maxValue = values.reduce((a, b) => a > b ? a : b);

    final Color chartColor = isPositive ? Colors.green : Colors.red;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minValue * 0.99,
        maxY: maxValue * 1.01,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (index) => FlSpot(index.toDouble(), data[index].value),
            ),
            isCurved: true,
            barWidth: 2,
            color: chartColor,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCommodityIcon(String name) {
    switch (name.toLowerCase()) {
      case 'gold':
        return Icons.monetization_on;
      case 'silver':
        return Icons.brightness_medium;
      case 'crude oil':
        return Icons.local_gas_station;
      default:
        return Icons.grain;
    }
  }

  Color _getCommodityColor(String name) {
    switch (name.toLowerCase()) {
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.blueGrey;
      case 'crude oil':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
