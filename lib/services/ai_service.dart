import 'dart:convert';
import 'package:finmate/models/budget.dart';
import 'package:finmate/models/ai_chat.dart';
import 'package:finmate/models/goal.dart';
import 'package:finmate/models/investment.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:finmate/models/ai_model.dart';

class AIService {
  // static final AIService _instance = AIService._internal();/
  final Logger _logger = Logger();
  final String _apiUrl = 'https://ai-models-api-eight.vercel.app/openai_api';
  final String _apiAccessKey = "123456789123456789";

  // Convert list of messages to the format expected by the API
  List<Map<String, String>> _formatMessages(List<ChatMessage> messages) {
    return messages
        .map((msg) => {
              'role': msg.isUser ? 'user' : 'assistant',
              'content': msg.content,
            })
        .toList();
  }

  // Send a message to the AI API
  Future<String> sendMessage({
    required String userMessage,
    required String selectedModel,
    required List<ChatMessage> messages,
    UserData? userData,
    UserFinanceData? userFinanceData,
    List<Budget>? budgets,
    List<Goal>? goals,
    List<Investment>? investments,
  }) async {
    try {
      // Get the model ID to use
      final modelId = AIModel.getModelId();
      _logger.i("Using AI model: $modelId");

      // Format the messages
      final formattedMessages = _formatMessages(messages);

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'model': modelId,
        'prompt': userMessage,
        'messages': formattedMessages,
        'system_prompt': getSystemPrompt(
          userData: userData,
          userFinanceData: userFinanceData,
          budgets: budgets,
          investments: investments,
        ),
        'temperature': 0.7,
        'max_tokens': 1000,
        'stream': false,
      };

      // Send the request to the API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': _apiAccessKey,
        },
        body: jsonEncode(requestBody),
      );

      // Handle response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String content = responseData['choices'][0]['message']['content'];
        return content;
      } else {
        _logger.e(
            "⛔ Error from AI API: ${response.statusCode} - ${response.body}");

        if (response.statusCode == 401) {
          return "Authentication error. Please check your API configuration.";
        } else if (response.statusCode == 429) {
          return "Rate limit exceeded. Please try again after a few moments.";
        } else if (response.statusCode >= 500) {
          return "Server error. Please try again later.";
        } else {
          return "An error occurred while communicating with the AI service. Please try again later.";
        }
      }
    } catch (e) {
      _logger.e("⛔ Error sending message to AI API: $e");
      return "An error occurred while communicating with the AI service. Please try again later.";
    }
  }

  // Helper method to convert ChatMessage objects to the format needed by the API
  List<Map<String, String>> convertMessages(List<ChatMessage> messages) {
    return _formatMessages(messages);
  }

  // Get the system prompt that defines the AI's behavior with enhanced user financial data
  String getSystemPrompt({
    UserData? userData,
    UserFinanceData? userFinanceData,
    List<Budget>? budgets,
    List<Goal>? goals,
    List<Investment>? investments,
  }) {
    String basePrompt =
        """You are FinMate AI, a helpful financial assistant integrated into the FinMate app.
You provide advice on personal finance, budgeting, investments, and financial planning.
Keep responses concise, practical, and focused on the user's financial goals and needs.
When giving investment advice, always include disclaimers about market risks.
For budgeting advice, focus on realistic and sustainable approaches.
Avoid giving specific legal or tax advice, and recommend consulting professionals when necessary.
Use a friendly but professional tone, and provide specific action steps when possible.

Always use "Rs." instead of the Rupee symbol (₹) when displaying currency values to avoid encoding issues.
For example, write "Rs.10,000" instead of "₹10,000".
Give responses in a clear and structured format, using bullet points or numbered lists when appropriate.
""";

    // Add user-specific information if available
    if (userData != null) {
      basePrompt += "\n\n### USER INFORMATION ###\n";
      basePrompt += "Name: ${userData.name}\n";
      basePrompt += "Email: ${userData.email}\n";
      if (userData.dob != null) {
        final age = DateTime.now().difference(userData.dob!).inDays ~/ 365;
        basePrompt += "Age: $age years\n";
      }
      if (userData.gender != null && userData.gender!.isNotEmpty) {
        basePrompt += "Gender: ${userData.gender}\n";
      }

      // Add cash information
      if (userFinanceData?.cash != null) {
        basePrompt += "\n### CASH BALANCE ###\n";
        basePrompt +=
            "Current Cash: Rs.${userFinanceData!.cash?.amount ?? '0'}\n";
      }

      // Add bank account information
      if (userFinanceData?.listOfBankAccounts != null &&
          userFinanceData!.listOfBankAccounts!.isNotEmpty) {
        basePrompt += "\n### BANK ACCOUNTS ###\n";
        double totalBankBalance = 0;
        for (var account in userFinanceData.listOfBankAccounts!) {
          basePrompt += "Account: ${account.bankAccountName}\n";
          basePrompt += "Available Balance: Rs.${account.availableBalance}\n";
          basePrompt += "Total Balance: Rs.${account.totalBalance}\n\n";
          totalBankBalance += double.parse(account.totalBalance ?? '0');
        }
        basePrompt += "Total Bank Balance: Rs.${totalBankBalance.toStringAsFixed(2)}\n";
      }

      // Add budget information with the updated structure
      if (budgets != null && budgets.isNotEmpty) {
        basePrompt += "\n### BUDGETS ###\n";

        // Get current month's budget
        final currentMonth = DateTime.now().month;
        final currentYear = DateTime.now().year;
        final currentBudget = budgets.firstWhere(
          (budget) =>
              budget.date?.month == currentMonth &&
              budget.date?.year == currentYear,
          orElse: () => Budget(),
        );

        if (currentBudget.bid != null && currentBudget.bid!.isNotEmpty) {
          basePrompt +=
              "Current Month's Budget: Rs.${currentBudget.totalBudget}\n";
          basePrompt += "Budget Spent: Rs.${currentBudget.spendings ?? '0'}\n";
          
          // Calculate remaining budget
          final totalBudget = double.parse(currentBudget.totalBudget ?? '0');
          final spent = double.parse(currentBudget.spendings ?? '0');
          final remaining = totalBudget - spent;
          final percentSpent = totalBudget > 0 ? (spent / totalBudget * 100).toStringAsFixed(1) : '0';
          
          basePrompt += "Budget Remaining: Rs.${remaining.toStringAsFixed(2)}\n";
          basePrompt += "Budget Utilization: $percentSpent%\n\n";

          // Category-wise budget breakdown with updated structure
          if (currentBudget.categoryBudgets != null &&
              currentBudget.categoryBudgets!.isNotEmpty) {
            basePrompt += "Category Budgets:\n";

            currentBudget.categoryBudgets!.forEach((category, detailsMap) {
              final allocated = detailsMap['allocated'] ?? '0';
              final spent = detailsMap['spent'] ?? '0';
              final remaining = detailsMap['remaining'] ?? '0';
              final percentage = detailsMap['percentage'] ?? '0';

              basePrompt += "- $category: \n";
              basePrompt += "  • Allocated: Rs.$allocated\n";
              basePrompt += "  • Spent: Rs.$spent\n";
              basePrompt += "  • Remaining: Rs.$remaining\n";
              basePrompt += "  • Usage: $percentage%\n";
            });
          }
        } else {
          basePrompt += "No budget set for the current month.\n";
        }
      }

      // Add goal information
      if (goals != null && goals.isNotEmpty) {
        basePrompt += "\n### FINANCIAL GOALS ###\n";
        double totalGoalAmount = 0;
        double totalSavedAmount = 0;
        
        for (var goal in goals) {
          basePrompt += "Goal: ${goal.name}\n";
          basePrompt += "Target Amount: Rs.${goal.targetAmount.toStringAsFixed(2)}\n";
          basePrompt += "Current Amount: Rs.${goal.currentAmount.toStringAsFixed(2)}\n";
          basePrompt += "Progress: ${(goal.progressPercentage * 100).toStringAsFixed(1)}%\n";
          
          if (goal.deadline != null) {
            final daysLeft = goal.deadline!.difference(DateTime.now()).inDays;
            basePrompt += "Days to Deadline: $daysLeft\n";
          }
          
          if (goal.notes != null && goal.notes!.isNotEmpty) {
            basePrompt += "Notes: ${goal.notes}\n";
          }
          
          basePrompt += "Status: ${goal.status.displayName}\n\n";
          
          totalGoalAmount += goal.targetAmount;
          totalSavedAmount += goal.currentAmount;
        }
        
        final overallProgress = totalGoalAmount > 0 
            ? (totalSavedAmount / totalGoalAmount * 100).toStringAsFixed(1) 
            : '0';
        basePrompt += "Overall Goal Progress: $overallProgress% (Rs.${totalSavedAmount.toStringAsFixed(2)} of Rs.${totalGoalAmount.toStringAsFixed(2)})\n";
      }

      // Add investment information
      if (investments != null && investments.isNotEmpty) {
        basePrompt += "\n### INVESTMENTS ###\n";
        double totalInvestmentValue = 0;
        double totalInvestedAmount = 0;

        // Group investments by type
        Map<String, List<Investment>> investmentsByType = {};
        for (var investment in investments) {
          if (!investmentsByType.containsKey(investment.type)) {
            investmentsByType[investment.type] = [];
          }
          investmentsByType[investment.type]!.add(investment);

          totalInvestmentValue += investment.currentAmount;
          totalInvestedAmount += investment.initialAmount;
        }

        // Overall investment summary
        basePrompt +=
            "Total Investment Value: Rs.${totalInvestmentValue.toStringAsFixed(2)}\n";
        basePrompt +=
            "Total Invested Amount: Rs.${totalInvestedAmount.toStringAsFixed(2)}\n";
        final netProfit = totalInvestmentValue - totalInvestedAmount;
        final netProfitPercentage = totalInvestedAmount > 0
            ? (netProfit / totalInvestedAmount) * 100
            : 0;
        basePrompt +=
            "Net Profit/Loss: Rs.${netProfit.toStringAsFixed(2)} (${netProfitPercentage.toStringAsFixed(2)}%)\n\n";

        // Details by investment type
        investmentsByType.forEach((type, typeInvestments) {
          double typeValue = 0;
          double typeAmount = 0;

          basePrompt += "$type Investments:\n";
          for (var investment in typeInvestments) {
            typeValue += investment.currentAmount; // Use currentAmount
            typeAmount += investment.initialAmount; // Use initialAmount

            basePrompt +=
                "- ${investment.name}: (current amount: Rs.${investment.currentAmount}) (invested: Rs.${investment.initialAmount})";
            
            // Add performance data if available
            if (investment.valueHistory.isNotEmpty && investment.valueHistory.length > 1) {
              final oldestValue = investment.valueHistory.first['value'] ?? investment.initialAmount;
              final latestValue = investment.currentAmount;
              final performancePercent = ((latestValue - oldestValue) / oldestValue * 100).toStringAsFixed(2);
              basePrompt += " (performance: $performancePercent%)";
            }
            
            basePrompt += "\n";
          }

          final typeProfit = typeValue - typeAmount;
          final typeProfitPercentage =
              typeAmount > 0 ? (typeProfit / typeAmount) * 100 : 0;
          basePrompt +=
              "  Summary: Value Rs.${typeValue.toStringAsFixed(2)}, Return ${typeProfitPercentage.toStringAsFixed(2)}%\n\n";
        });
      }

      // Add transaction summary
      if (userFinanceData?.listOfUserTransactions != null &&
          userFinanceData!.listOfUserTransactions!.isNotEmpty) {
        basePrompt += "\n### TRANSACTION SUMMARY ###\n";

        // Calculate total income and expenses for the current month
        double totalIncome = 0;
        double totalExpenses = 0;
        final currentMonth = DateTime.now().month;
        final currentYear = DateTime.now().year;
        
        // Monthly statistics
        Map<int, Map<String, double>> monthlyStats = {};
        
        // Category statistics for current month
        Map<String, double> categorySpending = {};
        Map<String, double> categoryIncome = {};

        for (var transaction in userFinanceData.listOfUserTransactions!) {
          // Skip null dates
          if (transaction.date == null) continue;
          
          // Get transaction month and year
          final transMonth = transaction.date!.month;
          final transYear = transaction.date!.year;
          
          // Create entry for this month if it doesn't exist
          if (!monthlyStats.containsKey(transMonth)) {
            monthlyStats[transMonth] = {'income': 0, 'expense': 0};
          }
          
          // Process by transaction type
          if (transaction.transactionType == TransactionType.income.displayName) {
            final amount = double.parse(transaction.amount ?? '0');
            
            // Add to monthly stats
            monthlyStats[transMonth]!['income'] = (monthlyStats[transMonth]!['income'] ?? 0) + amount;
            
            // Add to current month totals
            if (transMonth == currentMonth && transYear == currentYear) {
              totalIncome += amount;
              
              // Add to category income
              final category = transaction.category ?? 'Uncategorized';
              categoryIncome[category] = (categoryIncome[category] ?? 0) + amount;
            }
          } else if (transaction.transactionType == TransactionType.expense.displayName) {
            final amount = double.parse(transaction.amount?.replaceAll('-', '') ?? '0');
            
            // Add to monthly stats
            monthlyStats[transMonth]!['expense'] = (monthlyStats[transMonth]!['expense'] ?? 0) + amount;
            
            // Add to current month totals
            if (transMonth == currentMonth && transYear == currentYear) {
              totalExpenses += amount;
              
              // Add to category spending
              final category = transaction.category ?? 'Uncategorized';
              categorySpending[category] = (categorySpending[category] ?? 0) + amount;
            }
          }
        }

        basePrompt += "Current Month Income: Rs.${totalIncome.toStringAsFixed(2)}\n";
        basePrompt += "Current Month Expenses: Rs.${totalExpenses.toStringAsFixed(2)}\n";
        basePrompt += "Net Balance: Rs.${(totalIncome - totalExpenses).toStringAsFixed(2)}\n\n";
        
        // Monthly trend (last 3 months)
        basePrompt += "Monthly Trends (Last 3 Months):\n";
        final lastMonths = monthlyStats.keys.toList()..sort((a, b) => b.compareTo(a));
        final last3Months = lastMonths.take(3).toList();
        
        for (var month in last3Months) {
          final income = monthlyStats[month]!['income'] ?? 0;
          final expense = monthlyStats[month]!['expense'] ?? 0;
          final monthName = _getMonthName(month);
          
          basePrompt += "- $monthName: Income Rs.${income.toStringAsFixed(2)}, Expenses Rs.${expense.toStringAsFixed(2)}, Net Rs.${(income - expense).toStringAsFixed(2)}\n";
        }
        basePrompt += "\n";

        // Get top spending categories for current month
        var sortedSpendingCategories = categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedSpendingCategories.isNotEmpty) {
          basePrompt += "Top Spending Categories (Current Month):\n";
          final topCategories = sortedSpendingCategories.take(5);
          for (var entry in topCategories) {
            final percentage = totalExpenses > 0 
                ? (entry.value / totalExpenses * 100).toStringAsFixed(1) 
                : '0';
            basePrompt +=
                "- ${entry.key}: Rs.${entry.value.toStringAsFixed(2)} ($percentage% of total)\n";
          }
          basePrompt += "\n";
        }

        // Get top income categories for current month
        var sortedIncomeCategories = categoryIncome.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedIncomeCategories.isNotEmpty) {
          basePrompt += "Top Income Categories (Current Month):\n";
          final topIncomeCategories = sortedIncomeCategories.take(3);
          for (var entry in topIncomeCategories) {
            final percentage = totalIncome > 0 
                ? (entry.value / totalIncome * 100).toStringAsFixed(1) 
                : '0';
            basePrompt +=
                "- ${entry.key}: Rs.${entry.value.toStringAsFixed(2)} ($percentage% of total)\n";
          }
          basePrompt += "\n";
        }

        // Add detailed list of last 50 transactions
        basePrompt += "### DETAILED TRANSACTION HISTORY (LAST 50 TRANSACTIONS) ###\n";
        final recentTransactions = userFinanceData.listOfUserTransactions!
            .where((t) => t.date != null)
            .toList()
          ..sort((a, b) =>
              (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));

        final last50Transactions = recentTransactions.take(50).toList();
        
        // Group transactions by date
        Map<String, List<Transaction>> transactionsByDate = {};
        for (var transaction in last50Transactions) {
          final date = transaction.date!;
          final dateStr = "${date.day}/${date.month}/${date.year}";
          
          if (!transactionsByDate.containsKey(dateStr)) {
            transactionsByDate[dateStr] = [];
          }
          transactionsByDate[dateStr]!.add(transaction);
        }
        
        // List transactions by date
        final sortedDates = transactionsByDate.keys.toList()
          ..sort((a, b) {
            // Convert to DateTime for comparison (DD/MM/YYYY format)
            final partsA = a.split('/').map(int.parse).toList();
            final partsB = b.split('/').map(int.parse).toList();
            final dateA = DateTime(partsA[2], partsA[1], partsA[0]);
            final dateB = DateTime(partsB[2], partsB[1], partsB[0]);
            return dateB.compareTo(dateA);
          });
        
        for (var dateStr in sortedDates) {
          basePrompt += "\nDate: $dateStr\n";
          
          for (var transaction in transactionsByDate[dateStr]!) {
            final type = transaction.transactionType == TransactionType.income.displayName 
                ? "Income" 
                : (transaction.transactionType == TransactionType.expense.displayName 
                    ? "Expense" 
                    : "Transfer");
            
            final amount = transaction.amount?.replaceAll('-', '') ?? '0';
            final category = transaction.category ?? 'Uncategorized';
            final paymentMethod = transaction.methodOfPayment ?? 'Unknown';
            final description = transaction.description?.isNotEmpty == true 
                ? transaction.description 
                : "(No description)";
            
            basePrompt += "- [$type] Rs.$amount | Category: $category | Method: $paymentMethod";
            
            if (transaction.payee != null && transaction.payee!.isNotEmpty) {
              basePrompt += " | Payee: ${transaction.payee}";
            }
            
            if (transaction.bankAccountName != null && transaction.bankAccountName!.isNotEmpty) {
              basePrompt += " | Account: ${transaction.bankAccountName}";
            }
            
            basePrompt += " | $description\n";
          }
        }
      }

      // Add groups information
      if (userFinanceData?.listOfGroups != null &&
          userFinanceData!.listOfGroups!.isNotEmpty) {
        basePrompt += "\n### GROUP FINANCES ###\n";
        for (var group in userFinanceData.listOfGroups!) {
          basePrompt += "Group: ${group.name}\n";
          basePrompt += "Total Amount: Rs.${group.totalAmount}\n";
          basePrompt += "Your Balance: Rs.${group.membersBalance?[userData.uid]?['currentAmount'] ?? '0'}\n";
          
          if (group.listOfMembers != null && group.listOfMembers!.isNotEmpty) {
            basePrompt += "Members: ${group.listOfMembers!.length}\n";
          }
          
          if (group.listOfTransactions != null && group.listOfTransactions!.isNotEmpty) {
            basePrompt += "Recent Activity: ${group.listOfTransactions!.length} transactions\n";
          }
          
          basePrompt += "\n";
        }
      }

      basePrompt +=
          "\nUse this comprehensive information about the user's finances when providing personalized financial advice, but be respectful of their privacy. Do not recite all of their financial details back to them unless specifically asked. Focus on giving helpful, actionable advice based on their actual financial situation.";
    }
    _logger.i('System prompt generated: $basePrompt');

    // Estimate token count
    int tokenCount = estimateTokenCount(basePrompt);
    _logger.d('Estimated token count for system prompt: $tokenCount');

    return basePrompt;
  }
  
  // Helper method to get month name from month number
  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }

  // Simple token estimation - roughly 4 characters per token
  static int estimateTokenCount(String text) {
    return (text.length / 4).ceil();
  }
}
