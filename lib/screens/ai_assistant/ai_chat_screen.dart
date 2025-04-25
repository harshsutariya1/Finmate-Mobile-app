import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/budget.dart';
import 'package:finmate/models/chat_message.dart';
import 'package:finmate/models/investment.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/ai_chat_provider.dart';
import 'package:finmate/providers/budget_provider.dart';
import 'package:finmate/providers/investment_provider.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/ai_service.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _showApiKeyDialog = false;
  bool _dataPrivacyAccepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkApiKey();
      _checkDataPrivacyConsent();
      ref.read(chatHistoryProvider.notifier).initializeChat();
      _scrollToBottom();
    });
  }
  

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Check if API key is configured
  Future<void> _checkApiKey() async {
    final apiKey = await AIService.getApiKey();
    if (apiKey.isEmpty) {
      setState(() {
        _showApiKeyDialog = true;
      });
    }
  }

  // Check if user has consented to data privacy
  Future<void> _checkDataPrivacyConsent() async {
    // This could be stored in shared preferences in a real implementation
    if (!_dataPrivacyAccepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDataPrivacyDialog();
      });
    }
  }

  // Show data privacy consent dialog
  void _showDataPrivacyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Financial Data Access"),
        content: const Text(
          "FinMate AI can provide personalized financial advice by accessing your account details, transactions, and other financial data stored in the app. Your data will only be used to provide personalized advice and will not be stored or shared outside this app.\n\nDo you want to allow FinMate AI to access your financial data?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _dataPrivacyAccepted = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text("No, Keep Private"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _dataPrivacyAccepted = true;
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: color3),
            child: const Text("Yes, Allow Access", style: TextStyle(color: whiteColor),),
          ),
        ],
      ),
    );
  }

  // Scroll to bottom of chat
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Send message with comprehensive financial data
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isTyping = true);
    _messageController.clear();
    _focusNode.requestFocus();

    final selectedModel = ref.read(selectedModelProvider);
    ref.read(isLoadingResponseProvider.notifier).state = true;

    // Get comprehensive user data from all providers
    final userData = ref.read(userDataNotifierProvider);
    final userFinanceData = ref.read(userFinanceDataNotifierProvider);
    final budgets = ref.read(budgetNotifierProvider);
    final investments = ref.read(investmentNotifierProvider);

    // Wait a moment before showing typing indicator
    await Future.delayed(const Duration(milliseconds: 300));
    
    await ref.read(chatHistoryProvider.notifier).sendMessageAndGetResponse(
      message,
      selectedModel,
      // Only pass user data if consent was given
      userData: _dataPrivacyAccepted ? userData : null,
      userFinanceData: _dataPrivacyAccepted ? userFinanceData : null,
      budgets: _dataPrivacyAccepted ? budgets : null,
      investments: _dataPrivacyAccepted ? investments : null,
    );

    ref.read(isLoadingResponseProvider.notifier).state = false;
    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatHistory = ref.watch(chatHistoryProvider);
    final isLoadingResponse = ref.watch(isLoadingResponseProvider);
    final selectedModel = ref.watch(selectedModelProvider);

    // Trigger scroll to bottom whenever chatHistory changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Show API key dialog if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showApiKeyDialog) {
        _showApiKeyConfigDialog();
        setState(() {
          _showApiKeyDialog = false;
        });
      }
    });

    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        title: Text("FinMate AI Assistant"),
        backgroundColor: color4,
        actions: [
          // Data privacy toggle
          IconButton(
            icon: Icon(
              _dataPrivacyAccepted ? Icons.visibility : Icons.visibility_off,
              color: _dataPrivacyAccepted ? color3 : Colors.grey,
            ),
            tooltip: _dataPrivacyAccepted ? "Financial data access enabled" : "Financial data access disabled",
            onPressed: () => _showDataPrivacyDialog(),
          ),
          // Model selection dropdown
          DropdownButton<String>(
            value: selectedModel,
            underline: Container(),
            icon: const Icon(Icons.keyboard_arrow_down, color: color3),
            items: AIService.models.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(selectedModelProvider.notifier).state = value;
              }
            },
          ),
          // API key configuration
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showApiKeyConfigDialog,
          ),
          // Clear chat history
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showClearChatDialog,
          ),
          sbw10,
        ],
      ),
      body: Column(
        children: [
          // Enhanced financial data access indicator
          if (_dataPrivacyAccepted)
            _buildDataPrivacyBanner(),
          
          // Chat history
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: chatHistory.length + (isLoadingResponse ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatHistory.length) {
                  // Show typing indicator
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(chatHistory[index]);
              },
            ),
          ),
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: InkWell(
        onLongPress: () => _copyMessageToClipboard(message.content),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: message.isUser ? color3 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message content with Markdown support for AI messages
              message.isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 16),
                        code: const TextStyle(
                          backgroundColor: Color(0xFFEEEEEE),
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
              // Timestamp
              const SizedBox(height: 4),
          Text(
            DateFormat('h:mm a').format(message.timestamp),
            style: TextStyle(
              color: message.isUser ? Colors.white70 : Colors.grey,
              fontSize: 12,
            ),
          ),
          
        ],
            ),
        ),
      ),
    );
  }

  
  // New method to copy message content to clipboard
  void _copyMessageToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    snackbarToast(context: context, text: "Message copied to clipboard !", icon: Icons.copy_all_outlined);
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color3),
              ),
            ),
            const SizedBox(width: 8),
            const Text("Thinking...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Message input field
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: "Ask FinMate AI...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          FloatingActionButton(
            onPressed: _isTyping ? null : _sendMessage,
            backgroundColor: color3,
            elevation: 0,
            child: Icon(
              _isTyping ? Icons.hourglass_empty : Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog to configure API key
  void _showApiKeyConfigDialog() {
    final TextEditingController apiKeyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Configure OpenAI API Key"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your OpenAI API key to enable the AI Assistant feature. You can get an API key from openai.com.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: "API Key",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (apiKeyController.text.trim().isNotEmpty) {
                await AIService.saveApiKey(apiKeyController.text.trim());
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: color3),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Show dialog to confirm clearing chat history
  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Chat History"),
        content: const Text("Are you sure you want to clear the chat history?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chatHistoryProvider.notifier).clearChat();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  // Enhanced data privacy banner showing all data types being shared
  Widget _buildDataPrivacyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      color: color3.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color3),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "AI has access to your financial data (transactions, accounts, detailed budgets, and investments) to provide personalized advice",
              style: TextStyle(fontSize: 12, color: color3),
            ),
          ),
        ],
      ),
    );
  }
}
