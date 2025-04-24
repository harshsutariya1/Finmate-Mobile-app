import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/investment.dart';
import 'package:finmate/providers/investment_provider.dart';
import 'package:finmate/screens/home/investment%20screens/add_investment_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class InvestmentDetailsScreen extends ConsumerStatefulWidget {
  final Investment investment;

  const InvestmentDetailsScreen({
    super.key,
    required this.investment,
  });

  @override
  ConsumerState<InvestmentDetailsScreen> createState() =>
      _InvestmentDetailsScreenState();
}

class _InvestmentDetailsScreenState
    extends ConsumerState<InvestmentDetailsScreen> {
  late Investment investment;
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final dateFormat = DateFormat('dd MMM yyyy');
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    investment = widget.investment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
        title: Text(investment.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigate().push(
                AddInvestmentScreen(existingInvestment: investment),
              );
              // Refresh investment data
              final updatedInvestment = ref
                  .read(investmentNotifierProvider)
                  .firstWhere((i) => i.id == investment.id);
              setState(() {
                investment = updatedInvestment;
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: color3,
        onPressed: _showUpdateValueDialog,
        child: const Icon(Icons.update, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          sbh20,
          if (investment.valueHistory.length > 1) _buildPerformanceChart(),
          sbh20,
          _buildDetailsSection(),
          sbh20,
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final returnAmount = investment.totalReturn;
    final isPositive = returnAmount >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withAlpha(13), // Using withAlpha instead of withOpacity
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getColorForInvestmentType(investment.type).withAlpha(
                      51), // Using withAlpha instead of withOpacity(0.2)
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForInvestmentType(investment.type),
                  color: _getColorForInvestmentType(investment.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    Text(
                      investment.type,
                      style: TextStyle(
                        fontSize: 14,
                        color: color2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildValueColumn(
                  'Initial', currencyFormat.format(investment.initialAmount)),
              _buildValueColumn(
                  'Current', currencyFormat.format(investment.currentAmount)),
              _buildValueColumn(
                'Return',
                '${isPositive ? '+' : ''}${currencyFormat.format(returnAmount)}',
                textColor: isPositive ? Colors.green : Colors.red,
              ),
            ],
          ),
          sbh15,
          if (investment.targetAmount > 0) ...[
            const Divider(height: 24),
            Text(
              'Progress to Target: ${investment.progressPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                color: color2,
                fontWeight: FontWeight.bold,
              ),
            ),
            sbh10,
            LinearProgressIndicator(
              value: investment.progressPercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForInvestmentType(investment.type),
              ),
            ),
            sbh10,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹0',
                  style: TextStyle(fontSize: 12, color: color2),
                ),
                Text(
                  currencyFormat.format(investment.targetAmount),
                  style: TextStyle(fontSize: 12, color: color2),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValueColumn(String label, String value, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor ?? color1,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceChart() {
    if (investment.valueHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort history by date
    final history = List.from(investment.valueHistory);
    history.sort((a, b) {
      final dateA = (a['date'] as Timestamp).toDate();
      final dateB = (b['date'] as Timestamp).toDate();
      return dateA.compareTo(dateB);
    });

    // Create chart data
    final List<FlSpot> spots = [];
    final List<String> xLabels = [];

    // Find min and max values for Y axis scaling
    double minValue = double.infinity;
    double maxValue = -double.infinity;

    for (int i = 0; i < history.length; i++) {
      final entry = history[i];
      final date = (entry['date'] as Timestamp).toDate();
      final value = (entry['value'] as num).toDouble();

      spots.add(FlSpot(i.toDouble(), value));
      xLabels.add(DateFormat('dd MMM').format(date));

      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
    }

    // Add some padding to min and max for better visuals
    final padding = (maxValue - minValue) * 0.1;
    minValue = (minValue - padding).clamp(0, double.infinity);
    maxValue = maxValue + padding;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          sbh20,
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: (maxValue - minValue) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withAlpha(51),
                      strokeWidth: 1,
                    );
                  },
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
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % ((spots.length > 6) ? 2 : 1) != 0) {
                          return const SizedBox.shrink();
                        }
                        if (value.toInt() >= 0 &&
                            value.toInt() < xLabels.length) {
                          return Text(
                            xLabels[value.toInt()],
                            style: TextStyle(
                              color: color2,
                              fontSize: 10,
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
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _getColorForInvestmentType(investment.type),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: spots.length < 15),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getColorForInvestmentType(investment.type)
                          .withAlpha(51),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    // tooltipBgColor: Colors.white.withAlpha(204),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        final index = touchedSpot.x.toInt();
                        if (index >= 0 && index < history.length) {
                          final entry = history[index];
                          final date = (entry['date'] as Timestamp).toDate();
                          return LineTooltipItem(
                            '${DateFormat('dd MMM yy').format(date)}\n',
                            const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: currencyFormat.format(touchedSpot.y),
                                style: TextStyle(
                                  color: color1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
                minY: minValue,
                maxY: maxValue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          sbh15,
          _buildDetailRow(
            'Purchase Date',
            dateFormat.format(investment.purchaseDate),
            Icons.calendar_today,
          ),
          if (investment.maturityDate != null)
            _buildDetailRow(
              'Maturity Date',
              dateFormat.format(investment.maturityDate!),
              Icons.event,
            ),
          if (investment.institution.isNotEmpty)
            _buildDetailRow(
              'Institution/Broker',
              investment.institution,
              Icons.business,
            ),
          if (investment.accountNumber.isNotEmpty)
            _buildDetailRow(
              'Account/Reference Number',
              investment.accountNumber,
              Icons.numbers,
            ),
          if (investment.notes.isNotEmpty) ...[
            sbh10,
            Text(
              'Notes:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
            sbh5,
            Text(
              investment.notes,
              style: TextStyle(
                color: color2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color3,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: color2,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: color1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (investment.valueHistory.isEmpty || investment.valueHistory.length < 2) {
      return const SizedBox.shrink();
    }

    // Sort history by date in descending order (newest first)
    final history = List.from(investment.valueHistory);
    history.sort((a, b) {
      final dateA = (a['date'] as Timestamp).toDate();
      final dateB = (b['date'] as Timestamp).toDate();
      return dateB.compareTo(dateA);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Value History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          sbh15,
          ...history.asMap().entries.map((entry) {
            final item = entry.value;
            final date = (item['date'] as Timestamp).toDate();
            final value = (item['value'] as num).toDouble();
            final isFirst = entry.key == 0;
            final isPurchase = entry.key == history.length - 1;

            double changePercentage = 0;
            if (!isFirst) {
              final prevValue =
                  (history[entry.key - 1]['value'] as num).toDouble();
              changePercentage = ((value - prevValue) / prevValue) * 100;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPurchase
                          ? Colors.blue.withAlpha(51)
                          : (changePercentage >= 0
                              ? Colors.green.withAlpha(51)
                              : Colors.red.withAlpha(51)),
                    ),
                    child: Icon(
                      isPurchase
                          ? Icons.paid
                          : (changePercentage >= 0
                              ? Icons.trending_up
                              : Icons.trending_down),
                      color: isPurchase
                          ? Colors.blue
                          : (changePercentage >= 0 ? Colors.green : Colors.red),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPurchase ? 'Initial Purchase' : 'Value Update',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: color1,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(date),
                          style: TextStyle(
                            fontSize: 14,
                            color: color2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(value),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color1,
                        ),
                      ),
                      if (!isFirst)
                        Text(
                          '${changePercentage >= 0 ? '+' : ''}${changePercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: changePercentage >= 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getColorForInvestmentType(String type) {
    final colors = {
      'Stocks': Colors.blue,
      'Mutual Funds': Colors.green,
      'Fixed Deposits': Colors.amber,
      'Crypto': Colors.purple,
      'Gold': Colors.orange,
      'Real Estate': Colors.teal,
      'Others': Colors.grey,
    };

    return colors[type] ?? Colors.grey;
  }

  IconData _getIconForInvestmentType(String type) {
    final icons = {
      'Stocks': Icons.show_chart,
      'Mutual Funds': Icons.pie_chart,
      'Fixed Deposits': Icons.account_balance,
      'Crypto': Icons.currency_bitcoin,
      'Gold': Icons.monetization_on,
      'Real Estate': Icons.home,
      'Others': Icons.category,
    };

    return icons[type] ?? Icons.category;
  }

  void _showUpdateValueDialog() {
    final TextEditingController controller =
        TextEditingController(text: investment.currentAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Value'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Current Value',
            hintText: 'Enter the updated value',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newValue = double.tryParse(controller.text);
              if (newValue != null) {
                setState(() {
                  _isUpdating = true;
                });

                final success = await ref
                    .read(investmentNotifierProvider.notifier)
                    .updateInvestmentValue(
                        investment.uid, investment.id, newValue);

                if (success) {
                  // Refresh investment data
                  final updatedInvestment = ref
                      .read(investmentNotifierProvider)
                      .firstWhere((i) => i.id == investment.id);
                  setState(() {
                    investment = updatedInvestment;
                    _isUpdating = false;
                  });
                } else {
                  setState(() {
                    _isUpdating = false;
                  });
                }

                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
