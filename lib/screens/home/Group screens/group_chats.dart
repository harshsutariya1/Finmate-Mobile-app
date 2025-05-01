import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/group_chat.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/database_references.dart';
import 'package:finmate/services/database_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/fullscreen_image_viewer.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class GroupChats extends ConsumerStatefulWidget {
  const GroupChats({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GroupChats> createState() => _GroupChatsState();
}

class _GroupChatsState extends ConsumerState<GroupChats> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Logger _logger = Logger();

  bool _isSending = false;
  // bool _isTyping = false;
  File? _selectedImage;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider);

    return Scaffold(
      backgroundColor: color4,
      body: Column(
        children: [
          Expanded(
            child: _buildChatStream(userData),
          ),
          _buildChatInputField(userData),
        ],
      ),
    );
  }

  /// Stream builder for chat messages
  Widget _buildChatStream(UserData userData) {
    return StreamBuilder<QuerySnapshot<Chat>>(
      stream: groupChatCollection(widget.group.gid ?? "").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
          return _buildEmptyChatState();
        }

        return _buildChatMessages(snapshot.data!.docs, userData);
      },
    );
  }

  /// Loading state when waiting for chat data
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: color2),
          const SizedBox(height: 16),
          Text(
            "Loading conversations...",
            style: TextStyle(color: color2),
          )
        ],
      ),
    );
  }

  /// Error state when chat stream has errors
  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              "Couldn't load messages",
              style: TextStyle(
                color: color3,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: color2,
                foregroundColor: Colors.white,
              ),
              child: Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state when no chat messages exist
  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color2.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_outlined,
              size: 60,
              color: color2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color3,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Be the first to start the conversation!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of chat messages with date separators
  Widget _buildChatMessages(
      List<QueryDocumentSnapshot<Chat>> chatDocs, UserData userData) {
    // Sort messages by date and time
    final List<QueryDocumentSnapshot<Chat>> sortedChats = List.from(chatDocs);
    sortedChats.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      int dateComp = aData.date!.compareTo(bData.date!);
      if (dateComp != 0) return dateComp;

      // Compare time strings in HH:MM format
      return ('${aData.time?.hour}:${aData.time?.minute}')
          .compareTo('${bData.time?.hour}:${bData.time?.minute}');
    });

    // Group messages by date
    final Map<String, List<QueryDocumentSnapshot<Chat>>> groupedChats = {};
    for (final doc in sortedChats) {
      final chat = doc.data();
      final dateKey = DateFormat('yyyy-MM-dd').format(chat.date!);

      if (!groupedChats.containsKey(dateKey)) {
        groupedChats[dateKey] = [];
      }
      groupedChats[dateKey]!.add(doc);
    }

    // Scroll to bottom on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final List<UserData> groupMembersData = widget.group.listOfMembers ?? [];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: groupedChats.length,
      itemBuilder: (context, groupIndex) {
        final dateKey = groupedChats.keys.elementAt(groupIndex);
        final messagesInGroup = groupedChats[dateKey]!;

        return Column(
          children: [
            _buildDateSeparator(dateKey),
            ...messagesInGroup.map((doc) {
              final Chat chatData = doc.data();
              final UserData? sender =
                  _getSender(chatData.senderId, groupMembersData);
              return _buildMessageBubble(userData, sender, chatData, doc.id);
            }),
          ],
        );
      },
    );
  }

  /// Gets the sender UserData for a given senderId
  UserData? _getSender(String? senderId, List<UserData> members) {
    if (senderId == null) return null;

    try {
      return members.firstWhere((user) => user.uid == senderId);
    } catch (e) {
      _logger.w("Sender not found for ID: $senderId");
      return null;
    }
  }

  /// Builds a date separator for message groups
  Widget _buildDateSeparator(String dateKey) {
    final DateTime date = DateTime.parse(dateKey);
    final DateTime now = DateTime.now();
    final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));

    String dateText;
    if (DateFormat('yyyy-MM-dd').format(now) == dateKey) {
      dateText = "Today";
    } else if (DateFormat('yyyy-MM-dd').format(yesterday) == dateKey) {
      dateText = "Yesterday";
    } else {
      dateText = DateFormat('MMMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
        ],
      ),
    );
  }

  /// Builds a message bubble for a chat message
  Widget _buildMessageBubble(
      UserData currentUser, UserData? sender, Chat chatData, String chatId) {
    final bool isCurrentUser = sender?.uid == currentUser.uid;
    final bool isImage = chatData.isImage == true;
    final time = chatData.time?.format(context) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => isCurrentUser ? _showDeleteDialog(chatId) : null,
        child: Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Sender avatar (only for received messages)
            if (!isCurrentUser) ...[
              userProfilePicInCircle(
                imageUrl: sender?.pfpURL ?? "",
                outerRadius: 18,
                innerRadius: 16,
              ),
              const SizedBox(width: 8),
            ],

            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name (only for received messages)
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(
                        sender?.name ?? "Unknown",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color2,
                        ),
                      ),
                    ),

                  // Message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? userChatColor : senderChatColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: isCurrentUser
                            ? Radius.circular(16)
                            : Radius.circular(4),
                        bottomRight: isCurrentUser
                            ? Radius.circular(4)
                            : Radius.circular(16),
                      ),
                    ),
                    child: isImage
                        ? _buildImageMessage(chatData)
                        : _buildTextMessage(chatData, isCurrentUser),
                  ),

                  // Message time
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a text message bubble
  Widget _buildTextMessage(Chat chatData, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        chatData.massage ?? "",
        style: TextStyle(
          color: Colors.black87,
          fontSize: 15,
        ),
      ),
    );
  }

  /// Builds an image message bubble
  Widget _buildImageMessage(Chat chatData) {
    final String imageUrl = chatData.massage ?? "";
    final String heroTag = "img_${chatData.cid}";
    
    return GestureDetector(
      onTap: () => _openFullScreenImage(imageUrl, heroTag),
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color3,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey.shade700),
                  const SizedBox(height: 8),
                  Text(
                    "Couldn't load image",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
            imageBuilder: (context, imageProvider) => Container(
              constraints: BoxConstraints(
                maxHeight: 250,
                minHeight: 100,
              ),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Open image in full screen
  void _openFullScreenImage(String imageUrl, String heroTag) {
    Navigate().push(
      FullScreenImageViewer(
        imageUrl: imageUrl,
        heroTag: heroTag,
      ),
    );
  }

  /// Shows a dialog to confirm message deletion
  void _showDeleteDialog(String chatId) {
    showYesNoDialog(
      context,
      title: "Delete Message?",
      contentWidget: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          "This message will be permanently deleted.",
          style: TextStyle(fontSize: 16),
        ),
      ),
      onTapYes: () => _deleteMessage(chatId),
      onTapNo: () => Navigate().goBack(),
    );
  }

  /// Deletes a message from the database
  Future<void> _deleteMessage(String chatId) async {
    try {
      await groupChatCollection(widget.group.gid ?? "").doc(chatId).delete();
      Navigate().goBack();

      snackbarToast(
        context: context,
        text: "Message deleted",
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      _logger.e("Error deleting message: $e");

      Navigate().goBack();
      snackbarToast(
        context: context,
        text: "Failed to delete message",
        icon: Icons.error_outline,
      );
    }
  }

  /// Builds the chat input field with attachment button
  Widget _buildChatInputField(UserData userData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Image attachment button
            IconButton(
              onPressed: () => _isSending ? null : _sendImage(userData),
              icon: _isSending
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color3,
                      ),
                    )
                  : Icon(Icons.photo, color: color3, size: 26),
            ),

            // Message input
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  // setState(() {
                  //   _isTyping = value.trim().isNotEmpty;
                  // });
                },
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Material(
              color: color3,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: (_messageController.text.isNotEmpty)
                    ? () => _sendTextMessage(userData)
                    : null,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sends a text message
  Future<void> _sendTextMessage(UserData userData) async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    _messageController.clear();

    try {
      final docRef = await groupChatCollection(widget.group.gid ?? "").add(
        Chat(
          senderId: userData.uid,
          massage: messageText,
        ),
      );

      await docRef.update({'cid': docRef.id});
      _logger.i("Message sent");
    } catch (e) {
      _logger.e("Error sending message: $e");
      snackbarToast(
        context: context,
        text: "Failed to send message",
        icon: Icons.error_outline,
      );
    }
  }

  /// Sends an image message
  Future<void> _sendImage(UserData userData) async {
    setState(() {
      _isSending = true;
    });

    try {
      _selectedImage = await getImageFromGallery();
      if (_selectedImage == null || _selectedImage!.path.isEmpty) {
        setState(() {
          _isSending = false;
        });
        return;
      }

      _logger.i("Image selected: ${_selectedImage?.path}");

      final picUrl = await uploadGroupChatPics(
        file: _selectedImage!,
        uid: userData.uid ?? "",
        gid: widget.group.gid ?? "",
      );

      final docRef = await groupChatCollection(widget.group.gid ?? "").add(
        Chat(
          senderId: userData.uid,
          massage: picUrl,
          isImage: true,
        ),
      );

      await docRef.update({'cid': docRef.id});
      _logger.i("Image message sent");
    } catch (e) {
      _logger.e("Error sending image: $e");
      snackbarToast(
        context: context,
        text: "Failed to send image",
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}
