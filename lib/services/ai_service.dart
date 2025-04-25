import 'dart:convert';
import 'package:finmate/models/chat_message.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static final Logger _logger = Logger();
  // API key is now properly set
  static const String _apiKey = "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";
  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";

  // Available OpenAI models
  static const Map<String, String> models = {
    'gpt-3.5-turbo': 'GPT-3.5 Turbo',
    'gpt-4-turbo': 'GPT-4 Turbo',
    'gpt-4': 'GPT-4',
  };

  // Get the system prompt that defines the AI's behavior
  static String getSystemPrompt() {
    return """You are FinMate AI, a helpful financial assistant integrated into the FinMate app.
You provide advice on personal finance, budgeting, investments, and financial planning.
Keep responses concise, practical, and focused on the user's financial goals and needs.
When giving investment advice, always include disclaimers about market risks.
For budgeting advice, focus on realistic and sustainable approaches.
Avoid giving specific legal or tax advice, and recommend consulting professionals when necessary.
You have access to the user's financial data in the FinMate app, but always respect their privacy.
Use a friendly but professional tone, and provide specific action steps when possible.""";
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

  // Get API key from shared preferences, falling back to default if not found
  static Future<String> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('openai_api_key');
      return savedKey ?? _apiKey; // Fall back to default key if not found
    } catch (e) {
      _logger.e('Error retrieving API key: $e');
      return _apiKey; // Return default key on error
    }
  }

  // Send a message to the OpenAI API and get a response
  static Future<ChatMessage?> sendMessage({
    required List<ChatMessage> messages,
    required String selectedModel,
  }) async {
    try {
      // Get saved API key or use default
      final apiKey = await getApiKey();
      
      // Add system prompt to the beginning of the conversation
      List<Map<String, String>> formattedMessages = [
        {"role": "system", "content": getSystemPrompt()},
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
      final response = await http.post(
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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        return ChatMessage(
          content: content,
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
          content: "I encountered an error: $errorMessage. Please try again later.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _logger.e('Error sending message to OpenAI: $e');
      return ChatMessage(
        content: "Sorry, I'm having trouble connecting to my services. Please check your internet connection or try again later. Error: ${e.toString()}",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }
}
