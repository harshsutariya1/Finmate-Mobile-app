import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/ai_model.dart';
import 'package:finmate/providers/ai_chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AIChatSettingsScreen extends ConsumerStatefulWidget {
  const AIChatSettingsScreen({super.key});

  @override
  ConsumerState<AIChatSettingsScreen> createState() => _AIChatSettingsScreenState();
}

class _AIChatSettingsScreenState extends ConsumerState<AIChatSettingsScreen> {
  
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
        title: const Text("AI Assistant Settings"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("AI Model"),
            _buildAIModelInfo(),
            
            const SizedBox(height: 20),
            
            Text(
              "This app uses ${AIModel.getModelName()} to provide financial assistance and answer your questions about personal finance.",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader("Chat History"),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.withAlpha(50),
                child: const Icon(Icons.delete_forever, color: Colors.red),
              ),
              title: const Text(
                "Clear Chat History",
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text("Removes all messages from the chat."),
              onTap: _showClearChatDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color3,
        ),
      ),
    );
  }

  Widget _buildAIModelInfo() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color3.withAlpha(50),
          child: const Icon(Icons.auto_awesome, color: color3),
        ),
        title: const Text("Current AI Model"),
        subtitle: Text(
          AIModel.getModelName(),
          style: TextStyle(color: color3),
        ),
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
            child: const Text("Clear",style: TextStyle(color: whiteColor),),
          ),
        ],
      ),
    );
  }
}
