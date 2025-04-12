import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/transaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AllTransactionsScreen extends ConsumerStatefulWidget {
  const AllTransactionsScreen({super.key, required this.transactionsList});
  final List<Transaction> transactionsList;

  @override
  ConsumerState<AllTransactionsScreen> createState() =>
      _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  // Initialize to current month (0-indexed)
  late int _selectedIndex;
  late PageController _pageController;

  // Add search functionality
  final Map<int, String> _searchQueries = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Add filter state variables
  String? _selectedCategory;
  String? _selectedBankAccount;
  String? _sortOption;
  bool _hasActiveFilters = false;

  List<String> monthsTabTitles = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  @override
  void initState() {
    super.initState();
    // Get the current month (1-12) and convert to 0-indexed (0-11)
    _selectedIndex = DateTime.now().month - 1;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: _buildAppBar(),
      body: _buildTransactionPageView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: color4,
      title: const Text('Transactions'),
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: color1,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      actions: [
        // Add filter button
        IconButton(
          icon: Stack(
            children: [
              Icon(Icons.filter_list, color: color3),
              if (_hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 10,
                      minHeight: 10,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _showFilterOptions,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomTabBar(
          selectedIndex: _selectedIndex,
          tabTitles: monthsTabTitles,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildTransactionPageView() {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      itemCount: monthsTabTitles.length,
      itemBuilder: (context, index) {
        return _buildMonthlyTransactionList(index + 1); // Month is 1-indexed
      },
    );
  }

// __________________________________________________________________________ //

  Widget _buildMonthlyTransactionList(int month) {
    // Filter transactions for the selected month
    List<Transaction> monthlyTransactions = _filterTransactionsByMonth(month);

    // Sort transactions by date and time in descending order
    monthlyTransactions.sort((a, b) {
      int dateComparison = b.date!.compareTo(a.date!);
      if (dateComparison != 0) {
        return dateComparison;
      } else {
        return b.time!.format(context).compareTo(a.time!.format(context));
      }
    });

    // Apply category and bank account filters
    if (_selectedCategory != null) {
      monthlyTransactions = monthlyTransactions
          .where((transaction) => transaction.category == _selectedCategory)
          .toList();
    }

    if (_selectedBankAccount != null) {
      monthlyTransactions = monthlyTransactions
          .where((transaction) =>
              transaction.bankAccountName == _selectedBankAccount)
          .toList();
    }

    // Apply sorting if selected
    if (_sortOption != null) {
      if (_sortOption == 'amount_asc') {
        monthlyTransactions.sort((a, b) {
          return double.parse(a.amount?.replaceAll('-', '') ?? '0')
              .compareTo(double.parse(b.amount?.replaceAll('-', '') ?? '0'));
        });
      } else if (_sortOption == 'amount_desc') {
        monthlyTransactions.sort((a, b) {
          return double.parse(b.amount?.replaceAll('-', '') ?? '0')
              .compareTo(double.parse(a.amount?.replaceAll('-', '') ?? '0'));
        });
      }
    }

    // Apply search filter
    final searchQuery = _searchQueries[month] ?? '';
    final filteredTransactions = searchQuery.isEmpty
        ? monthlyTransactions
        : monthlyTransactions.where((transaction) {
            final description = transaction.description?.toLowerCase() ?? '';
            final category = transaction.category?.toLowerCase() ?? '';
            final payee = transaction.payee?.toLowerCase() ?? '';
            final amount = transaction.amount ?? '';

            return description.contains(searchQuery.toLowerCase()) ||
                category.contains(searchQuery.toLowerCase()) ||
                payee.contains(searchQuery.toLowerCase()) ||
                amount.contains(searchQuery);
          }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: monthlyTransactions.isEmpty
          ? _buildEmptyState(month)
          : SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSummary(monthlyTransactions),
                  sbh15,
                  // Add active filters indicator
                  if (_hasActiveFilters)
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: color3.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color3.withOpacity(0.3))),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, size: 16, color: color3),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _getActiveFiltersText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: color3,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = null;
                                _selectedBankAccount = null;
                                _sortOption = null;
                                _hasActiveFilters = false;
                              });
                            },
                            child: Icon(Icons.close, size: 16, color: color3),
                          ),
                        ],
                      ),
                    ),
                  _buildSearchBar(month),
                  sbh10,
                  filteredTransactions.isEmpty && searchQuery.isNotEmpty
                      ? _buildNoSearchResults(searchQuery)
                      : filteredTransactions.isEmpty
                          ? _buildNoFilterResults()
                          : _buildTransactionsByDate(filteredTransactions),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(int month) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: color2.withAlpha(150),
          ),
          sbh15,
          Text(
            "No transactions in ${monthsTabTitles[month - 1]}",
            style: TextStyle(
              color: color2,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          sbh10,
          Text(
            "Add your first transaction by tapping the + button",
            style: TextStyle(
              color: color2.withAlpha(180),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummary(List<Transaction> transactions) {
    // Calculate month summary
    double income = 0;
    double expense = 0;

    for (var transaction in transactions) {
      if (transaction.transactionType == TransactionType.income.displayName) {
        income += double.parse(transaction.amount ?? "0.0");
      } else if (transaction.transactionType ==
          TransactionType.expense.displayName) {
        expense +=
            double.parse(transaction.amount?.replaceAll('-', '') ?? "0.0")
                .abs();
      }
    }

    double balance = income - expense;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color3.withOpacity(0.8), color2.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color2.withAlpha(40),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                  "Income", income, Colors.white, Icons.arrow_upward_rounded),
              _buildSummaryItem("Expense", expense, Colors.white,
                  Icons.arrow_downward_rounded),
            ],
          ),
          Divider(color: Colors.white.withAlpha(120), height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSummaryItem(
                "Balance",
                balance,
                Colors.white,
                balance >= 0
                    ? Icons.account_balance_wallet
                    : Icons.warning_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String title, double amount, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          "₹ ${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsByDate(List<Transaction> transactions) {
    // Group transactions by date
    Map<String, List<Transaction>> groupedTransactions = {};

    for (var transaction in transactions) {
      String dateKey = transaction.date!.toString().split(' ')[0];
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    // Sort dates in descending order
    List<String> sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    return Column(
      children: sortedDates.map((date) {
        return _buildDateGroup(date, groupedTransactions[date]!);
      }).toList(),
    );
  }

  Widget _buildDateGroup(String dateString, List<Transaction> transactions) {
    DateTime date = DateTime.parse(dateString);
    String formattedDate = _getFormattedDate(date);

    // Calculate total for this date
    double dailyTotal = 0;
    for (var transaction in transactions) {
      dailyTotal += double.parse(transaction.amount ?? "0.0");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 12, bottom: 8),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: color3.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color1,
                ),
              ),
              Text(
                "₹ ${dailyTotal.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: dailyTotal >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        ...transactions.map((transaction) {
          return transactionTile(context, transaction, ref);
        }),
      ],
    );
  }

  String _getFormattedDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime yesterday = DateTime(now.year, now.month, now.day - 1);

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Today";
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return "Yesterday";
    } else {
      // Format: "Mon, 21 Jan"
      return "${_getDayOfWeek(date.weekday)}, ${date.day} ${monthsTabTitles[date.month - 1].substring(0, 3)}";
    }
  }

  String _getDayOfWeek(int day) {
    List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[day - 1];
  }

  List<Transaction> _filterTransactionsByMonth(int month) {
    List<Transaction> filteredTransactions = [];

    // Get current year
    int currentYear = DateTime.now().year;

    for (var transaction in widget.transactionsList) {
      if (transaction.date != null &&
          transaction.date!.month == month &&
          transaction.date!.year == currentYear) {
        filteredTransactions.add(transaction);
      }
    }

    return filteredTransactions;
  }

  Widget _buildSearchBar(int month) {
    // When the page changes, update the search controller text
    if (_searchController.text != (_searchQueries[month] ?? '')) {
      _searchController.text = _searchQueries[month] ?? '';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: _isSearching
            ? [
                BoxShadow(
                  color: color3.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQueries[month] = value;
          });
        },
        onTap: () {
          setState(() {
            _isSearching = true;
          });
        },
        onSubmitted: (_) {
          setState(() {
            _isSearching = false;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          prefixIcon: Icon(
            Icons.search,
            color: _isSearching ? color3 : Colors.grey,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQueries[month] = '';
                      _isSearching = false;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 70,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No results found for "$query"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add method to show filter options
  void _showFilterOptions() {
    // Get all unique categories and bank accounts for filtering
    final allTransactions = widget.transactionsList;
    final Set<String> categories = {};
    final Set<String> bankAccounts = {};

    for (var transaction in allTransactions) {
      if (transaction.category != null && transaction.category!.isNotEmpty) {
        categories.add(transaction.category!);
      }

      if (transaction.bankAccountName != null &&
          transaction.bankAccountName!.isNotEmpty) {
        bankAccounts.add(transaction.bankAccountName!);
      }
    }

    // Local variables to track selections in the dialog
    String? tempCategory = _selectedCategory;
    String? tempBankAccount = _selectedBankAccount;
    String? tempSortOption = _sortOption;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: color3,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Content - Scrollable area
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categories section
                          _buildFilterSectionHeader('Categories'),
                          _buildFilterOption(
                            'All Categories',
                            tempCategory == null,
                            () {
                              setDialogState(() {
                                tempCategory = null;
                              });
                            },
                          ),
                          ...categories.map((category) => _buildFilterOption(
                                category,
                                tempCategory == category,
                                () {
                                  setDialogState(() {
                                    tempCategory = (tempCategory == category)
                                        ? null
                                        : category;
                                  });
                                },
                              )),

                          Divider(
                              height: 1, thickness: 1, color: Colors.grey[200]),

                          // Bank accounts section
                          _buildFilterSectionHeader('Bank Accounts'),
                          _buildFilterOption(
                            'All Accounts',
                            tempBankAccount == null,
                            () {
                              setDialogState(() {
                                tempBankAccount = null;
                              });
                            },
                          ),
                          ...bankAccounts.map((account) => _buildFilterOption(
                                account,
                                tempBankAccount == account,
                                () {
                                  setDialogState(() {
                                    tempBankAccount =
                                        (tempBankAccount == account)
                                            ? null
                                            : account;
                                  });
                                },
                              )),

                          Divider(
                              height: 1, thickness: 1, color: Colors.grey[200]),

                          // Sort options
                          _buildFilterSectionHeader('Sort By'),
                          _buildFilterOption(
                            'Date (Default)',
                            tempSortOption == null,
                            () {
                              setDialogState(() {
                                tempSortOption = null;
                              });
                            },
                          ),
                          _buildFilterOption(
                            'Amount: Low to High',
                            tempSortOption == 'amount_asc',
                            () {
                              setDialogState(() {
                                tempSortOption =
                                    (tempSortOption == 'amount_asc')
                                        ? null
                                        : 'amount_asc';
                              });
                            },
                          ),
                          _buildFilterOption(
                            'Amount: High to Low',
                            tempSortOption == 'amount_desc',
                            () {
                              setDialogState(() {
                                tempSortOption =
                                    (tempSortOption == 'amount_desc')
                                        ? null
                                        : 'amount_desc';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer with buttons
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Reset button
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempCategory = null;
                              tempBankAccount = null;
                              tempSortOption = null;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(color: color3),
                          ),
                        ),
                        // Apply button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCategory = tempCategory;
                              _selectedBankAccount = tempBankAccount;
                              _sortOption = tempSortOption;
                              _hasActiveFilters = tempCategory != null ||
                                  tempBankAccount != null ||
                                  tempSortOption != null;
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Apply',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper widget for filter section headers
  Widget _buildFilterSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 8),
      color: Colors.grey[50],
      width: double.infinity,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color2,
        ),
      ),
    );
  }

  // Helper widget for filter options with checkbox
  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? color3 : Colors.black87,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color3 : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? color3 : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // New widget to show when no results match the filter
  Widget _buildNoFilterResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 70,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No transactions match the filters',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedBankAccount = null;
                  _sortOption = null;
                  _hasActiveFilters = false;
                });
              },
              child: Text(
                'Clear filters',
                style: TextStyle(
                  fontSize: 14,
                  color: color3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to show text of active filters
  String _getActiveFiltersText() {
    List<String> activeFilters = [];

    if (_selectedCategory != null) {
      activeFilters.add('Category: $_selectedCategory');
    }

    if (_selectedBankAccount != null) {
      activeFilters.add('Account: $_selectedBankAccount');
    }

    if (_sortOption != null) {
      activeFilters.add(
          'Sort: ${_sortOption == 'amount_asc' ? 'Amount (Low-High)' : 'Amount (High-Low)'}');
    }

    return activeFilters.join(' • ');
  }
}
