import 'package:finmate/models/market_data.dart';
import 'package:finmate/services/market_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

// Provider for selected time range
final selectedTimeRangeProvider = StateProvider<TimeRange>(
  (ref) => TimeRange.daily,
);

// Provider for search query
final searchQueryProvider = StateProvider<String>(
  (ref) => '',
);

// Provider for market indices with auto-refresh
final marketIndicesProvider = FutureProvider<List<MarketIndex>>((ref) async {
  _logger.i('Fetching market indices...');
  try {
    return await MarketApiService.getMarketIndices();
  } catch (e) {
    _logger.e('Error in marketIndicesProvider: $e');
    // Don't return empty list anymore, let the error propagate
    throw e;
  }
});

// Provider for popular stocks with auto-refresh
final popularStocksProvider = FutureProvider<List<Stock>>((ref) async {
  _logger.i('Fetching popular stocks...');
  try {
    return await MarketApiService.getPopularStocks();
  } catch (e) {
    _logger.e('Error in popularStocksProvider: $e');
    throw e;
  }
});

// Provider for cryptocurrencies with auto-refresh
final cryptocurrenciesProvider = FutureProvider<List<Cryptocurrency>>((ref) async {
  _logger.i('Fetching cryptocurrencies...');
  try {
    return await MarketApiService.getCryptocurrencies();
  } catch (e) {
    _logger.e('Error in cryptocurrenciesProvider: $e');
    throw e;
  }
});

// Provider for commodities with auto-refresh
final commoditiesProvider = FutureProvider<List<Commodity>>((ref) async {
  _logger.i('Fetching commodities...');
  try {
    return await MarketApiService.getCommodities();
  } catch (e) {
    _logger.e('Error in commoditiesProvider: $e');
    throw e;
  }
});

// Provider for chart data with auto-refresh
final chartDataProvider = FutureProvider.family<List<ChartDataPoint>, ChartDataRequest>((ref, request) async {
  _logger.i('Fetching chart data for ${request.symbol}...');
  try {
    return await MarketApiService.getChartData(request.symbol, request.timeRange);
  } catch (e) {
    _logger.e('Error in chartDataProvider: $e');
    throw e;
  }
});

// Provider for market search results
final marketSearchProvider = FutureProvider.family<List<MarketSearchResult>, String>((ref, query) async {
  if (query.isEmpty) {
    return [];
  }
  _logger.i('Searching market for: $query');
  try {
    return await MarketApiService.searchMarket(query);
  } catch (e) {
    _logger.e('Error in marketSearchProvider: $e');
    throw e;
  }
});

// Class to hold chart data requests
class ChartDataRequest {
  final String symbol;
  final TimeRange timeRange;
  
  ChartDataRequest({required this.symbol, required this.timeRange});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartDataRequest &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          timeRange == other.timeRange;

  @override
  int get hashCode => symbol.hashCode ^ timeRange.hashCode;
}
