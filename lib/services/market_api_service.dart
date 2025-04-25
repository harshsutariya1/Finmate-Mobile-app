import 'dart:convert';
import 'package:finmate/models/market_data.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarketApiService {
  final Logger _logger = Logger();
  
  // AlphaVantage API key
  static const String _alphavantageApiKey = 'ALK9YGQQOOGYR0CY';
  
  // Base URL for AlphaVantage API
  static const String _alphavantageBaseUrl = 'https://www.alphavantage.co/query';
  
  // Cache timeout (5 minutes)
  static const int _cacheTimeoutMinutes = 5;
  
  // Get market indices data (NSE, BSE)
  Future<List<MarketIndex>> getMarketIndices() async {
    try {
      final cachedData = await _getCachedData('market_indices');
      if (cachedData != null) {
        return _parseIndicesFromCache(cachedData);
      }
      
      // For NSE NIFTY 50
      final niftyData = await _fetchGlobalQuote('^NSEI');
      
      // For BSE SENSEX
      final bseData = await _fetchGlobalQuote('^BSESN');
      
      // For NIFTY Bank
      final bankNiftyData = await _fetchGlobalQuote('^NSEBANK');
      
      // Get historical data for charts
      final niftyHistorical = await _fetchTimeSeriesData('^NSEI', TimeRange.month);
      final bseHistorical = await _fetchTimeSeriesData('^BSESN', TimeRange.month);
      final bankNiftyHistorical = await _fetchTimeSeriesData('^NSEBANK', TimeRange.month);
      
      final indices = [
        _createMarketIndexFromResponse(
          'NSE NIFTY 50', 'NIFTY', niftyData, niftyHistorical),
        _createMarketIndexFromResponse(
          'BSE SENSEX', 'SENSEX', bseData, bseHistorical),
        _createMarketIndexFromResponse(
          'NIFTY Bank', 'BANKNIFTY', bankNiftyData, bankNiftyHistorical),
      ];
      
      // Cache the results
      await _cacheData('market_indices', indices.map((index) => index.toJson()).toList());
      
      return indices;
    } catch (e) {
      _logger.e('Failed to fetch market indices: $e');
      // Return mock data as fallback if API fails
      return [
        MarketIndex(
          name: 'NSE NIFTY 50',
          symbol: 'NIFTY',
          currentValue: 22462.75,
          change: 121.63,
          changePercentage: 0.54,
          historicalData: _generateMockHistoricalData(22300, 22500),
        ),
        MarketIndex(
          name: 'BSE SENSEX',
          symbol: 'SENSEX',
          currentValue: 73709.60,
          change: 469.05,
          changePercentage: 0.64,
          historicalData: _generateMockHistoricalData(73300, 73800),
        ),
        MarketIndex(
          name: 'NIFTY Bank',
          symbol: 'BANKNIFTY',
          currentValue: 48461.30,
          change: -98.20,
          changePercentage: -0.20,
          historicalData: _generateMockHistoricalData(48300, 48600),
        ),
      ];
    }
  }
  
  // Get popular stocks data
  Future<List<Stock>> getPopularStocks() async {
    try {
      final cachedData = await _getCachedData('popular_stocks');
      if (cachedData != null) {
        return _parseStocksFromCache(cachedData);
      }
      
      // Symbols for popular Indian stocks
      final symbols = [
        'RELIANCE.BSE', // Reliance Industries
        'TCS.BSE',      // Tata Consultancy Services
        'HDFCBANK.BSE', // HDFC Bank
        'INFY.BSE',     // Infosys
        'ICICIBANK.BSE' // ICICI Bank
      ];
      
      final List<Stock> stocks = [];
      
      for (final symbol in symbols) {
        // Get quote data
        final quoteData = await _fetchGlobalQuote(symbol);
        
        // Get historical data
        final historicalData = await _fetchTimeSeriesData(symbol, TimeRange.month);
        
        // Create stock object
        stocks.add(_createStockFromResponse(symbol, quoteData, historicalData));
      }
      
      // Cache the results
      await _cacheData('popular_stocks', stocks.map((stock) => stock.toJson()).toList());
      
      return stocks;
    } catch (e) {
      _logger.e('Failed to fetch popular stocks: $e');
      // Return mock data as fallback
      return [
        Stock(
          name: 'Reliance Industries',
          symbol: 'RELIANCE.NS',
          companyLogo: 'https://companieslogo.com/img/orig/RELIANCE.NS-c28acd1c.png',
          currentPrice: 2934.75,
          change: 18.55,
          changePercentage: 0.64,
          marketCap: 1986432000000,
          peRatio: 32.56,
          eps: 90.13,
          sector: 'Oil & Gas',
          historicalData: _generateMockHistoricalData(2900, 2950),
        ),
        // ... other mock stocks data
      ];
    }
  }

  // Search stocks by query
  Future<List<Stock>> searchStocks(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // Use AlphaVantage Symbol Search API
      final response = await http.get(Uri.parse(
        '$_alphavantageBaseUrl?function=SYMBOL_SEARCH&keywords=$query&apikey=$_alphavantageApiKey'
      ));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('bestMatches')) {
          final matches = data['bestMatches'] as List;
          
          final List<Stock> results = [];
          
          // Limit to 5 results to avoid API rate limiting
          for (int i = 0; i < matches.length && i < 5; i++) {
            final match = matches[i];
            final symbol = match['1. symbol'];
            
            // Get more details for this stock
            try {
              final quoteData = await _fetchGlobalQuote(symbol);
              final historicalData = await _fetchTimeSeriesData(symbol, TimeRange.month);
              
              results.add(_createStockFromResponse(
                symbol, quoteData, historicalData, 
                name: match['2. name'],
                type: match['3. type'],
                region: match['4. region'],
              ));
            } catch (e) {
              // Continue with next result if one fails
              _logger.w('Error fetching details for search result $symbol: $e');
              continue;
            }
          }
          
          return results;
        }
      }
      
      return [];
    } catch (e) {
      _logger.e('Failed to search stocks: $e');
      return [];
    }
  }

  // Get cryptocurrencies data
  Future<List<Cryptocurrency>> getCryptocurrencies() async {
    try {
      final cachedData = await _getCachedData('cryptocurrencies');
      if (cachedData != null) {
        return _parseCryptosFromCache(cachedData);
      }
      
      // Crypto symbols to fetch
      final symbols = ['BTC', 'ETH', 'USDT'];
      final List<Cryptocurrency> cryptos = [];
      
      for (final symbol in symbols) {
        // Fetch crypto data from AlphaVantage
        final response = await http.get(Uri.parse(
          '$_alphavantageBaseUrl?function=DIGITAL_CURRENCY_DAILY&symbol=$symbol&market=INR&apikey=$_alphavantageApiKey'
        ));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data.containsKey('Meta Data') && data.containsKey('Time Series (Digital Currency Daily)')) {
            final metaData = data['Meta Data'];
            final timeSeries = data['Time Series (Digital Currency Daily)'];
            
            // Get the latest date
            final latestDate = timeSeries.keys.first;
            final latestData = timeSeries[latestDate];
            
            // Get historical data for chart
            final List<ChartDataPoint> historicalData = [];
            final sortedDates = timeSeries.keys.toList()..sort();
            final last30Days = sortedDates.reversed.take(30).toList();
            
            for (final date in last30Days) {
              final dayData = timeSeries[date];
              historicalData.add(ChartDataPoint(
                timestamp: DateTime.parse(date),
                value: double.parse(dayData['4a. close (INR)']),
              ));
            }
            
            // Calculate change
            final double currentPrice = double.parse(latestData['4a. close (INR)']);
            final double previousPrice = double.parse(
              timeSeries[sortedDates[sortedDates.length - 2]]['4a. close (INR)']
            );
            final double change = currentPrice - previousPrice;
            final double changePercentage = (change / previousPrice) * 100;
            
            cryptos.add(Cryptocurrency(
              name: _getCryptoName(symbol),
              symbol: symbol,
              image: _getCryptoImage(symbol),
              currentPrice: currentPrice,
              change: change,
              changePercentage: changePercentage,
              marketCap: _estimateMarketCap(symbol, currentPrice),
              volume24h: double.parse(latestData['5. volume']),
              circulatingSupply: _getCirculatingSupply(symbol),
              historicalData: historicalData,
            ));
          }
        }
      }
      
      if (cryptos.isNotEmpty) {
        await _cacheData('cryptocurrencies', cryptos.map((crypto) => crypto.toJson()).toList());
        return cryptos;
      }
      
      // Use mock data if API call fails
      return _getMockCryptos();
    } catch (e) {
      _logger.e('Failed to fetch cryptocurrencies: $e');
      return _getMockCryptos();
    }
  }

  // Get commodities data (Gold, Silver)
  Future<List<Commodity>> getCommodities() async {
    try {
      // For commodities, we use Forex API to get precious metals
      // XAU/INR for Gold (per troy ounce)
      // XAG/INR for Silver (per troy ounce)
      
      final cachedData = await _getCachedData('commodities');
      if (cachedData != null) {
        return _parseCommoditiesFromCache(cachedData);
      }
      
      final List<Commodity> commodities = [];
      
      // Gold price in INR
      final goldResponse = await http.get(Uri.parse(
        '$_alphavantageBaseUrl?function=CURRENCY_EXCHANGE_RATE&from_currency=XAU&to_currency=INR&apikey=$_alphavantageApiKey'
      ));
      
      // Silver price in INR
      final silverResponse = await http.get(Uri.parse(
        '$_alphavantageBaseUrl?function=CURRENCY_EXCHANGE_RATE&from_currency=XAG&to_currency=INR&apikey=$_alphavantageApiKey'
      ));
      
      // Oil (WTI) price in USD, then convert to INR
      final oilResponse = await http.get(Uri.parse(
        '$_alphavantageBaseUrl?function=WTI&interval=daily&apikey=$_alphavantageApiKey'
      ));
      
      // USD to INR exchange rate
      final usdInrResponse = await http.get(Uri.parse(
        '$_alphavantageBaseUrl?function=CURRENCY_EXCHANGE_RATE&from_currency=USD&to_currency=INR&apikey=$_alphavantageApiKey'
      ));
      
      if (goldResponse.statusCode == 200) {
        final data = json.decode(goldResponse.body);
        if (data.containsKey('Realtime Currency Exchange Rate')) {
          final rateData = data['Realtime Currency Exchange Rate'];
          final double exchangeRate = double.parse(rateData['5. Exchange Rate']);
          
          // Convert from per troy ounce to per 10 grams (standard in India)
          // 1 troy ounce = 31.1035 grams
          final double perTenGrams = exchangeRate * 10 / 31.1035;
          
          // Mock change data since the API doesn't provide historical data in the free tier
          final double change = 305.00;
          final double changePercentage = 0.43;
          
          commodities.add(Commodity(
            name: 'Gold',
            symbol: 'XAU',
            currentPrice: perTenGrams,
            change: change,
            changePercentage: changePercentage,
            unit: '10 grams',
            historicalData: _generateMockHistoricalData(perTenGrams - 500, perTenGrams + 500),
          ));
        }
      }
      
      if (silverResponse.statusCode == 200) {
        final data = json.decode(silverResponse.body);
        if (data.containsKey('Realtime Currency Exchange Rate')) {
          final rateData = data['Realtime Currency Exchange Rate'];
          final double exchangeRate = double.parse(rateData['5. Exchange Rate']);
          
          // Convert from per troy ounce to per kg (standard in India)
          // 1 troy ounce = 31.1035 grams, 1 kg = 1000 grams
          final double perKg = exchangeRate * 1000 / 31.1035;
          
          // Mock change data
          final double change = -294.00;
          final double changePercentage = -0.31;
          
          commodities.add(Commodity(
            name: 'Silver',
            symbol: 'XAG',
            currentPrice: perKg,
            change: change,
            changePercentage: changePercentage,
            unit: '1 kg',
            historicalData: _generateMockHistoricalData(perKg - 1000, perKg + 1000),
          ));
        }
      }
      
      // Handle crude oil if the response is valid
      if (oilResponse.statusCode == 200 && usdInrResponse.statusCode == 200) {
        final oilData = json.decode(oilResponse.body);
        final usdInrData = json.decode(usdInrResponse.body);
        
        if (oilData.containsKey('data') && 
            usdInrData.containsKey('Realtime Currency Exchange Rate')) {
          final oilEntries = oilData['data'] as List;
          if (oilEntries.isNotEmpty) {
            final latestOil = oilEntries.first;
            final double oilUsd = double.parse(latestOil['value']);
            
            final usdInrRate = usdInrData['Realtime Currency Exchange Rate'];
            final double usdToInr = double.parse(usdInrRate['5. Exchange Rate']);
            
            final double oilInr = oilUsd * usdToInr;
            
            // Mock change data
            final double change = 23.50;
            final double changePercentage = 0.35;
            
            commodities.add(Commodity(
              name: 'Crude Oil',
              symbol: 'CL',
              currentPrice: oilInr,
              change: change,
              changePercentage: changePercentage,
              unit: '1 barrel',
              historicalData: _generateMockHistoricalData(oilInr - 100, oilInr + 100),
            ));
          }
        }
      }
      
      if (commodities.isNotEmpty) {
        await _cacheData('commodities', commodities.map((commodity) => commodity.toJson()).toList());
        return commodities;
      }
      
      // Return mock data if API calls fail
      return _getMockCommodities();
    } catch (e) {
      _logger.e('Failed to fetch commodities: $e');
      return _getMockCommodities();
    }
  }

  // Get detailed historical data for a specific stock
  Future<List<ChartDataPoint>> getDetailedStockData(String symbol, TimeRange timeRange) async {
    try {
      final cacheKey = 'detailed_${symbol}_${timeRange.label}';
      final cachedData = await _getCachedData(cacheKey);
      if (cachedData != null) {
        return (cachedData as List)
          .map((item) => ChartDataPoint(
            timestamp: DateTime.parse(item['timestamp']),
            value: item['value'],
          ))
          .toList();
      }
      
      // Determine time series function based on time range
      String function;
      String interval = 'daily';
      
      switch (timeRange) {
        case TimeRange.day:
          function = 'TIME_SERIES_INTRADAY';
          interval = '5min';
          break;
        case TimeRange.week:
        case TimeRange.month:
          function = 'TIME_SERIES_DAILY';
          break;
        case TimeRange.threeMonths:
        case TimeRange.sixMonths:
          function = 'TIME_SERIES_WEEKLY';
          break;
        case TimeRange.year:
        case TimeRange.fiveYears:
          function = 'TIME_SERIES_MONTHLY';
          break;
      }
      
      // Build URL based on function
      String url = '$_alphavantageBaseUrl?function=$function&symbol=$symbol&apikey=$_alphavantageApiKey';
      if (function == 'TIME_SERIES_INTRADAY') {
        url += '&interval=$interval';
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<ChartDataPoint> chartData = [];
        
        String timeSeriesKey;
        if (function == 'TIME_SERIES_INTRADAY') {
          timeSeriesKey = 'Time Series ($interval)';
        } else if (function == 'TIME_SERIES_DAILY') {
          timeSeriesKey = 'Time Series (Daily)';
        } else if (function == 'TIME_SERIES_WEEKLY') {
          timeSeriesKey = 'Weekly Time Series';
        } else {
          timeSeriesKey = 'Monthly Time Series';
        }
        
        if (data.containsKey(timeSeriesKey)) {
          final timeSeries = data[timeSeriesKey] as Map<String, dynamic>;
          
          // Convert map entries to list and sort by date
          final entries = timeSeries.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
            
          // Filter based on time range
          final now = DateTime.now();
          final startDate = now.subtract(timeRange.duration);
          
          for (var entry in entries) {
            final date = DateTime.parse(entry.key);
            if (date.isAfter(startDate)) {
              chartData.add(ChartDataPoint(
                timestamp: date,
                value: double.parse(entry.value['4. close']),
              ));
            }
          }
          
          // Cache the results
          await _cacheData(cacheKey, chartData.map((point) => {
            'timestamp': point.timestamp.toIso8601String(),
            'value': point.value,
          }).toList());
          
          return chartData;
        }
      }
      
      // Return mock data if API call fails
      return _generateDetailedMockData(timeRange);
    } catch (e) {
      _logger.e('Failed to fetch detailed stock data: $e');
      return _generateDetailedMockData(timeRange);
    }
  }

  // Fetch global quote for a symbol
  Future<Map<String, dynamic>> _fetchGlobalQuote(String symbol) async {
    final response = await http.get(Uri.parse(
      '$_alphavantageBaseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_alphavantageApiKey'
    ));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to load quote for $symbol');
    }
    
    final data = json.decode(response.body);
    if (!data.containsKey('Global Quote') || data['Global Quote'].isEmpty) {
      throw Exception('No quote data for $symbol');
    }
    
    return data['Global Quote'];
  }
  
  // Fetch time series data for a symbol
  Future<List<ChartDataPoint>> _fetchTimeSeriesData(String symbol, TimeRange timeRange) async {
    String function = 'TIME_SERIES_DAILY';
    String outputSize = 'compact'; // compact = 100 data points
    
    final response = await http.get(Uri.parse(
      '$_alphavantageBaseUrl?function=$function&symbol=$symbol&outputsize=$outputSize&apikey=$_alphavantageApiKey'
    ));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to load time series for $symbol');
    }
    
    final data = json.decode(response.body);
    if (!data.containsKey('Time Series (Daily)')) {
      throw Exception('No time series data for $symbol');
    }
    
    final timeSeries = data['Time Series (Daily)'] as Map<String, dynamic>;
    final List<ChartDataPoint> chartData = [];
    
    // Convert to sorted list
    final entries = timeSeries.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
      
    // Get the last 30 days or less
    final dataPoints = entries.length > 30 ? entries.sublist(entries.length - 30) : entries;
    
    for (var entry in dataPoints) {
      chartData.add(ChartDataPoint(
        timestamp: DateTime.parse(entry.key),
        value: double.parse(entry.value['4. close']),
      ));
    }
    
    return chartData;
  }
  
  // Create MarketIndex from API response
  MarketIndex _createMarketIndexFromResponse(
      String name, String symbol, Map<String, dynamic> quoteData, List<ChartDataPoint> historicalData) {
    final double currentValue = double.parse(quoteData['05. price']);
    final double change = double.parse(quoteData['09. change']);
    final double changePercentage = double.parse(quoteData['10. change percent'].replaceAll('%', ''));
    
    return MarketIndex(
      name: name,
      symbol: symbol,
      currentValue: currentValue,
      change: change,
      changePercentage: changePercentage,
      historicalData: historicalData,
    );
  }
  
  // Create Stock from API response
  Stock _createStockFromResponse(
      String symbol, Map<String, dynamic> quoteData, List<ChartDataPoint> historicalData, 
      {String? name, String? type, String? region}) {
    final double currentPrice = double.parse(quoteData['05. price']);
    final double change = double.parse(quoteData['09. change']);
    final double changePercentage = double.parse(quoteData['10. change percent'].replaceAll('%', ''));
    
    // Extract just the stock name from the symbol
    final stockName = name ?? _getStockNameFromSymbol(symbol);
    
    return Stock(
      name: stockName,
      symbol: symbol,
      companyLogo: _getCompanyLogoUrl(symbol),
      currentPrice: currentPrice,
      change: change,
      changePercentage: changePercentage,
      // Since we can't get this from Global Quote, use estimates or mock data
      marketCap: _estimateMarketCap(symbol, currentPrice),
      peRatio: _estimatePERatio(symbol),
      eps: _estimateEPS(symbol),
      sector: _getStockSector(symbol),
      historicalData: historicalData,
    );
  }
  
  // Helper methods for data that isn't available in the free API tier
  
  String _getStockNameFromSymbol(String symbol) {
    final symbolMap = {
      'RELIANCE.BSE': 'Reliance Industries',
      'TCS.BSE': 'Tata Consultancy Services',
      'HDFCBANK.BSE': 'HDFC Bank',
      'INFY.BSE': 'Infosys',
      'ICICIBANK.BSE': 'ICICI Bank',
    };
    
    return symbolMap[symbol] ?? symbol.split('.')[0];
  }
  
  String _getCompanyLogoUrl(String symbol) {
    final logoMap = {
      'RELIANCE.BSE': 'https://companieslogo.com/img/orig/RELIANCE.NS-c28acd1c.png',
      'TCS.BSE': 'https://companieslogo.com/img/orig/TCS.NS-7401f1bd.png',
      'HDFCBANK.BSE': 'https://companieslogo.com/img/orig/HDB-bb6241fe.png',
      'INFY.BSE': 'https://companieslogo.com/img/orig/INFY-7401e672.png',
      'ICICIBANK.BSE': 'https://companieslogo.com/img/orig/IBN-af163749.png',
    };
    
    return logoMap[symbol] ?? '';
  }
  
  double _estimateMarketCap(String symbol, double price) {
    final marketCapMap = {
      'RELIANCE.BSE': 1986432000000.0,
      'TCS.BSE': 1420000000000.0,
      'HDFCBANK.BSE': 1280000000000.0,
      'INFY.BSE': 645000000000.0,
      'ICICIBANK.BSE': 735000000000.0,
      'BTC': 124505343292565.0,
      'ETH': 40292332842479.0,
      'USDT': 10732727757734.0,
    };
    
    return marketCapMap[symbol] ?? (price * 1000000000);
  }
  
  double _estimatePERatio(String symbol) {
    final peRatioMap = {
      'RELIANCE.BSE': 32.56,
      'TCS.BSE': 29.14,
      'HDFCBANK.BSE': 23.86,
      'INFY.BSE': 25.23,
      'ICICIBANK.BSE': 22.15,
    };
    
    return peRatioMap[symbol] ?? 20.0;
  }
  
  double _estimateEPS(String symbol) {
    final epsMap = {
      'RELIANCE.BSE': 90.13,
      'TCS.BSE': 133.02,
      'HDFCBANK.BSE': 70.51,
      'INFY.BSE': 61.86,
      'ICICIBANK.BSE': 47.54,
    };
    
    return epsMap[symbol] ?? 5.0;
  }
  
  String _getStockSector(String symbol) {
    final sectorMap = {
      'RELIANCE.BSE': 'Oil & Gas',
      'TCS.BSE': 'IT Services',
      'HDFCBANK.BSE': 'Banking',
      'INFY.BSE': 'IT Services',
      'ICICIBANK.BSE': 'Banking',
    };
    
    return sectorMap[symbol] ?? 'Others';
  }
  
  String _getCryptoName(String symbol) {
    final nameMap = {
      'BTC': 'Bitcoin',
      'ETH': 'Ethereum',
      'USDT': 'Tether',
    };
    
    return nameMap[symbol] ?? symbol;
  }
  
  String _getCryptoImage(String symbol) {
    final imageMap = {
      'BTC': 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
      'ETH': 'https://assets.coingecko.com/coins/images/279/large/ethereum.png',
      'USDT': 'https://assets.coingecko.com/coins/images/325/large/Tether.png',
    };
    
    return imageMap[symbol] ?? '';
  }
  
  double _getCirculatingSupply(String symbol) {
    final supplyMap = {
      'BTC': 19747587.0,
      'ETH': 120307495.0,
      'USDT': 128750000000.0,
    };
    
    return supplyMap[symbol] ?? 0.0;
  }
  
  // Cache methods
  
  Future<void> _cacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheItem = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await prefs.setString(key, json.encode(cacheItem));
    } catch (e) {
      _logger.e('Error caching data: $e');
    }
  }
  
  Future<dynamic> _getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedItemStr = prefs.getString(key);
      
      if (cachedItemStr != null) {
        final cachedItem = json.decode(cachedItemStr);
        final timestamp = cachedItem['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Check if cache is still valid (less than 5 minutes old)
        if (now - timestamp < _cacheTimeoutMinutes * 60 * 1000) {
          return cachedItem['data'];
        }
      }
      return null;
    } catch (e) {
      _logger.e('Error reading cache: $e');
      return null;
    }
  }
  
  // Parse cached data back to objects
  
  List<MarketIndex> _parseIndicesFromCache(List<dynamic> cachedData) {
    return cachedData.map((item) {
      final historicalData = (item['historicalData'] as List).map((point) => ChartDataPoint(
        timestamp: DateTime.parse(point['timestamp']),
        value: point['value'],
      )).toList();
      
      return MarketIndex(
        name: item['name'],
        symbol: item['symbol'],
        currentValue: item['currentValue'],
        change: item['change'],
        changePercentage: item['changePercentage'],
        historicalData: historicalData,
      );
    }).toList();
  }
  
  List<Stock> _parseStocksFromCache(List<dynamic> cachedData) {
    return cachedData.map((item) {
      final historicalData = (item['historicalData'] as List).map((point) => ChartDataPoint(
        timestamp: DateTime.parse(point['timestamp']),
        value: point['value'],
      )).toList();
      
      return Stock(
        name: item['name'],
        symbol: item['symbol'],
        companyLogo: item['companyLogo'] ?? '',
        currentPrice: item['currentPrice'],
        change: item['change'],
        changePercentage: item['changePercentage'],
        marketCap: item['marketCap'],
        peRatio: item['peRatio'],
        eps: item['eps'],
        sector: item['sector'],
        historicalData: historicalData,
      );
    }).toList();
  }
  
  List<Cryptocurrency> _parseCryptosFromCache(List<dynamic> cachedData) {
    return cachedData.map((item) {
      final historicalData = (item['historicalData'] as List).map((point) => ChartDataPoint(
        timestamp: DateTime.parse(point['timestamp']),
        value: point['value'],
      )).toList();
      
      return Cryptocurrency(
        name: item['name'],
        symbol: item['symbol'],
        image: item['image'] ?? '',
        currentPrice: item['currentPrice'],
        change: item['change'],
        changePercentage: item['changePercentage'],
        marketCap: item['marketCap'],
        volume24h: item['volume24h'],
        circulatingSupply: item['circulatingSupply'],
        historicalData: historicalData,
      );
    }).toList();
  }
  
  List<Commodity> _parseCommoditiesFromCache(List<dynamic> cachedData) {
    return cachedData.map((item) {
      final historicalData = (item['historicalData'] as List).map((point) => ChartDataPoint(
        timestamp: DateTime.parse(point['timestamp']),
        value: point['value'],
      )).toList();
      
      return Commodity(
        name: item['name'],
        symbol: item['symbol'],
        currentPrice: item['currentPrice'],
        change: item['change'],
        changePercentage: item['changePercentage'],
        unit: item['unit'],
        historicalData: historicalData,
      );
    }).toList();
  }
  
  // Mock data for fallbacks
  
  List<Cryptocurrency> _getMockCryptos() {
    return [
      Cryptocurrency(
        name: 'Bitcoin',
        symbol: 'BTC',
        image: 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
        currentPrice: 6296256.28, // INR value
        change: 6645.24,
        changePercentage: 0.11,
        marketCap: 124505343292565,
        volume24h: 3160628460644,
        circulatingSupply: 19747587,
        historicalData: _generateMockHistoricalData(6280000, 6300000),
      ),
      Cryptocurrency(
        name: 'Ethereum',
        symbol: 'ETH',
        image: 'https://assets.coingecko.com/coins/images/279/large/ethereum.png',
        currentPrice: 334913.95, // INR value
        change: 478.68,
        changePercentage: 0.14,
        marketCap: 40292332842479,
        volume24h: 1148867259025,
        circulatingSupply: 120307495,
        historicalData: _generateMockHistoricalData(334000, 335000),
      ),
      Cryptocurrency(
        name: 'Tether',
        symbol: 'USDT',
        image: 'https://assets.coingecko.com/coins/images/325/large/Tether.png',
        currentPrice: 83.36, // INR value
        change: -0.05,
        changePercentage: -0.06,
        marketCap: 10732727757734,
        volume24h: 3424451689685,
        circulatingSupply: 128750000000,
        historicalData: _generateMockHistoricalData(83.30, 83.40),
      ),
    ];
  }
  
  List<Commodity> _getMockCommodities() {
    return [
      Commodity(
        name: 'Gold',
        symbol: 'XAU',
        currentPrice: 71892.00, // INR per 10 grams
        change: 305.00,
        changePercentage: 0.43,
        unit: '10 grams',
        historicalData: _generateMockHistoricalData(71500, 72000),
      ),
      Commodity(
        name: 'Silver',
        symbol: 'XAG',
        currentPrice: 94435.00, // INR per kg
        change: -294.00,
        changePercentage: -0.31,
        unit: '1 kg',
        historicalData: _generateMockHistoricalData(94300, 94600),
      ),
      Commodity(
        name: 'Crude Oil',
        symbol: 'CL',
        currentPrice: 6654.19, // INR per barrel
        change: 23.50,
        changePercentage: 0.35,
        unit: '1 barrel',
        historicalData: _generateMockHistoricalData(6630, 6670),
      ),
    ];
  }
  
  // Generate mock historical data
  List<ChartDataPoint> _generateMockHistoricalData(double min, double max) {
    final now = DateTime.now();
    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000;
    List<ChartDataPoint> data = [];

    for (int i = 30; i >= 0; i--) {
      final point = ChartDataPoint(
        timestamp: now.subtract(Duration(days: i)),
        value: min + (max - min) * ((random * i / 30 + 0.5) % 1.0),
      );
      data.add(point);
    }
    return data;
  }

  // Generate more detailed mock data based on time range
  List<ChartDataPoint> _generateDetailedMockData(TimeRange timeRange) {
    final now = DateTime.now();
    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000;
    final baseValue = 1000.0 + random * 1000;
    final List<ChartDataPoint> data = [];
    
    int dataPoints;
    Duration interval;
    
    switch (timeRange) {
      case TimeRange.day:
        dataPoints = 24;
        interval = const Duration(hours: 1);
        break;
      case TimeRange.week:
        dataPoints = 7;
        interval = const Duration(days: 1);
        break;
      case TimeRange.month:
        dataPoints = 30;
        interval = const Duration(days: 1);
        break;
      case TimeRange.threeMonths:
        dataPoints = 12;
        interval = const Duration(days: 7);
        break;
      case TimeRange.sixMonths:
        dataPoints = 24;
        interval = const Duration(days: 7);
        break;
      case TimeRange.year:
        dataPoints = 12;
        interval = const Duration(days: 30);
        break;
      case TimeRange.fiveYears:
        dataPoints = 20;
        interval = const Duration(days: 90);
        break;
    }
    
    for (int i = dataPoints - 1; i >= 0; i--) {
      final point = ChartDataPoint(
        timestamp: now.subtract(interval * i),
        value: baseValue * (1 + 0.2 * (random - 0.5) * (dataPoints - i) / dataPoints),
      );
      data.add(point);
    }
    
    return data;
  }
}
