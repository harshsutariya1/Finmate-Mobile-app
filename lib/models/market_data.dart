
class MarketIndex {
  final String name;
  final String symbol;
  final double currentValue;
  final double change;
  final double changePercentage;
  final List<ChartDataPoint> historicalData;

  MarketIndex({
    required this.name,
    required this.symbol,
    required this.currentValue,
    required this.change,
    required this.changePercentage,
    required this.historicalData,
  });

  bool get isPositive => change >= 0;
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'symbol': symbol,
      'currentValue': currentValue,
      'change': change,
      'changePercentage': changePercentage,
      'historicalData': historicalData.map((point) => point.toJson()).toList(),
    };
  }
}

class Stock {
  final String name;
  final String symbol;
  final String companyLogo;
  final double currentPrice;
  final double change;
  final double changePercentage;
  final double marketCap;
  final double peRatio;
  final double eps;
  final String sector;
  final List<ChartDataPoint> historicalData;
  final Map<String, dynamic>? additionalInfo;

  Stock({
    required this.name,
    required this.symbol,
    this.companyLogo = '',
    required this.currentPrice,
    required this.change,
    required this.changePercentage,
    required this.marketCap,
    this.peRatio = 0,
    this.eps = 0,
    this.sector = '',
    required this.historicalData,
    this.additionalInfo,
  });

  bool get isPositive => change >= 0;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'symbol': symbol,
      'companyLogo': companyLogo,
      'currentPrice': currentPrice,
      'change': change,
      'changePercentage': changePercentage,
      'marketCap': marketCap,
      'peRatio': peRatio,
      'eps': eps,
      'sector': sector,
      'historicalData': historicalData.map((point) => point.toJson()).toList(),
      'additionalInfo': additionalInfo,
    };
  }
}

class Cryptocurrency {
  final String name;
  final String symbol;
  final String image;
  final double currentPrice;
  final double change;
  final double changePercentage;
  final double marketCap;
  final double volume24h;
  final double circulatingSupply;
  final List<ChartDataPoint> historicalData;

  Cryptocurrency({
    required this.name,
    required this.symbol,
    required this.image,
    required this.currentPrice,
    required this.change,
    required this.changePercentage,
    required this.marketCap,
    required this.volume24h,
    required this.circulatingSupply,
    required this.historicalData,
  });

  bool get isPositive => change >= 0;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'symbol': symbol,
      'image': image,
      'currentPrice': currentPrice,
      'change': change,
      'changePercentage': changePercentage,
      'marketCap': marketCap,
      'volume24h': volume24h,
      'circulatingSupply': circulatingSupply,
      'historicalData': historicalData.map((point) => point.toJson()).toList(),
    };
  }
}

class Commodity {
  final String name;
  final String symbol;
  final double currentPrice;
  final double change;
  final double changePercentage;
  final String unit;
  final List<ChartDataPoint> historicalData;

  Commodity({
    required this.name,
    required this.symbol,
    required this.currentPrice,
    required this.change,
    required this.changePercentage,
    required this.unit,
    required this.historicalData,
  });

  bool get isPositive => change >= 0;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'symbol': symbol,
      'currentPrice': currentPrice,
      'change': change,
      'changePercentage': changePercentage,
      'unit': unit,
      'historicalData': historicalData.map((point) => point.toJson()).toList(),
    };
  }
}

class ChartDataPoint {
  final DateTime timestamp;
  final double value;

  ChartDataPoint({
    required this.timestamp,
    required this.value,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
    };
  }
}

enum TimeRange {
  day,
  week,
  month,
  threeMonths,
  sixMonths,
  year,
  fiveYears,
}

extension TimeRangeExtension on TimeRange {
  String get label {
    switch (this) {
      case TimeRange.day:
        return '1D';
      case TimeRange.week:
        return '1W';
      case TimeRange.month:
        return '1M';
      case TimeRange.threeMonths:
        return '3M';
      case TimeRange.sixMonths:
        return '6M';
      case TimeRange.year:
        return '1Y';
      case TimeRange.fiveYears:
        return '5Y';
    }
  }

  Duration get duration {
    switch (this) {
      case TimeRange.day:
        return const Duration(days: 1);
      case TimeRange.week:
        return const Duration(days: 7);
      case TimeRange.month:
        return const Duration(days: 30);
      case TimeRange.threeMonths:
        return const Duration(days: 90);
      case TimeRange.sixMonths:
        return const Duration(days: 180);
      case TimeRange.year:
        return const Duration(days: 365);
      case TimeRange.fiveYears:
        return const Duration(days: 365 * 5);
    }
  }
}
