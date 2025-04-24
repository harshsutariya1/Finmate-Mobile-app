import 'dart:convert';

import 'package:finmate/models/market_data.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class MarketApiService {
  final Logger _logger = Logger();
  
  // API Keys for different services
  // You should store these securely and not in code
  static const String _alphavantageApiKey = 'YOUR_ALPHA_VANTAGE_API_KEY';
  static const String _finnhubApiKey = 'YOUR_FINNHUB_API_KEY';
  
  // URLs for APIs
  static const String _alphavantageBaseUrl = 'https://www.alphavantage.co/query';
  static const String _finnhubBaseUrl = 'https://finnhub.io/api/v1';
  static const String _coingeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  
  // Get market indices data (NSE, BSE)
  Future<List<MarketIndex>> getMarketIndices() async {
    try {
      // In a real app, you'd make API calls to fetch real data
      // For now, we'll return mock data
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
    } catch (e) {
      _logger.e('Failed to fetch market indices: $e');
      throw Exception('Failed to fetch market indices');
    }
  }
  
  // Get popular stocks data
  Future<List<Stock>> getPopularStocks() async {
    try {
      // Mock data - replace with actual API call
      return [
        Stock(
          name: 'Reliance Industries',
          symbol: 'RELIANCE.NS',
          companyLogo: 'https://companieslogo.com/img/orig/RELIANCE.NS-c28acd1c.png',
          currentPrice: 2934.75,
          change: 18.55,
          changePercentage: 0.64,
          marketCap: 1986432000000, // 1.98T INR
          peRatio: 32.56,
          eps: 90.13,
          sector: 'Oil & Gas',
          historicalData: _generateMockHistoricalData(2900, 2950),
        ),
        Stock(
          name: 'Tata Consultancy Services',
          symbol: 'TCS.NS',
          companyLogo: 'https://companieslogo.com/img/orig/TCS.NS-7401f1bd.png',
          currentPrice: 3876.20,
          change: -23.40,
          changePercentage: -0.60,
          marketCap: 1420000000000, // 1.42T INR
          peRatio: 29.14,
          eps: 133.02,
          sector: 'IT Services',
          historicalData: _generateMockHistoricalData(3850, 3900),
        ),
        Stock(
          name: 'HDFC Bank',
          symbol: 'HDFCBANK.NS',
          companyLogo: 'https://companieslogo.com/img/orig/HDB-bb6241fe.png',
          currentPrice: 1682.45,
          change: 12.70,
          changePercentage: 0.76,
          marketCap: 1280000000000, // 1.28T INR
          peRatio: 23.86,
          eps: 70.51,
          sector: 'Banking',
          historicalData: _generateMockHistoricalData(1670, 1690),
        ),
        Stock(
          name: 'Infosys',
          symbol: 'INFY.NS',
          companyLogo: 'https://companieslogo.com/img/orig/INFY-7401e672.png',
          currentPrice: 1560.70,
          change: 5.30,
          changePercentage: 0.34,
          marketCap: 645000000000, // 645B INR
          peRatio: 25.23,
          eps: 61.86,
          sector: 'IT Services',
          historicalData: _generateMockHistoricalData(1550, 1570),
        ),
        Stock(
          name: 'ICICI Bank',
          symbol: 'ICICIBANK.NS',
          companyLogo: 'https://companieslogo.com/img/orig/IBN-af163749.png',
          currentPrice: 1052.85,
          change: -3.15,
          changePercentage: -0.30,
          marketCap: 735000000000, // 735B INR
          peRatio: 22.15,
          eps: 47.54,
          sector: 'Banking',
          historicalData: _generateMockHistoricalData(1045, 1060),
        ),
      ];
    } catch (e) {
      _logger.e('Failed to fetch popular stocks: $e');
      throw Exception('Failed to fetch popular stocks');
    }
  }

  // Search stocks by query
  Future<List<Stock>> searchStocks(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // In a real implementation, you would make an API call to search
      final allStocks = await getPopularStocks();
      return allStocks
          .where((stock) =>
              stock.name.toLowerCase().contains(query.toLowerCase()) ||
              stock.symbol.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      _logger.e('Failed to search stocks: $e');
      throw Exception('Failed to search stocks');
    }
  }

  // Get cryptocurrencies data
  Future<List<Cryptocurrency>> getCryptocurrencies() async {
    try {
      // Mock data - replace with actual API call
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
    } catch (e) {
      _logger.e('Failed to fetch cryptocurrencies: $e');
      throw Exception('Failed to fetch cryptocurrencies');
    }
  }

  // Get commodities data (Gold, Silver)
  Future<List<Commodity>> getCommodities() async {
    try {
      // Mock data - replace with actual API call
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
    } catch (e) {
      _logger.e('Failed to fetch commodities: $e');
      throw Exception('Failed to fetch commodities');
    }
  }

  // Get detailed historical data for a specific stock
  Future<List<ChartDataPoint>> getDetailedStockData(String symbol, TimeRange timeRange) async {
    try {
      // In a production app, you would make an API call to get real data
      // based on the symbol and time range
      return _generateDetailedMockData(timeRange);
    } catch (e) {
      _logger.e('Failed to fetch detailed stock data: $e');
      throw Exception('Failed to fetch detailed stock data');
    }
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
