import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/investment.dart';
import 'package:finmate/providers/investment_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/investment%20screens/add_investment_screen.dart';
import 'package:finmate/screens/home/investment%20screens/investment_details_screen.dart';
import 'package:finmate/screens/home/market%20screens/market_overview_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:finmate/screens/ai_assistant/ai_chat_screen.dart';

class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  late ScrollController _tabScrollController;
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  int _selectedInvestmentTypeFilter = 0;
  bool _isLoading = false;
  int _selectedPieSection = -1;
  
  final List<String> investmentTypeTabs = [
    'All',
    'Stocks',
    'Mutual Funds',
    'Fixed Deposits',
    'Crypto',
    'Gold',
    'Real Estate',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: investmentTypeTabs.length, vsync: this);
    _pageController = PageController(initialPage: _selectedInvestmentTypeFilter);
    _tabScrollController = ScrollController();
    _loadInvestments();
    
    // Connect tab controller to selection
    _tabController.addListener(_handleTabSelection);
  }
  
  void _handleTabSelection() {
    if (_tabController.indexIsChanging || _tabController.index != _selectedInvestmentTypeFilter) {
      setState(() {
        _selectedInvestmentTypeFilter = _tabController.index;
        // Animate to the selected page without jumping
        _pageController.animateToPage(
          _selectedInvestmentTypeFilter,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        
        // Scroll tab into view
        _scrollToSelectedTab();
      });
    }
  }

  void _scrollToSelectedTab() {
    // Calculate the approximate position of the selected tab
    // This estimation assumes all tabs have similar width
    final tabWidth = 100.0;  // Approximate width of each tab including padding
    final screenWidth = MediaQuery.of(context).size.width;
    final maxOffset = _tabScrollController.position.maxScrollExtent;
    
    // Calculate target position (center the selected tab)
    double targetPosition = (tabWidth * _selectedInvestmentTypeFilter) - (screenWidth / 2) + (tabWidth / 2);
    
    // Clamp the position to valid scroll bounds
    targetPosition = targetPosition.clamp(0.0, maxOffset);
    
    // Animate to the position
    if (_tabScrollController.hasClients) {
      _tabScrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _pageController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInvestments() async {
    setState(() => _isLoading = true);
    final userData = ref.read(userDataNotifierProvider);
    await ref.read(investmentNotifierProvider.notifier).loadInvestments(userData.uid ?? '');
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final investments = ref.watch(investmentNotifierProvider);
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
        elevation: 1, // Add subtle elevation
        title: const Text(
          'Investments',
          style: TextStyle(fontWeight: FontWeight.bold, color: color1),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.trending_up, color: color3),
          //   tooltip: 'Market Overview',
          //   onPressed: () {
          //     Navigate().push(const MarketOverviewScreen());
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, color: color3),
            tooltip: 'AI Assistant',
            onPressed: () {
              Navigate().push(const AIChatScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: color3),
            tooltip: 'Add Investment',
            onPressed: () => Navigate().push(const AddInvestmentScreen()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildCustomTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : investments.isEmpty
                    ? _buildEmptyState()
                    : _buildPageView(investments),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _tabScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: investmentTypeTabs.asMap().entries.map((entry) {
            final index = entry.key;
            final title = entry.value;
            final isSelected = index == _selectedInvestmentTypeFilter;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedInvestmentTypeFilter = index;
                  _tabController.animateTo(index);
                  
                  // Scroll to the selected tab in the CustomTabBar
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  
                  // Ensure selected tab is visible
                  _scrollToSelectedTab();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color3 : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color2,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance,
            size: 80,
            color: color2.withAlpha(150),
          ),
          sbh15,
          Text(
            "No investments yet",
            style: TextStyle(
              color: color2,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          sbh10,
          Text(
            "Add your first investment to start tracking",
            style: TextStyle(
              color: color2.withAlpha(180),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          sbh20,
          ElevatedButton(
            onPressed: () => Navigate().push(const AddInvestmentScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: color3,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Add Investment"),
          ),
          sbh10,
          ElevatedButton.icon(
            onPressed: () {
              Navigate().push(const AIChatScreen());
            },
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            label: const Text(
              "AI Assistant",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(List<Investment> allInvestments) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _selectedInvestmentTypeFilter = index;
          _tabController.animateTo(index);
        });
      },
      itemCount: investmentTypeTabs.length,
      itemBuilder: (context, index) {
        // Filter investments based on selected tab
        final List<Investment> filteredInvestments = index == 0
            ? allInvestments
            : allInvestments.where(
                (investment) => investment.type == investmentTypeTabs[index],
              ).toList();
              
        return _buildInvestmentsDashboard(filteredInvestments);
      },
    );
  }
  
  Widget _buildInvestmentsDashboard(List<Investment> filteredInvestments) {
    // Calculate portfolio totals
    final double totalInvested = filteredInvestments.fold(
        0, (sum, investment) => sum + investment.initialAmount);
    final double currentValue = filteredInvestments.fold(
        0, (sum, investment) => sum + investment.currentAmount);
    final double totalReturn = currentValue - totalInvested;
    final double returnPercentage = totalInvested > 0
        ? (totalReturn / totalInvested) * 100
        : 0;
    
    // Portfolio allocation data for chart
    Map<String, double> investmentTypeAllocation = {};
    for (var investment in filteredInvestments) {
      final type = investment.type;
      if (investmentTypeAllocation.containsKey(type)) {
        investmentTypeAllocation[type] = 
            investmentTypeAllocation[type]! + investment.currentAmount;
      } else {
        investmentTypeAllocation[type] = investment.currentAmount;
      }
    }
    
    return RefreshIndicator(
      onRefresh: _loadInvestments,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPortfolioSummary(totalInvested, currentValue, totalReturn, returnPercentage),
          sbh20,
          _buildPortfolioAllocation(investmentTypeAllocation, currentValue),
          sbh20,
          _buildInvestmentsList(filteredInvestments),
        ],
      ),
    );
  }
  
  Widget _buildPortfolioSummary(
      double totalInvested, double currentValue, double totalReturn, double returnPercentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // Changed to withAlpha
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Current Value',
                currencyFormat.format(currentValue),
                Icons.account_balance_wallet,
                color3,
              ),
              _buildSummaryItem(
                'Total Invested',
                currencyFormat.format(totalInvested),
                Icons.savings,
                color2,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Total Return',
                '${totalReturn >= 0 ? '+' : ''}${currencyFormat.format(totalReturn)}',
                totalReturn >= 0 ? Icons.trending_up : Icons.trending_down,
                totalReturn >= 0 ? Colors.green : Colors.red,
              ),
              _buildSummaryItem(
                'Return %',
                '${returnPercentage.toStringAsFixed(2)}%',
                returnPercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                returnPercentage >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
            color: color.withAlpha(26), // Adjusted from withOpacity(0.1)
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPortfolioAllocation(Map<String, double> allocation, double totalValue) {
    if (allocation.isEmpty || totalValue == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // Changed to withAlpha
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portfolio Allocation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color1,
                ),
              ),
              Text(
                'Total: ${currencyFormat.format(totalValue)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 55,
                    sections: _getPieChartSections(allocation, totalValue),
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _selectedPieSection = -1;
                            return;
                          }
                          _selectedPieSection = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 750),
                  swapAnimationCurve: Curves.easeInOutQuint,
                ),
                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Allocation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color2,
                      ),
                    ),
                    Text(
                      allocation.length.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    Text(
                      'Types',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: _buildEnhancedLegendItems(allocation, totalValue),
            ),
          ),
        ],
      ),
    );
  }
  
  List<PieChartSectionData> _getPieChartSections(
      Map<String, double> allocation, double totalValue) {
    final entries = allocation.entries.toList();
    // Sort by largest value first for better visualization
    entries.sort((a, b) => b.value.compareTo(a.value));
    
    return List.generate(entries.length, (i) {
      final entry = entries[i];
      final percentage = entry.value / totalValue * 100;
      final color = _getColorForInvestmentType(entry.key);
      final isSelected = i == _selectedPieSection;
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '', // Remove text from chart sections for cleaner look
        radius: isSelected ? 90 : 60, // Expand selected section
        titleStyle: const TextStyle(
          fontSize: 0,  // No text inside sections
        ),
        badgeWidget: isSelected ? _buildEnhancedBadge(entry.key, percentage) : null,
        badgePositionPercentageOffset: 1.05,
      );
    });
  }
  
  Widget _buildEnhancedBadge(String type, double percentage) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color1,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 10,
              color: color2,
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildEnhancedLegendItems(Map<String, double> allocation, double totalValue) {
    final entries = allocation.entries.toList();
    // Sort by largest value first
    entries.sort((a, b) => b.value.compareTo(a.value));
    
    return entries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final percentage = entry.value / totalValue * 100;
      final color = _getColorForInvestmentType(entry.key);
      final isSelected = index == _selectedPieSection;
      
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedPieSection = _selectedPieSection == index ? -1 : index;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(26) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: color1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : color2,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                currencyFormat.format(entry.value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color1,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
  
  Color _getColorForInvestmentType(String type) {
    // Enhanced color palette with more vibrant colors
    final colors = {
      'Stocks': const Color(0xFF2E7DD1),
      'Mutual Funds': const Color(0xFF38C976),
      'Fixed Deposits': const Color(0xFFFAC12F),
      'Crypto': const Color(0xFF9C42F5),
      'Gold': const Color(0xFFFF9234),
      'Real Estate': const Color(0xFF0CCCB0),
      'Others': const Color(0xFF607D8B),
    };
    
    return colors[type] ?? Colors.grey;
  }
  
  Widget _buildInvestmentsList(List<Investment> investments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Investments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color1,
          ),
        ),
        sbh15,
        ...investments.map((investment) => _buildInvestmentCard(investment)),
      ],
    );
  }
  
  Widget _buildInvestmentCard(Investment investment) {
    final double returnAmount = investment.currentAmount - investment.initialAmount;
    final double returnPercentage = 
        investment.initialAmount > 0 ? (returnAmount / investment.initialAmount) * 100 : 0;
    
    return GestureDetector(
      onTap: () => Navigate().push(
        InvestmentDetailsScreen(investment: investment),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(8), // Changed from withOpacity(0.03)
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getColorForInvestmentType(investment.type).withAlpha(51), // Adjusted from withOpacity(0.2)
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForInvestmentType(investment.type),
                    color: _getColorForInvestmentType(investment.type),
                    size: 20,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        investment.type,
                        style: TextStyle(
                          fontSize: 12,
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
                      currencyFormat.format(investment.currentAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          returnAmount >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: returnAmount >= 0 ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        Text(
                          '${returnPercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: returnAmount >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            sbh10,
            LinearProgressIndicator(
              value: investment.progressPercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                returnAmount >= 0 ? Colors.green : Colors.red,
              ),
            ),
            sbh10,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invested: ${currencyFormat.format(investment.initialAmount)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: color2,
                  ),
                ),
                if (investment.targetAmount > 0)
                  Text(
                    'Target: ${currencyFormat.format(investment.targetAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: color2,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
}

// Badge widget for pie chart
class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // Adjusted from withOpacity(0.1)
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}