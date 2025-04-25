
enum TimeRange {
  intraday('1 Day', 'TIME_SERIES_INTRADAY', '60min', 1),
  daily('1 Week', 'TIME_SERIES_DAILY', null, 7),
  weekly('1 Month', 'TIME_SERIES_WEEKLY', null, 30),
  monthly('3 Months', 'TIME_SERIES_MONTHLY', null, 90),
  quarterly('6 Months', 'TIME_SERIES_MONTHLY', null, 180),
  yearly('1 Year', 'TIME_SERIES_MONTHLY', null, 365);

  final String label;
  final String functionName;
  final String? interval;
  final int days;
  
  const TimeRange(this.label, this.functionName, this.interval, this.days);
}

class ChartDataPoint {
  final DateTime timestamp;
  final double value;
  final double? open;
  final double? high;
  final double? low;
  final double? volume;
  
  ChartDataPoint({
    required this.timestamp, 
    required this.value,
    this.open,
    this.high,
    this.low,
    this.volume,
  });
  
  factory ChartDataPoint.fromAlphaVantage(String date, Map<String, dynamic> json) {
    // Alpha Vantage returns different formats based on the endpoint
    // For time series data
    if (json.containsKey('1. open')) {
      return ChartDataPoint(
        timestamp: DateTime.parse(date),
        value: double.parse(json['4. close']),
        open: double.parse(json['1. open']),
        high: double.parse(json['2. high']),
        low: double.parse(json['3. low']),
        volume: json['5. volume'] != null ? double.parse(json['5. volume']) : null,
      );
    } 
    // For digital currency
    else if (json.containsKey('1a. open (USD)')) {
      return ChartDataPoint(
        timestamp: DateTime.parse(date),
        value: double.parse(json['4a. close (USD)']),
        open: double.parse(json['1a. open (USD)']),
        high: double.parse(json['2a. high (USD)']),
        low: double.parse(json['3a. low (USD)']),
        volume: json['5. volume'] != null ? double.parse(json['5. volume']) : null,
      );
    } 
    // For global quote
    else if (json.containsKey('05. price')) {
      final dateString = json['07. latest trading day'] ?? date;
      return ChartDataPoint(
        timestamp: DateTime.parse(dateString),
        value: double.parse(json['05. price']),
        open: double.parse(json['02. open']),
        high: double.parse(json['03. high']),
        low: double.parse(json['04. low']),
        volume: double.parse(json['06. volume']),
      );
    }
    else {
      // Fallback
      return ChartDataPoint(
        timestamp: DateTime.parse(date),
        value: 0.0,
      );
    }
  }
}

abstract class MarketEntity {
  final String symbol;
  final String name;
  final double currentValue;
  final double change;
  final double changePercentage;
  
  MarketEntity({
    required this.symbol,
    required this.name,
    required this.currentValue,
    required this.change,
    required this.changePercentage,
  });
  
  bool get isPositive => change >= 0;
}

class MarketIndex extends MarketEntity {
  final String type;
  final String country;
  
  MarketIndex({
    required super.symbol,
    required super.name,
    required super.currentValue,
    required super.change,
    required super.changePercentage,
    required this.type,
    required this.country,
  });
  
  factory MarketIndex.fromJson(Map<String, dynamic> json) {
    double price = double.tryParse(json['05. price'] ?? '0.0') ?? 0.0;
    double change = double.tryParse(json['09. change'] ?? '0.0') ?? 0.0;
    double changePercent = double.tryParse(
      (json['10. change percent'] as String?)?.replaceAll('%', '') ?? '0.0'
    ) ?? 0.0;
    
    return MarketIndex(
      symbol: json['01. symbol'] ?? '',
      name: json['name'] ?? json['01. symbol'] ?? '',
      currentValue: price,
      change: change,
      changePercentage: changePercent,
      type: json['type'] ?? 'equity',
      country: json['country'] ?? 'US',
    );
  }
  
  // Factory method specifically for Alpha Vantage global quote data
  factory MarketIndex.fromAlphaVantageQuote(String symbol, String name, Map<String, dynamic> json) {
    Map<String, dynamic> quote = json['Global Quote'] ?? {};
    double price = double.tryParse(quote['05. price'] ?? '0.0') ?? 0.0;
    double change = double.tryParse(quote['09. change'] ?? '0.0') ?? 0.0;
    double changePercent = double.tryParse(
      (quote['10. change percent'] as String?)?.replaceAll('%', '') ?? '0.0'
    ) ?? 0.0;
    
    return MarketIndex(
      symbol: symbol,
      name: name,
      currentValue: price,
      change: change,
      changePercentage: changePercent,
      type: 'equity',
      country: 'US',
    );
  }
}

class Stock extends MarketEntity {
  final String companyLogo;
  final String sector;
  final double marketCap;
  final double peRatio;
  final double eps;
  final double? beta;
  final double? dividend;
  final double? volume;

  Stock({
    required super.symbol,
    required super.name,
    required super.currentValue,
    required super.change,
    required super.changePercentage,
    required this.companyLogo,
    required this.sector,
    required this.marketCap,
    required this.peRatio,
    required this.eps,
    this.beta,
    this.dividend,
    this.volume,
  });
  
  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['01. symbol'] ?? json['Symbol'] ?? '',
      name: json['Name'] ?? json['01. symbol'] ?? '',
      currentValue: double.tryParse(json['05. price'] ?? '0.0') ?? 0.0,
      change: double.tryParse(json['09. change'] ?? '0.0') ?? 0.0,
      changePercentage: double.tryParse(
        (json['10. change percent'] as String?)?.replaceAll('%', '') ?? '0.0'
      ) ?? 0.0,
      companyLogo: json['companyLogo'] ?? '',
      sector: json['Sector'] ?? '',
      marketCap: double.tryParse(json['MarketCapitalization'] ?? '0.0') ?? 0.0,
      peRatio: double.tryParse(json['PERatio'] ?? '0.0') ?? 0.0,
      eps: double.tryParse(json['EPS'] ?? '0.0') ?? 0.0,
      beta: double.tryParse(json['Beta'] ?? '0'),
      dividend: double.tryParse(json['DividendYield'] ?? '0'),
      volume: double.tryParse(json['06. volume'] ?? '0'),
    );
  }
  
  // Factory method specifically for Alpha Vantage data
  factory Stock.fromAlphaVantage(Map<String, dynamic> quote, Map<String, dynamic> overview) {
    Map<String, dynamic> globalQuote = quote['Global Quote'] ?? {};
    
    return Stock(
      symbol: globalQuote['01. symbol'] ?? overview['Symbol'] ?? '',
      name: overview['Name'] ?? globalQuote['01. symbol'] ?? '',
      currentValue: double.tryParse(globalQuote['05. price'] ?? '0.0') ?? 0.0,
      change: double.tryParse(globalQuote['09. change'] ?? '0.0') ?? 0.0,
      changePercentage: double.tryParse(
        (globalQuote['10. change percent'] as String?)?.replaceAll('%', '') ?? '0.0'
      ) ?? 0.0,
      companyLogo: '', // Alpha Vantage doesn't provide logos
      sector: overview['Sector'] ?? '',
      marketCap: double.tryParse(overview['MarketCapitalization'] ?? '0.0') ?? 0.0,
      peRatio: double.tryParse(overview['PERatio'] ?? '0.0') ?? 0.0,
      eps: double.tryParse(overview['EPS'] ?? '0.0') ?? 0.0,
      beta: double.tryParse(overview['Beta'] ?? '0'),
      dividend: double.tryParse(overview['DividendYield'] ?? '0'),
      volume: double.tryParse(globalQuote['06. volume'] ?? '0'),
    );
  }
}

class Cryptocurrency extends MarketEntity {
  final String image;
  final double marketCap;
  final double volume24h;
  final double circulatingSupply;

  Cryptocurrency({
    required super.symbol,
    required super.name,
    required super.currentValue,
    required super.change,
    required super.changePercentage,
    required this.image,
    required this.marketCap,
    required this.volume24h,
    required this.circulatingSupply,
  });

  factory Cryptocurrency.fromJson(Map<String, dynamic> json) {
    return Cryptocurrency(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      currentValue: double.tryParse(json['currentValue']?.toString() ?? '0.0') ?? 0.0,
      change: double.tryParse(json['change']?.toString() ?? '0.0') ?? 0.0,
      changePercentage: double.tryParse(json['changePercentage']?.toString() ?? '0.0') ?? 0.0,
      image: json['image'] ?? '',
      marketCap: double.tryParse(json['marketCap']?.toString() ?? '0.0') ?? 0.0,
      volume24h: double.tryParse(json['volume24h']?.toString() ?? '0.0') ?? 0.0,
      circulatingSupply: double.tryParse(json['circulatingSupply']?.toString() ?? '0.0') ?? 0.0,
    );
  }
  
  factory Cryptocurrency.fromAlphaVantage(Map<String, dynamic> data) {
    final Map<String, dynamic> rateInfo = 
        data['Realtime Currency Exchange Rate'] ?? {};
    
    final double currentValue = double.tryParse(
        rateInfo['5. Exchange Rate'] ?? '0.0') ?? 0.0;
    
    // For crypto, AlphaVantage doesn't provide change directly, so using placeholder
    final double change = 0.0;
    final double changePercentage = 0.0;
    
    return Cryptocurrency(
      symbol: rateInfo['1. From_Currency Code'] ?? '',
      name: rateInfo['2. From_Currency Name'] ?? '',
      currentValue: currentValue,
      change: change,
      changePercentage: changePercentage,
      image: '', // Alpha Vantage doesn't provide images
      marketCap: 0.0, // Not available in basic Alpha Vantage data
      volume24h: 0.0, // Not available in basic Alpha Vantage data
      circulatingSupply: 0.0, // Not available in basic Alpha Vantage data
    );
  }
}

class Commodity extends MarketEntity {
  final String unit;

  Commodity({
    required super.symbol,
    required super.name,
    required super.currentValue,
    required super.change,
    required super.changePercentage,
    required this.unit,
  });

  factory Commodity.fromJson(Map<String, dynamic> json) {
    return Commodity(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      currentValue: double.tryParse(json['currentValue']?.toString() ?? '0.0') ?? 0.0,
      change: double.tryParse(json['change']?.toString() ?? '0.0') ?? 0.0,
      changePercentage: double.tryParse(json['changePercentage']?.toString() ?? '0.0') ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }
  
  factory Commodity.fromAlphaVantageForex(Map<String, dynamic> data, String commodityName, String unit) {
    final Map<String, dynamic> rateInfo = 
        data['Realtime Currency Exchange Rate'] ?? {};
    
    final double currentValue = double.tryParse(
        rateInfo['5. Exchange Rate'] ?? '0.0') ?? 0.0;
    
    // For commodities via forex, AlphaVantage doesn't provide change directly
    final double change = 0.0;
    final double changePercentage = 0.0;
    
    return Commodity(
      symbol: rateInfo['1. From_Currency Code'] ?? '',
      name: commodityName,
      currentValue: currentValue,
      change: change,
      changePercentage: changePercentage,
      unit: unit,
    );
  }
}

class MarketSearchResult {
  final String symbol;
  final String name;
  final String type; // 'stock', 'index', 'crypto', 'commodity'
  final String? image;
  final double currentValue;
  final double change;
  final double changePercentage;

  MarketSearchResult({
    required this.symbol,
    required this.name,
    required this.type,
    this.image,
    required this.currentValue,
    required this.change,
    required this.changePercentage,
  });

  bool get isPositive => change >= 0;
  
  factory MarketSearchResult.fromAlphaVantageSearch(Map<String, dynamic> data) {
    final symbol = data['1. symbol'] as String? ?? '';
    final name = data['2. name'] as String? ?? '';
    String type = 'stock';
    
    // Try to determine the type based on the data
    final dataType = data['3. type']?.toString().toLowerCase() ?? '';
    if (dataType.contains('etf') || dataType.contains('fund')) {
      type = 'index';
    } else if (dataType.contains('crypto')) {
      type = 'crypto';
    } else if (dataType.contains('commodity')) {
      type = 'commodity';
    }
    
    return MarketSearchResult(
      symbol: symbol,
      name: name,
      type: type,
      image: null,
      currentValue: 0, // These would be populated in a separate API call
      change: 0,
      changePercentage: 0,
    );
  }
}
