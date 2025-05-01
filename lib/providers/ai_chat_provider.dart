import 'package:finmate/models/budget.dart';
import 'package:finmate/models/chat_message.dart';
import 'package:finmate/models/goal.dart';
import 'package:finmate/models/investment.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/services/ai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

// Provider for storing conversation history
final chatHistoryProvider =
    StateNotifierProvider<ChatHistoryNotifier, List<ChatMessage>>((ref) {
  return ChatHistoryNotifier();
});

class ChatHistoryNotifier extends StateNotifier<List<ChatMessage>> {
  ChatHistoryNotifier() : super([]);
  final logger = Logger();

  // Add initial greeting message when conversation starts
  void initializeChat() {
    if (state.isEmpty) {
      state = [
        ChatMessage(
          content:
              "Hello! I'm FinMate AI, your personal finance assistant. I can help you with budgeting, investments, financial planning, and more. How can I help you today?",
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];
    }
  }

  // Add a new user message to the conversation
  void addUserMessage(String content) {
    if (content.trim().isEmpty) return;

    state = [
      ...state,
      ChatMessage(
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ];
  }

  // Add an AI response to the conversation
  void addAIMessage(ChatMessage message) {
    state = [...state, message];
  }

  // Clear the chat history
  void clearChat() {
    state = [];
    initializeChat();
  }

  // Enhanced method to send message with all user finance data
  Future<void> sendMessageAndGetResponse(
    String userMessage,
    String selectedModel, {
    UserData? userData,
    UserFinanceData? userFinanceData,
    List<Budget>? budgets,
    List<Goal>? goals,
    List<Investment>? investments,
  }) async {
    if (userMessage.trim().isEmpty) return;

    // Add user message to chat
    addUserMessage(userMessage);

    try {
      // Send message to OpenAI API with comprehensive user data
      final aiResponse = await AIService().sendMessage(
        userMessage: userMessage,
        messages: state,
        selectedModel: selectedModel,
        userData: userData,
        userFinanceData: userFinanceData,
        budgets: budgets,
        goals: goals,
        investments: investments,
      );

      final ChatMessage aiMessage = ChatMessage(
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (aiResponse.isNotEmpty) {
        // Add AI response to chat
        addAIMessage(aiMessage);
      } else {
        // Add fallback message if response is null
        addAIMessage(
          ChatMessage(
            content:
                "I couldn't generate a response at the moment. Please try again later.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      logger.e("Error getting AI response: $e");
      // Add error message
      addAIMessage(
        ChatMessage(
          content:
              "Sorry, I encountered an unexpected error. Please try again or check your connection.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }
}

// Provider for storing currently selected model
final selectedModelProvider = StateProvider<String>((ref) {
  // Change default to GPT-4.1 Nano
  return 'gpt-4.1-nano';
});

// Provider for tracking loading state
final isLoadingResponseProvider = StateProvider<bool>((ref) {
  return false;
});
