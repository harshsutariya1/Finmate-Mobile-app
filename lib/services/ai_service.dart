import 'dart:convert';
import 'package:finmate/models/budget.dart';
import 'package:finmate/models/chat_message.dart';
import 'package:finmate/models/investment.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

class AIService {
  static final Logger _logger = Logger();

  // Get API key from environment variables
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";

  // Available OpenAI models
  static const Map<String, String> models = {
    'gpt-4.1-nano': 'GPT-4.1 Nano',
    'gpt-3.5-turbo': 'GPT-3.5 Turbo',
    'gpt-4-turbo': 'GPT-4 Turbo',
    "gpt-4.1-mini": "GPT-4.1 Mini",
    'gpt-4': 'GPT-4',
  };

  // Get the system prompt that defines the AI's behavior with enhanced user financial data
  static String getSystemPrompt({
    UserData? userData,
    UserFinanceData? userFinanceData,
    List<Budget>? budgets,
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

  // Save API key to shared preferences
  static Future<void> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('openai_api_key', apiKey);
      _logger.i('API key saved successfully');
    } catch (e) {
      _logger.e('Error saving API key: $e');
    }
  }

  // Modify getApiKey to use the environment variable if SharedPreferences fails or is empty
  static Future<String> getApiKey() async {
    String? savedKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedKey = prefs.getString('openai_api_key');
    } catch (e) {
      _logger.e('Error retrieving API key from SharedPreferences: $e');
    }
    // Use saved key, or fallback to environment key, or empty string
    return savedKey ?? _apiKey;
  }

  // Send a message to the OpenAI API and get a response
  static Future<ChatMessage?> sendMessage({
    required List<ChatMessage> messages,
    required String selectedModel,
    UserData? userData,
    UserFinanceData? userFinanceData,
    List<Budget>? budgets,
    List<Investment>? investments,
  }) async {
    try {
      // Get API key (will check SharedPreferences first, then .env)
      final apiKey = await getApiKey();

      if (apiKey.isEmpty) {
         _logger.e('OpenAI API Key is missing. Please configure it in settings or .env file.');
         return ChatMessage(
           content: "API Key is missing. Please configure it in the settings.",
           isUser: false,
           timestamp: DateTime.now(),
         );
      }

      // Add system prompt to the beginning of the conversation
      List<Map<String, String>> formattedMessages = [
        {
          "role": "system",
          "content": getSystemPrompt(
            userData: userData,
            userFinanceData: userFinanceData,
            budgets: budgets,
            investments: investments,
          )
        },
      ];

      // Add user messages
      formattedMessages.addAll(
        messages.map((msg) => {
              "role": msg.isUser ? "user" : "assistant",
              "content": msg.content,
            }),
      );

      _logger.i('Sending request to OpenAI API with model: $selectedModel');

      // Make API request with timeout
      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': selectedModel,
          'messages': formattedMessages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Optional: Process content to fix any encoding issues
        final processedContent = content.toString();

        return ChatMessage(
          content: processedContent,
          isUser: false,
          timestamp: DateTime.now(),
        );
      } else {
        _logger.e('API Error: ${response.statusCode} - ${response.body}');

        // Parse error message if available
        String errorMessage = 'Failed to get response: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData.containsKey('error')) {
            errorMessage = errorData['error']['message'] ?? errorMessage;
          }
        } catch (_) {}

        return ChatMessage(
          content:
              "I encountered an error: $errorMessage. Please try again later.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _logger.e('Error sending message to OpenAI: $e');
      return ChatMessage(
        content:
            "Sorry, I'm having trouble connecting to my services. Please check your internet connection or try again later. Error: ${e.toString()}",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }
}
