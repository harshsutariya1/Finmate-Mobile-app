import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/market_data.dart';
import 'package:finmate/providers/market_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TouchedSpot {
  final LineBarSpot spot;
  final int barIndex;

  TouchedSpot(this.spot, this.barIndex);
}

class MarketDetailScreen extends ConsumerStatefulWidget {
  final String name;
  final String symbol;
  final String type; // 'index', 'stock', 'crypto', 'commodity'

  const MarketDetailScreen({
    super.key,
    required this.name,
    required this.symbol,
    required this.type,
  });

  @override
  ConsumerState<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends ConsumerState<MarketDetailScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final percentFormat = NumberFormat('+0.00%;-0.00%');
  final numberFormat = NumberFormat('#,##0.00');
  
  // For chart touch data
  TouchedSpot? _touchedSpot;
  
  @override
  Widget build(BuildContext context) {
    final timeRange = ref.watch(selectedTimeRangeProvider);
    final detailDataAsync = ref.watch(detailedStockDataProvider(widget.symbol));
    
    // Get entity-specific data based on type
    dynamic entityData;
    if (widget.type == 'index') {
      final indices = ref.watch(marketIndicesProvider).valueOrNull ?? [];
      entityData = indices.where((i) => i.symbol == widget.symbol).firstOrNull;
    } else if (widget.type == 'stock') {
      final stocks = ref.watch(popularStocksProvider).valueOrNull ?? [];
      entityData = stocks.where((s) => s.symbol == widget.symbol).firstOrNull;
    } else if (widget.type == 'crypto') {
      final cryptos = ref.watch(cryptocurrenciesProvider).valueOrNull ?? [];
      entityData = cryptos.where((c) => c.symbol == widget.symbol).firstOrNull;
    } else if (widget.type == 'commodity') {
      final commodities = ref.watch(commoditiesProvider).valueOrNull ?? [];
      entityData = commodities.where((c) => c.symbol == widget.symbol).firstOrNull;
    }
    
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(detailedStockDataProvider(widget.symbol));
              if (widget.type == 'index') {
                ref.invalidate(marketIndicesProvider);
              } else if (widget.type == 'stock') {
                ref.invalidate(popularStocksProvider);
              } else if (widget.type == 'crypto') {
                ref.invalidate(cryptocurrenciesProvider);
              } else if (widget.type == 'commodity') {
                ref.invalidate(commoditiesProvider);
              }
            },
          ),
        ],
      ),
      body: entityData == null
          ? const Center(child: CircularProgressIndicator())
          : _buildDetailView(entityData, timeRange, detailDataAsync),
    );
  }
  
  Widget _buildDetailView(dynamic entityData, TimeRange timeRange, AsyncValue<List<ChartDataPoint>> detailDataAsync) {
    final bool isPositive = entityData.isPositive;
    final Color valueColor = isPositive ? Colors.green : Colors.red;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderSection(entityData, valueColor),
        sbh20,
        _buildChartSection(detailDataAsync, isPositive),
        sbh20,
        _buildTimeRangeSelector(timeRange),
        sbh20,
        _buildAdditionalInfo(entityData),
      ],
    );
  }
  
  Widget _buildHeaderSection(dynamic entityData, Color valueColor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEntityIcon(entityData),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color1,
                        ),
                      ),
                      Text(
                        widget.symbol,
                        style: TextStyle(
                          fontSize: 14,
                          color: color2,
                        ),
                      ),
                      if (widget.type == 'stock')
                        Text(
                          entityData.sector,
                          style: TextStyle(
                            fontSize: 14,
                            color: color3,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Value',
                        style: TextStyle(
                          fontSize: 14,
                          color: color2,
                        ),
                      ),
                      Text(
                        currencyFormat.format(entityData.currentPrice ?? entityData.currentValue),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color1,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          entityData.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: valueColor,
                        ),
                        Text(
                          entityData.isPositive
                              ? '+${numberFormat.format(entityData.change)}'
                              : numberFormat.format(entityData.change),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: valueColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${entityData.changePercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEntityIcon(dynamic entityData) {
    // For Stock
    if (widget.type == 'stock' && entityData.companyLogo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          entityData.companyLogo,
          width: 50,
          height: 50,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.business,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    // For Crypto
    if (widget.type == 'crypto' && entityData.image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          entityData.image,
          width: 50,
          height: 50,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.currency_bitcoin,
            size: 50,
            color: Colors.amber,
          ),
        ),
      );
    }
    
    // For commodity
    if (widget.type == 'commodity') {
      IconData icon;
      Color iconColor;
      
      switch (entityData.name.toLowerCase()) {
        case 'gold':
          icon = Icons.monetization_on;
          iconColor = Colors.amber;
          break;
        case 'silver':
          icon = Icons.brightness_medium;
          iconColor = Colors.blueGrey;
          break;
        case 'crude oil':
          icon = Icons.local_gas_station;
          iconColor = Colors.brown;
          break;
        default:
          icon = Icons.grain;
          iconColor = Colors.grey;
      }
      
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 30,
          color: iconColor,
        ),
      );
    }
    
    // For indices & default
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color3.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.show_chart,
        size: 30,
        color: color3,
      ),
    );
  }
  
  Widget _buildChartSection(AsyncValue<List<ChartDataPoint>> detailDataAsync, bool isPositive) {
    final chartColor = isPositive ? Colors.green : Colors.red;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price Chart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color1,
                  ),
                ),
                if (_touchedSpot != null)
                  Text(
                    currencyFormat.format(_touchedSpot!.spot.y),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: chartColor,
                    ),
                  ),
              ],
            ),
            sbh15,
            SizedBox(
              height: 250,
              child: detailDataAsync.when(
                data: (data) => _buildChart(data, chartColor),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading chart data: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<ChartDataPoint> data, Color chartColor) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    
    // Calculate min and max values for scaling
    final List<double> values = data.map((point) => point.value).toList();
    double minValue = values.reduce((a, b) => a < b ? a : b);
    double maxValue = values.reduce((a, b) => a > b ? a : b);
    
    // Add padding to min/max
    final padding = (maxValue - minValue) * 0.1;
    minValue = (minValue - padding).clamp(0, double.infinity);
    maxValue = maxValue + padding;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: (maxValue - minValue) / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Format big numbers better
                String text;
                if (value >= 1000000) {
                  text = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  text = '${(value / 1000).toStringAsFixed(1)}K';
                } else {
                  text = value.toInt().toString();
                }
                return Text(
                  text,
                  style: TextStyle(
                    color: color2,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: data.length > 10 ? (data.length / 5).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index >= 0 && index < data.length && index % ((data.length > 10) ? 5 : 1) == 0) {
                  final DateTime date = data[index].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: TextStyle(
                        color: color2,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            left: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minValue,
        maxY: maxValue,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.white,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].timestamp;
                  return LineTooltipItem(
                    '${DateFormat('dd MMM yyyy').format(date)}\n',
                    TextStyle(
                      color: color2,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: currencyFormat.format(spot.y),
                        style: TextStyle(
                          color: chartColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }
                return null;
              }).toList();
            },
          ),
          touchCallback: (event, response) {
            if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
              setState(() => _touchedSpot = null);
              return;
            }
            if (event is FlPanEndEvent || event is FlTapUpEvent) {
              setState(() => _touchedSpot = null);
              return;
            }
            setState(() => _touchedSpot = TouchedSpot(
              response.lineBarSpots!.first,
              response.lineBarSpots!.first.barIndex,
            ));
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(
                i.toDouble(),
                data[i].value,
              ),
            ),
            isCurved: true,
            barWidth: 3,
            color: chartColor,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withOpacity(0.15),
              gradient: LinearGradient(
                colors: [
                  chartColor.withOpacity(0.25),
                  chartColor.withOpacity(0.01),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeRangeSelector(TimeRange currentRange) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: TimeRange.values.map((range) {
            final isSelected = range == currentRange;
            return _buildTimeRangeChip(range.label, range, isSelected);
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildTimeRangeChip(String text, TimeRange range, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedTimeRangeProvider.notifier).state = range;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color3 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color3 : color2.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : color2,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  Widget _buildAdditionalInfo(dynamic entityData) {
    if (entityData == null) return const SizedBox.shrink();
    
    // Different layouts based on entity type
    if (widget.type == 'stock') {
      return _buildStockAdditionalInfo(entityData);
    } else if (widget.type == 'crypto') {
      return _buildCryptoAdditionalInfo(entityData);
    } else if (widget.type == 'commodity') {
      return _buildCommodityAdditionalInfo(entityData);
    } else {
      return _buildIndexAdditionalInfo(entityData);
    }
  }
  
  Widget _buildStockAdditionalInfo(dynamic stock) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh15,
            _buildInfoRow('Market Cap', currencyFormat.format(stock.marketCap)),
            _buildInfoRow('P/E Ratio', numberFormat.format(stock.peRatio)),
            _buildInfoRow('EPS', numberFormat.format(stock.eps)),
            _buildInfoRow('Sector', stock.sector),
            
            sbh20,
            Text(
              'About the Company',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh10,
            Text(
              _getCompanyDescription(stock.name),
              style: TextStyle(
                fontSize: 14,
                color: color2,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCryptoAdditionalInfo(dynamic crypto) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cryptocurrency Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh15,
            _buildInfoRow('Market Cap', currencyFormat.format(crypto.marketCap)),
            _buildInfoRow('24h Volume', currencyFormat.format(crypto.volume24h)),
            _buildInfoRow('Circulating Supply', '${numberFormat.format(crypto.circulatingSupply)} ${crypto.symbol}'),
            sbh20,
            Text(
              'About this Cryptocurrency',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh10,
            Text(
              _getCryptoDescription(crypto.name),
              style: TextStyle(
                fontSize: 14,
                color: color2,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommodityAdditionalInfo(dynamic commodity) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commodity Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh15,
            _buildInfoRow('Unit', commodity.unit),
            _buildInfoRow('Yearly Change', '${commodity.changePercentage >= 0 ? '+' : ''}${commodity.changePercentage.toStringAsFixed(2)}%'),
            sbh20,
            Text(
              'About this Commodity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh10,
            Text(
              _getCommodityDescription(commodity.name),
              style: TextStyle(
                fontSize: 14,
                color: color2,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIndexAdditionalInfo(dynamic index) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Index Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh15,
            _buildInfoRow('Daily Change', '${numberFormat.format(index.change)} (${index.changePercentage.toStringAsFixed(2)}%)'),
            _buildInfoRow('Open', numberFormat.format(index.currentValue - index.change)),
            _buildInfoRow('Previous Close', numberFormat.format((index.currentValue - index.change) * 0.997)),
            sbh20,
            Text(
              'About this Index',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh10,
            Text(
              _getIndexDescription(index.name),
              style: TextStyle(
                fontSize: 14,
                color: color2,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: color2,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: color1,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getCompanyDescription(String name) {
    // Mock data - in a real app, this would come from an API
    final descriptions = {
      'Reliance Industries': 'Reliance Industries Limited is an Indian multinational conglomerate company headquartered in Mumbai. It has diverse businesses including energy, petrochemicals, natural gas, retail, telecommunications, mass media, and textiles.',
      'Tata Consultancy Services': 'Tata Consultancy Services is an Indian multinational information technology services and consulting company headquartered in Mumbai. It is part of the Tata Group and operates in 149 locations across 46 countries.',
      'HDFC Bank': 'HDFC Bank Limited is an Indian banking and financial services company headquartered in Mumbai. It is India\'s largest private sector bank by assets and market capitalization.',
      'Infosys': 'Infosys Limited is an Indian multinational corporation that provides business consulting, information technology and outsourcing services. The company is headquartered in Bangalore.',
      'ICICI Bank': 'ICICI Bank Limited is an Indian multinational banking and financial services company headquartered in Mumbai. It offers a wide range of banking products and financial services to corporate and retail customers.',
    };
    return descriptions[name] ?? 'A publicly traded company on the Indian stock exchange.';
  }
  
  String _getCryptoDescription(String name) {
    // Mock data
    final descriptions = {
      'Bitcoin': 'Bitcoin is the first decentralized cryptocurrency, introduced in 2009. It operates on blockchain technology, allowing peer-to-peer transactions without a central authority.',
      'Ethereum': 'Ethereum is a decentralized, open-source blockchain with smart contract functionality. Launched in 2015, it enables developers to build and deploy decentralized applications.',
      'Tether': 'Tether is a cryptocurrency that is pegged to the value of fiat currencies like USD, EUR, and JPY. It aims to maintain price stability, making it classified as a stablecoin.',
    };
    return descriptions[name] ?? 'A cryptocurrency operating on blockchain technology.';
  }
  
  String _getCommodityDescription(String name) {
    // Mock data
    final descriptions = {
      'Gold': 'Gold is a precious metal used throughout history as a store of value and in jewelry. It\'s considered a safe-haven investment during economic uncertainty.',
      'Silver': 'Silver is both a precious and industrial metal, with uses ranging from jewelry to electronics. It historically has been used as currency.',
      'Crude Oil': 'Crude oil is a naturally occurring fossil fuel composed of hydrocarbon deposits. It\'s refined to make various petroleum products like gasoline, diesel, and plastic.',
    };
    return descriptions[name] ?? 'A widely traded physical commodity with both industrial and investment applications.';
  }
  
  String _getIndexDescription(String name) {
    // Mock data
    final descriptions = {
      'NSE NIFTY 50': 'The NIFTY 50 is the flagship index of the National Stock Exchange of India, representing the weighted average of 50 of the largest Indian companies across various sectors.',
      'BSE SENSEX': 'The S&P BSE SENSEX is a free-float market-weighted stock market index of 30 well-established companies listed on the Bombay Stock Exchange, representing various industrial sectors.',
      'NIFTY Bank': 'The NIFTY Bank index represents the 12 most liquid and large capitalized stocks from the banking sector trading on the National Stock Exchange.',
    };
    return descriptions[name] ?? 'A market index tracking the performance of a specific segment of the stock market.';
  }
}
