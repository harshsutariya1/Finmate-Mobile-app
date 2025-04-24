import 'package:finmate/models/market_data.dart';
import 'package:finmate/services/market_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final marketApiServiceProvider = Provider<MarketApiService>((ref) {
  return MarketApiService();
});

// Market Indices
final marketIndicesProvider = FutureProvider<List<MarketIndex>>((ref) async {
  final apiService = ref.watch(marketApiServiceProvider);
  return apiService.getMarketIndices();
});

// Popular Stocks
final popularStocksProvider = FutureProvider<List<Stock>>((ref) async {
  final apiService = ref.watch(marketApiServiceProvider);
  return apiService.getPopularStocks();
});

// Search Stocks Query
final stockSearchQueryProvider = StateProvider<String>((ref) => '');

// Search Results
final stockSearchResultsProvider = FutureProvider<List<Stock>>((ref) async {
  final apiService = ref.watch(marketApiServiceProvider);
  final query = ref.watch(stockSearchQueryProvider);
  
  if (query.isEmpty) return [];
  return apiService.searchStocks(query);
});

// Cryptocurrencies
final cryptocurrenciesProvider = FutureProvider<List<Cryptocurrency>>((ref) async {
  final apiService = ref.watch(marketApiServiceProvider);
  return apiService.getCryptocurrencies();
});

// Commodities
final commoditiesProvider = FutureProvider<List<Commodity>>((ref) async {
  final apiService = ref.watch(marketApiServiceProvider);
  return apiService.getCommodities();
});

// Selected Time Range for charts
final selectedTimeRangeProvider = StateProvider<TimeRange>((ref) => TimeRange.month);

// Detailed Stock Data Provider with parameters
final detailedStockDataProvider = FutureProvider.family<List<ChartDataPoint>, String>((ref, symbol) async {
  final apiService = ref.watch(marketApiServiceProvider);
  final timeRange = ref.watch(selectedTimeRangeProvider);
  return apiService.getDetailedStockData(symbol, timeRange);
});
