import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/ai_model.dart';
import 'package:finmate/models/ai_chat.dart';
import 'package:finmate/providers/ai_chat_provider.dart';
import 'package:finmate/providers/budget_provider.dart';
import 'package:finmate/providers/goals_provider.dart';
import 'package:finmate/providers/investment_provider.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/ai_assistant/ai_chat_settings_screen.dart';
import 'package:finmate/services/navigation_services.dart';
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
  final bool _dataPrivacyAccepted = true; 
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    final selectedModel = AIModel.getModelId();
    ref.read(isLoadingResponseProvider.notifier).state = true;

    // Get comprehensive user data from all providers
    final userData = ref.read(userDataNotifierProvider);
    final userFinanceData = ref.read(userFinanceDataNotifierProvider);
    final budgets = ref.read(budgetNotifierProvider);
    final goals = ref.read(goalsNotifierProvider);
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
          goals: _dataPrivacyAccepted ? goals : null,
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

    // Trigger scroll to bottom whenever chatHistory changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: color4,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [color3, Colors.blueAccent], // Example gradient colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            "FinMate AI Assistant",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigate().push(const AIChatSettingsScreen());
            },
          ),
          sbw10,
        ],
      ),
      body: Column(
        children: [
          // Enhanced financial data access indicator
          if (_dataPrivacyAccepted) _buildDataPrivacyBanner(),
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
                color: Colors.black.withAlpha(13), // was .withOpacity(0.05)
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
    snackbarToast(
        context: context,
        text: "Message copied to clipboard !",
        icon: Icons.copy_all_outlined);
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
            color: Colors.black.withAlpha(26), // was .withOpacity(0.1)
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

  // Enhanced data privacy banner showing all data types being shared
  Widget _buildDataPrivacyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      color: color3.withAlpha(26), // was .withOpacity(0.1)
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
