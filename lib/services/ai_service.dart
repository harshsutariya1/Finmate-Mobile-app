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
        for (var account in userFinanceData.listOfBankAccounts!) {
          basePrompt += "Account: ${account.bankAccountName}\n";
          basePrompt += "Available Balance: Rs.${account.availableBalance}\n";
          basePrompt += "Total Balance: Rs.${account.totalBalance}\n\n";
        }
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
          basePrompt +=
              "Budget Remaining: Rs.${double.parse(currentBudget.totalBudget ?? '0') - double.parse(currentBudget.spendings ?? '0')}\n\n";

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
        basePrompt += "\n### GOALS ###\n";
        for (var goal in goals) {
          basePrompt += "Goal: ${goal.name}\n";
          basePrompt +=
              "Target Amount: Rs.${goal.targetAmount}\nCurrent Amount: Rs.${goal.currentAmount}\n";
        }
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
                "- ${investment.name}: (current amount: Rs.${investment.currentAmount}) (invested: Rs.${investment.initialAmount})\n"; // Use correct fields
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

        for (var transaction in userFinanceData.listOfUserTransactions!) {
          if (transaction.date?.month == currentMonth &&
              transaction.date?.year == currentYear) {
            if (transaction.transactionType ==
                TransactionType.income.displayName) {
              totalIncome += double.parse(transaction.amount ?? '0');
            } else if (transaction.transactionType ==
                TransactionType.expense.displayName) {
              totalExpenses +=
                  double.parse(transaction.amount?.replaceAll('-', '') ?? '0');
            }
          }
        }

        basePrompt += "Current Month Income: Rs.$totalIncome\n";
        basePrompt += "Current Month Expenses: Rs.$totalExpenses\n";
        basePrompt += "Net Balance: Rs.${totalIncome - totalExpenses}\n";

        // Get top 3 spending categories
        Map<String, double> categorySpending = {};
        for (var transaction in userFinanceData.listOfUserTransactions!) {
          if (transaction.transactionType ==
              TransactionType.expense.displayName) {
            final category = transaction.category ?? 'Uncategorized';
            final amount =
                double.parse(transaction.amount?.replaceAll('-', '') ?? '0');
            categorySpending[category] =
                (categorySpending[category] ?? 0) + amount;
          }
        }

        var sortedCategories = categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedCategories.isNotEmpty) {
          basePrompt += "\nTop Spending Categories:\n";
          final topCategories = sortedCategories.take(3);
          for (var entry in topCategories) {
            basePrompt +=
                "- ${entry.key}: Rs.${entry.value.toStringAsFixed(2)}\n";
          }
        }

        // Add a small samples of recent transactions
        basePrompt += "\nRecent Transactions:\n";
        final recentTransactions = userFinanceData.listOfUserTransactions!
            .where((t) => t.date != null)
            .toList()
          ..sort((a, b) =>
              (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));

        for (var i = 0; i < 5 && i < recentTransactions.length; i++) {
          final t = recentTransactions[i];
          final date = t.date != null
              ? "${t.date!.day}/${t.date!.month}/${t.date!.year}"
              : "Unknown date";
          basePrompt += "- $date: ${t.category} - Rs.${t.amount}\n";
        }
      }

      // Add groups information
      if (userFinanceData?.listOfGroups != null &&
          userFinanceData!.listOfGroups!.isNotEmpty) {
        basePrompt += "\n### GROUP FINANCES ###\n";
        for (var group in userFinanceData.listOfGroups!) {
          basePrompt += "Group: ${group.name}\n";
          basePrompt += "Total Amount: Rs.${group.totalAmount}\n";
          basePrompt +=
              "Your Balance: Rs.${group.membersBalance?[userData.uid] ?? '0'}\n\n";
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

  // Simple token estimation - roughly 4 characters per token
  static int estimateTokenCount(String text) {
    return (text.length / 4).ceil();
  }
}
