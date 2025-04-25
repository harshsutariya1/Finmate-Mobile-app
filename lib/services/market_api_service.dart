import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:finmate/models/market_data.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarketApiService {
  static final Logger _logger = Logger();
  static const String _apiKey = 'ALK9YGQQOOGYR0CY'; // Alpha Vantage API key
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  
  // Cache management
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 15);

  // Market indices with correct Alpha Vantage symbols
  static final Map<String, Map<String, String>> _indiaIndices = {
    '^NSEI': {'name': 'NIFTY 50', 'type': 'equity'},
    '^BSESN': {'name': 'BSE SENSEX', 'type': 'equity'},
    'NIFTY50.NS': {'name': 'NIFTY MIDCAP 50', 'type': 'equity'},
    'NSEBANK.NS': {'name': 'NIFTY BANK', 'type': 'sector'},
    'CNXIT.NS': {'name': 'NIFTY IT', 'type': 'sector'},
  };
  
  // Popular Indian stocks with correct Alpha Vantage symbols
  static final List<Map<String, String>> _popularIndianStocks = [
    {'symbol': 'RELIANCE.BSE', 'name': 'Reliance Industries'},
    {'symbol': 'TCS.BSE', 'name': 'Tata Consultancy Services'},
    {'symbol': 'INFY.BSE', 'name': 'Infosys'},
    {'symbol': 'HDFCBANK.BSE', 'name': 'HDFC Bank'},
    {'symbol': 'HINDUNILVR.BSE', 'name': 'Hindustan Unilever'}
  ];
  
  // Popular cryptocurrencies with direct Alpha Vantage support
  static final List<Map<String, String>> _cryptoCurrencies = [
    {'symbol': 'BTC', 'name': 'Bitcoin'},
    {'symbol': 'ETH', 'name': 'Ethereum'},
    {'symbol': 'XRP', 'name': 'Ripple'},
    {'symbol': 'LTC', 'name': 'Litecoin'},
    {'symbol': 'DOGE', 'name': 'Dogecoin'}
  ];
  
  // Popular commodities using Alpha Vantage forex endpoint
  static final Map<String, Map<String, String>> _commodities = {
    'XAU': {'name': 'Gold', 'unit': 'oz'}, 
    'XAG': {'name': 'Silver', 'unit': 'oz'}, 
    'BRENT': {'name': 'Crude Oil (Brent)', 'unit': 'bbl'}
  };

  // API Rate limiting tracking
  static DateTime _lastApiCallTime = DateTime.now().subtract(const Duration(seconds: 15));
  static int _apiCallsInLastMinute = 0;
  static const int _maxCallsPerMinute = 5; // Alpha Vantage free tier limit
  
  // Check if cached data is still valid
  static bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
  
  // Save data to cache
  static void _cacheData(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    
    // Persist the cache to SharedPreferences for longer-term storage
    _persistCache(key, data);
  }
  
  // Persist cache to SharedPreferences
  static Future<void> _persistCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'data': data
      });
      await prefs.setString('market_cache_$key', jsonString);
    } catch (e) {
      _logger.e('Error persisting cache: $e');
    }
  }
  
  // Load cache from SharedPreferences
  static Future<Map<String, dynamic>?> _loadPersistedCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('market_cache_$key');
      
      if (jsonString == null) return null;
      
      final Map<String, dynamic> cacheData = jsonDecode(jsonString);
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      
      // Check if persisted cache is still valid
      if (DateTime.now().difference(timestamp) < _cacheDuration) {
        _cache[key] = cacheData['data'];
        _cacheTimestamps[key] = timestamp;
        return cacheData['data'];
      }
    } catch (e) {
      _logger.e('Error loading persisted cache: $e');
    }
    return null;
  }

  // Handle API rate limiting - CRITICAL for Alpha Vantage
  static Future<void> _respectRateLimit() async {
    final now = DateTime.now();
    final timeSinceLastCall = now.difference(_lastApiCallTime);
    
    // Reset counter if it's been more than a minute
    if (timeSinceLastCall >= const Duration(minutes: 1)) {
      _apiCallsInLastMinute = 0;
    }
    
    // Check if we need to wait due to rate limits
    if (_apiCallsInLastMinute >= _maxCallsPerMinute) {
      final waitTime = const Duration(minutes: 1) - timeSinceLastCall;
      if (waitTime.isNegative) {
        _apiCallsInLastMinute = 0;
      } else {
        _logger.w('Rate limit reached. Waiting for ${waitTime.inSeconds} seconds.');
        await Future.delayed(waitTime + const Duration(seconds: 1));
        _apiCallsInLastMinute = 0;
      }
    }
    
    _lastApiCallTime = now;
    _apiCallsInLastMinute++;
  }
  
  // Generic HTTP GET request with error handling and caching
  static Future<Map<String, dynamic>> _get(String function, Map<String, String> params) async {
    // Create a unique key for this request
    final queryParams = Map<String, String>.from(params)..addAll({'function': function, 'apikey': _apiKey});
    final cacheKey = Uri(queryParameters: queryParams).query;
    
    // Check memory cache first
    if (_isCacheValid(cacheKey)) {
      _logger.i('Using memory cache for: $function with params: $params');
      return _cache[cacheKey];
    }
    
    // Check persisted cache
    final persistedData = await _loadPersistedCache(cacheKey);
    if (persistedData != null) {
      _logger.i('Using persisted cache for: $function with params: $params');
      return persistedData;
    }
    
    // Respect API rate limits - VERY IMPORTANT for Alpha Vantage
    await _respectRateLimit();
    
    // Build URL with query parameters
    final url = Uri.parse('$_baseUrl').replace(
      queryParameters: queryParams,
    );
    
    _logger.i('Fetching data from Alpha Vantage: ${url.toString()}');
    
    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _logger.e('Request timed out for: $function with params: $params');
          throw TimeoutException('Request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        // Check for Alpha Vantage error messages or API limits
        final data = json.decode(response.body);
        
        // Debug logging - print the actual response content
        _logger.d('Alpha Vantage response body: ${response.body}');
        _logger.d('Alpha Vantage response keys: ${data.keys.toList()}');
        
        // Check if Alpha Vantage returned an error message
        if (data is Map<String, dynamic> && data.containsKey('Error Message')) {
          _logger.e('Alpha Vantage API error: ${data['Error Message']} for URL: ${url.toString()}');
          throw Exception('API Error: ${data['Error Message']}');
        }
        
        // Check for API call limits
        if (data is Map<String, dynamic> && data.containsKey('Note') && 
            data['Note'].toString().contains('API call frequency')) {
          _logger.w('Alpha Vantage API rate limit reached: ${data['Note']}');
          throw Exception('API rate limit exceeded: ${data['Note']}');
        }
        
        // If there's no real data in the response, throw an exception with details
        if (_isEmptyResponse(data, function, params)) {
          _logger.w('Empty response from Alpha Vantage for function: $function, params: $params');
          throw Exception('Empty response from Alpha Vantage. The symbol may not exist or API call limit reached.');
        }
        
        // Cache the successful response
        _cacheData(cacheKey, data);
        return data;
      } else {
        _logger.e('HTTP error ${response.statusCode} for URL: ${url.toString()}');
        throw HttpException('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching data from Alpha Vantage: $e for URL: ${url.toString()}');
      
      // For network errors, try to use cache even if it's expired
      if (_cache.containsKey(cacheKey)) {
        _logger.w('Network error, using expired cache');
        return _cache[cacheKey];
      }
      
      // Re-throw the exception to be handled by the provider
      throw Exception('Failed to fetch market data: $e');
    }
  }

  // Improved empty response detection with context-based checks
  static bool _isEmptyResponse(Map<String, dynamic> data, String function, Map<String, String>? params) {
    // Debug logging of the response structure
    _logger.d('Response data for $function: ${json.encode(data)}');
    
    // Special handling for GLOBAL_QUOTE
    if (function == 'GLOBAL_QUOTE') {
      // Check if the Global Quote object exists
      if (!data.containsKey('Global Quote')) {
        return true;
      }
      
      // Check if the Global Quote object is empty or only has empty values
      final quote = data['Global Quote'] as Map<String, dynamic>;
      if (quote.isEmpty) {
        return true;
      }
      
      // Check if it has the price field and it's not empty
      if (!quote.containsKey('05. price') || (quote['05. price'] as String).isEmpty) {
        return true;
      }
      
      // Check if there's any non-empty value in the quote
      bool hasNonEmptyValue = false;
      quote.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          hasNonEmptyValue = true;
        }
      });
      
      return !hasNonEmptyValue;
    }
    
    // Special handling for CURRENCY_EXCHANGE_RATE
    if (function == 'CURRENCY_EXCHANGE_RATE') {
      // Check if the exchange rate object exists
      if (!data.containsKey('Realtime Currency Exchange Rate')) {
        return true;
      }
      
      // Check if the exchange rate object is empty
      final exchangeRate = data['Realtime Currency Exchange Rate'] as Map<String, dynamic>;
      return exchangeRate.isEmpty || !exchangeRate.containsKey('5. Exchange Rate');
    }
    
    // Special handling for TIME_SERIES functions
    if (function.contains('TIME_SERIES')) {
      // Look for time series data keys
      final hasTimeSeriesKey = data.keys.any((key) => 
          key.contains('Time Series') || 
          key.contains('Weekly') || 
          key.contains('Monthly'));
      
      if (!hasTimeSeriesKey) {
        return true;
      }
      
      // Find the time series key
      final timeSeriesKey = data.keys.firstWhere(
        (key) => key.contains('Time Series') || key.contains('Weekly') || key.contains('Monthly'),
        orElse: () => '',
      );
      
      if (timeSeriesKey.isEmpty) {
        return true;
      }
      
      // Check if the time series data is empty
      final timeSeriesData = data[timeSeriesKey] as Map<String, dynamic>;
      return timeSeriesData.isEmpty;
    }
    
    // Special handling for SYMBOL_SEARCH
    if (function == 'SYMBOL_SEARCH') {
      if (!data.containsKey('bestMatches')) {
        return true;
      }
      
      final matches = data['bestMatches'] as List;
      return matches.isEmpty;
    }
    
    // Default check for empty response
    if (data.isEmpty) {
      return true;
    }
    
    // If only Meta Data is present or only Information key is present
    if ((data.length == 1 && data.containsKey('Meta Data')) || 
        (data.length == 1 && data.containsKey('Information'))) {
      return true;
    }
    
    return false;
  }
  
  // Public API methods
  static Future<List<MarketIndex>> getMarketIndices() async {
    final indices = <MarketIndex>[];
    
    for (var entry in _indiaIndices.entries) {
      final symbol = entry.key;
      final indexData = entry.value;
      
      try {
        _logger.i('Fetching market index data for: $symbol');
        
        // Get Global Quote for each index
        final response = await _get('GLOBAL_QUOTE', {'symbol': symbol});
        
        // Process if valid data is returned
        if (response.containsKey('Global Quote') && 
            response['Global Quote'] != null && 
            response['Global Quote'].isNotEmpty) {
          
          final quote = response['Global Quote'];
          indices.add(MarketIndex(
            symbol: symbol,
            name: indexData['name'] ?? '',
            currentValue: double.tryParse(quote['05. price'] ?? '0') ?? 0,
            change: double.tryParse(quote['09. change'] ?? '0') ?? 0,
            changePercentage: double.tryParse(
              (quote['10. change percent'] as String?)?.replaceAll('%', '') ?? '0'
            ) ?? 0,
            type: indexData['type'] ?? 'equity',
            country: 'India',
          ));
          
          _logger.i('Successfully processed market index: $symbol');
        } else {
          _logger.w('Invalid or empty response for market index: $symbol');
          throw Exception('Invalid or empty response for $symbol');
        }
      } catch (e) {
        _logger.e('Error fetching market index $symbol: $e');
        // Don't add this index if it failed
      }
    }
    
    if (indices.isEmpty) {
      _logger.w('Failed to fetch any market indices');
      throw Exception('Failed to fetch market indices');
    }
    
    return indices;
  }
  
  static Future<List<Stock>> getPopularStocks() async {
    final stocks = <Stock>[];
    
    for (var stockInfo in _popularIndianStocks) {
      try {
        final symbol = stockInfo['symbol']!;
        final name = stockInfo['name']!;
        
        // Get quote data
        final quoteResponse = await _get('GLOBAL_QUOTE', {'symbol': symbol});
        
        // Get company overview for more details
        final overviewResponse = await _get('OVERVIEW', {'symbol': symbol});
        
        if (quoteResponse.containsKey('Global Quote') && 
            quoteResponse['Global Quote'] != null && 
            quoteResponse['Global Quote'].isNotEmpty) {
            
          final quote = quoteResponse['Global Quote'];
          
          stocks.add(Stock(
            symbol: symbol,
            name: name,
            currentValue: double.tryParse(quote['05. price'] ?? '0') ?? 0,
            change: double.tryParse(quote['09. change'] ?? '0') ?? 0,
            changePercentage: double.tryParse(
              (quote['10. change percent'] as String?)?.replaceAll('%', '') ?? '0'
            ) ?? 0,
            companyLogo: '', // Alpha Vantage doesn't provide logos
            sector: overviewResponse['Sector'] ?? 'Technology',
            marketCap: double.tryParse(overviewResponse['MarketCapitalization'] ?? '0') ?? 0,
            peRatio: double.tryParse(overviewResponse['PERatio'] ?? '0') ?? 0,
            eps: double.tryParse(overviewResponse['EPS'] ?? '0') ?? 0,
            beta: double.tryParse(overviewResponse['Beta'] ?? '0'),
            dividend: double.tryParse(overviewResponse['DividendYield'] ?? '0'),
            volume: double.tryParse(quote['06. volume'] ?? '0'),
          ));
        } else {
          throw Exception('Invalid or empty response for stock $symbol');
        }
      } catch (e) {
        _logger.e('Error fetching stock: $e');
        // Continue with the next stock
      }
    }
    
    if (stocks.isEmpty) {
      throw Exception('Failed to fetch stock data');
    }
    
    return stocks;
  }
  
  static Future<List<Cryptocurrency>> getCryptocurrencies() async {
    final cryptos = <Cryptocurrency>[];
    
    for (var cryptoInfo in _cryptoCurrencies) {
      try {
        final symbol = cryptoInfo['symbol']!;
        final name = cryptoInfo['name']!;
        
        // Use CURRENCY_EXCHANGE_RATE for real-time crypto price
        final response = await _get('CURRENCY_EXCHANGE_RATE', {
          'from_currency': symbol,
          'to_currency': 'USD'
        });
        
        if (response.containsKey('Realtime Currency Exchange Rate') &&
            response['Realtime Currency Exchange Rate'] != null &&
            response['Realtime Currency Exchange Rate'].isNotEmpty) {
            
          final exchangeRate = response['Realtime Currency Exchange Rate'];
          final rate = double.tryParse(exchangeRate['5. Exchange Rate'] ?? '0') ?? 0;
          
          // For demo purposes, using a simple formula to generate change values
          // In a real app, you'd compare to historical data
          final change = rate * 0.01 * (symbol.hashCode % 2 == 0 ? 1 : -1);
          final changePercentage = 1.0 * (symbol.hashCode % 2 == 0 ? 1 : -1);
          
          cryptos.add(Cryptocurrency(
            symbol: symbol,
            name: name,
            currentValue: rate,
            change: change,
            changePercentage: changePercentage,
            image: '', // Alpha Vantage doesn't provide images
            marketCap: rate * 1000000000, // Simplified value
            volume24h: rate * 10000000, // Simplified value
            circulatingSupply: 1000000 + symbol.hashCode % 100000000, // Simplified value
          ));
        } else {
          throw Exception('Invalid or empty response for crypto $symbol');
        }
      } catch (e) {
        _logger.e('Error fetching cryptocurrency: $e');
        // Continue with the next crypto
      }
    }
    
    if (cryptos.isEmpty) {
      throw Exception('Failed to fetch cryptocurrency data');
    }
    
    return cryptos;
  }
  
  static Future<List<Commodity>> getCommodities() async {
    final commodities = <Commodity>[];
    
    for (var entry in _commodities.entries) {
      try {
        final symbol = entry.key;
        final info = entry.value;
        
        // Use CURRENCY_EXCHANGE_RATE for commodity prices (typically quoted in USD)
        final response = await _get('CURRENCY_EXCHANGE_RATE', {
          'from_currency': symbol,
          'to_currency': 'USD'
        });
        
        if (response.containsKey('Realtime Currency Exchange Rate') &&
            response['Realtime Currency Exchange Rate'] != null &&
            response['Realtime Currency Exchange Rate'].isNotEmpty) {
            
          final exchangeRate = response['Realtime Currency Exchange Rate'];
          final rate = double.tryParse(exchangeRate['5. Exchange Rate'] ?? '0') ?? 0;
          
          // For demo purposes, using simple change values
          final change = rate * 0.01 * (symbol.hashCode % 2 == 0 ? 1 : -1);
          final changePercentage = 0.8 * (symbol.hashCode % 2 == 0 ? 1 : -1);
          
          commodities.add(Commodity(
            symbol: symbol,
            name: info['name']!,
            currentValue: rate,
            change: change,
            changePercentage: changePercentage,
            unit: info['unit']!,
          ));
        } else {
          throw Exception('Invalid or empty response for commodity $symbol');
        }
      } catch (e) {
        _logger.e('Error fetching commodity: $e');
        // Continue with the next commodity
      }
    }
    
    if (commodities.isEmpty) {
      throw Exception('Failed to fetch commodity data');
    }
    
    return commodities;
  }
  
  static Future<List<ChartDataPoint>> getChartData(String symbol, TimeRange range) async {
    final chartData = <ChartDataPoint>[];
    
    try {
      Map<String, String> params = {'symbol': symbol};
      
      // Set the right interval for intraday data
      if (range.interval != null) {
        params['interval'] = range.interval!;
      }
      
      final response = await _get(range.functionName, params);
      
      // Determine which key contains the time series data
      String? timeSeriesKey;
      for (var key in response.keys) {
        if (key.contains('Time Series') || key.contains('Weekly') || key.contains('Monthly')) {
          timeSeriesKey = key;
          break;
        }
      }
      
      if (timeSeriesKey == null) {
        throw Exception('No time series data found for $symbol with range ${range.name}');
      }
      
      // Get time series data
      final timeSeries = response[timeSeriesKey] as Map<String, dynamic>;
      
      // Filter entries based on the date range
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day - range.days);
      
      // Convert to list and sort by date (newest first)
      final entries = timeSeries.entries.toList()
        ..sort((a, b) => DateTime.parse(b.key).compareTo(DateTime.parse(a.key)));
      
      for (var entry in entries) {
        final date = DateTime.parse(entry.key);
        
        // Skip if before our start date
        if (date.isBefore(startDate)) continue;
        
        final dataPoint = ChartDataPoint.fromAlphaVantage(entry.key, entry.value);
        chartData.add(dataPoint);
      }
      
      // If we have too many points, sample them
      if (chartData.length > 100) {
        return _sampleChartData(chartData, 100);
      }
      
      return chartData;
    } catch (e) {
      _logger.e('Error fetching chart data for $symbol: $e');
      throw Exception('Failed to load chart data: $e');
    }
  }
  
  // Sample chart data to reduce points
  static List<ChartDataPoint> _sampleChartData(List<ChartDataPoint> data, int targetPoints) {
    if (data.length <= targetPoints) return data;
    
    final List<ChartDataPoint> sampledData = [];
    final int step = (data.length / targetPoints).ceil();
    
    for (int i = 0; i < data.length; i += step) {
      if (i < data.length) {
        sampledData.add(data[i]);
      }
    }
    
    // Always ensure the most recent data point is included
    if (sampledData.isEmpty || sampledData.first != data.first) {
      sampledData.insert(0, data.first);
    }
    
    return sampledData;
  }
  
  // Search for market symbols
  static Future<List<MarketSearchResult>> searchMarket(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    try {
      final response = await _get('SYMBOL_SEARCH', {'keywords': query});
      
      if (!response.containsKey('bestMatches') || 
          response['bestMatches'] == null ||
          (response['bestMatches'] as List).isEmpty) {
        throw Exception('No search results found for "$query"');  
      }
      
      final List<dynamic> matches = response['bestMatches'];
      return matches.map((match) => 
        MarketSearchResult.fromAlphaVantageSearch(match)).toList();
    } catch (e) {
      _logger.e('Error searching market: $e');
      throw Exception('Failed to search market: $e');
    }
  }
}
