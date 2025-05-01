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
  Set<String> _selectedCategories = {}; // Changed from String? to Set<String>
  String? _selectedBankAccount;
  String? _sortOption;
  bool _hasActiveFilters = false;
  
  // Create a map for category search controllers to prevent disposal issues
  final Map<String, TextEditingController> _categorySearchControllers = {};

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
    
    // Dispose all category search controllers
    for (var controller in _categorySearchControllers.values) {
      controller.dispose();
    }
    _categorySearchControllers.clear();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
    if (_selectedCategories.isNotEmpty) {
      monthlyTransactions = monthlyTransactions
          .where((transaction) => 
              _selectedCategories.contains(transaction.category))
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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
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
                          color: color3.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color3.withAlpha(77))),
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
                                _selectedCategories = {};
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
      margin: EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color3.withAlpha(204), color2.withAlpha(179)],
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
            color: color3.withAlpha(26),
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
                  color: color3.withAlpha(77),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
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
              color: Colors.grey.withAlpha(128),
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

    // Sort categories alphabetically for better dropdown experience
    final sortedCategories = categories.toList()..sort();

    // Local variables to track selections in the dialog
    Set<String> tempCategories = Set.from(_selectedCategories); // Create a copy of the selected categories
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
                      maxHeight: MediaQuery.of(context).size.height * 0.5, // Reduced from 0.6
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Replace dropdown with category selector button
                          _buildFilterSectionHeader('Categories'),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: _buildCategorySelector(
                              sortedCategories,
                              tempCategories,
                              (newCategories) {
                                setDialogState(() {
                                  tempCategories = newCategories;
                                });
                              },
                            ),
                          ),

                          Divider(height: 1, thickness: 1, color: Colors.grey[200]),

                          // Bank accounts section - Keep the existing pattern
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
                            key: ValueKey('sort_default'),
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
                            key: ValueKey('sort_asc'),
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
                            key: ValueKey('sort_desc'),
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
                              tempCategories = {};
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
                              _selectedCategories = tempCategories;
                              _selectedBankAccount = tempBankAccount;
                              _sortOption = tempSortOption;
                              _hasActiveFilters = tempCategories.isNotEmpty ||
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
  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap, {Key? key}) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? color3 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
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

  // Replace the dropdown with a button that opens a searchable category selector
  Widget _buildCategorySelector(
    List<String> categories,
    Set<String> selectedCategories,
    Function(Set<String>) onCategoriesSelected,
  ) {
    return InkWell(
      onTap: () {
        _showCategoryMultiSelectDialog(categories, selectedCategories, onCategoriesSelected);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedCategories.isEmpty 
                    ? 'All Categories' 
                    : selectedCategories.length == 1
                        ? selectedCategories.first
                        : '${selectedCategories.length} Categories Selected',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selectedCategories.isNotEmpty ? color2 : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.filter_list, color: color3, size: 20),
          ],
        ),
      ),
    );
  }

  // Add a new method to show the multi-select category dialog
  void _showCategoryMultiSelectDialog(
    List<String> categories,
    Set<String> selectedCategories,
    Function(Set<String>) onCategoriesSelected,
  ) {
    // Create a unique key for this dialog instance
    final String dialogKey = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create or retrieve controller for this instance
    if (!_categorySearchControllers.containsKey(dialogKey)) {
      _categorySearchControllers[dialogKey] = TextEditingController();
    }
    final searchController = _categorySearchControllers[dialogKey]!;
    
    List<String> filteredCategories = List.from(categories);
    Set<String> tempSelectedCategories = Set.from(selectedCategories);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color1,
                        ),
                      ),
                      // Show selected count
                      if (tempSelectedCategories.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color3.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${tempSelectedCategories.length} selected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Search box
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (query) {
                        setState(() {
                          if (query.isEmpty) {
                            filteredCategories = List.from(categories);
                          } else {
                            filteredCategories = categories
                                .where((cat) =>
                                    cat.toLowerCase().contains(query.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search categories...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  // "Select All" and "Clear All" buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              tempSelectedCategories = Set.from(filteredCategories);
                            });
                          },
                          icon: Icon(Icons.select_all, size: 18, color: color3),
                          label: Text('Select All', style: TextStyle(color: color3)),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              tempSelectedCategories = {};
                            });
                          },
                          icon: Icon(Icons.clear_all, size: 18, color: color3),
                          label: Text('Clear All', style: TextStyle(color: color3)),
                        ),
                      ],
                    ),
                  ),
                  
                  // Category list with checkboxes
                  Flexible(
                    child: filteredCategories.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No categories match your search',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              final isSelected = tempSelectedCategories.contains(category);
                              
                              return CheckboxListTile(
                                key: ValueKey('category_${category}_$index'),
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      tempSelectedCategories.add(category);
                                    } else {
                                      tempSelectedCategories.remove(category);
                                    }
                                  });
                                },
                                title: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: color1,
                                  ),
                                ),
                                secondary: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getCategoryColor(category).withAlpha(26),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(category), 
                                    color: _getCategoryColor(category), 
                                    size: 18
                                  ),
                                ),
                                activeColor: color3,
                                checkColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                dense: true,
                                controlAffinity: ListTileControlAffinity.trailing,
                              );
                            },
                          ),
                  ),
                  
                  // Footer buttons
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            onCategoriesSelected(tempSelectedCategories);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Apply', style: TextStyle(color: Colors.white)),
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
    ).then((_) {
      searchController.clear();
    });
  }

  // Helper method to get a color for a category (based on category name hash)
  Color _getCategoryColor(String category) {
    final colors = [
      color3,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final index = category.hashCode % colors.length;
    return colors[index.abs()];
  }

  // Helper method to get an icon for a category
  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    
    if (categoryLower.contains('food') || categoryLower.contains('grocery')) {
      return Icons.restaurant;
    } else if (categoryLower.contains('transport') || categoryLower.contains('travel')) {
      return Icons.directions_car;
    } else if (categoryLower.contains('shopping')) {
      return Icons.shopping_bag;
    } else if (categoryLower.contains('bill') || categoryLower.contains('utility')) {
      return Icons.receipt;
    } else if (categoryLower.contains('entertainment') || categoryLower.contains('movie')) {
      return Icons.movie;
    } else if (categoryLower.contains('health') || categoryLower.contains('medical')) {
      return Icons.medical_services;
    } else if (categoryLower.contains('education')) {
      return Icons.school;
    } else if (categoryLower.contains('income') || categoryLower.contains('salary')) {
      return Icons.attach_money;
    } else if (categoryLower.contains('transfer')) {
      return Icons.swap_horiz;
    }
    
    return Icons.category;
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
              color: Colors.grey.withAlpha(128),
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
                  _selectedCategories = {};
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

    if (_selectedCategories.isNotEmpty) {
      if (_selectedCategories.length == 1) {
        activeFilters.add('Category: ${_selectedCategories.first}');
      } else {
        activeFilters.add('Categories: ${_selectedCategories.length} selected');
      }
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
