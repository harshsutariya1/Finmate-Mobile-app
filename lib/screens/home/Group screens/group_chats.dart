import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/chat.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/database_references.dart';
import 'package:finmate/services/database_services.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/auth_widgets.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class GroupChats extends ConsumerStatefulWidget {
  const GroupChats({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GroupChats> createState() => _GroupChatsState();
}

class _GroupChatsState extends ConsumerState<GroupChats> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isSending = false;
  File? selectedPic;

  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider);
    return Scaffold(
      backgroundColor: color4,
      body: _body(userData),
    );
  }

  Widget _body(UserData userData) {
    return StreamBuilder(
      stream: groupChatCollection(widget.group.gid ?? "").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error.toString()}"),
          );
        }
        if (snapshot.hasData) {
          final List<QueryDocumentSnapshot<Chat>>? chatsList =
              snapshot.data?.docs;
          Logger().i("Chats Data found: ${chatsList?.length}");

          chatsList?.sort((a, b) {
            int dateComparison = a.data().date!.compareTo(b.data().date!);
            if (dateComparison != 0) {
              return dateComparison;
            } else {
              return a
                  .data()
                  .time!
                  .format(context)
                  .compareTo(b.data().time!.format(context));
            }
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            }
          });

          return listOfChats(chatsList, userData);
        } else {
          return Center(
            child: Text("Data not found!"),
          );
        }
      },
    );
  }

  Widget listOfChats(
      List<QueryDocumentSnapshot<Chat>>? chatsList, UserData userData) {
    final List<UserData> groupMembersData = widget.group.listOfMembers ?? [];
    return Column(
      children: [
        Expanded(
          child: (chatsList!.isNotEmpty)
              ? ListView.builder(
                  controller: _scrollController,
                  itemCount: chatsList.length,
                  itemBuilder: (context, index) {
                    final Chat chatData = chatsList[index].data();
                    final sender = groupMembersData.where((user) {
                      return user.uid == chatData.senderId;
                    }).first;
                    return chatTile(
                      userData,
                      sender,
                      chatData,
                      isLastTile: (index == chatsList.length),
                    );
                  },
                )
              : Center(
                  child: Text("Start Chating 👋"),
                ),
        ),
        massageTextField(userData),
        sbh5,
      ],
    );
  }

  Widget chatTile(
    UserData userData,
    UserData? senderData,
    Chat chatData, {
    bool isLastTile = false,
  }) {
    final size = MediaQuery.sizeOf(context);
    return ListTile(
      key: (isLastTile) ? ValueKey("lastTile") : null,
      //sender profile pic
      leading: (senderData?.uid != userData.uid)
          ? userProfilePicInCircle(
              imageUrl: senderData?.pfpURL ?? "",
              outerRadius: 20,
              innerRadius: 18,
            )
          : null,
      titleAlignment: ListTileTitleAlignment.bottom,
      // message text
      title: Container(
        margin: EdgeInsets.only(
          left: (senderData?.uid == userData.uid) ? size.width * .3 : 0,
          right: (senderData?.uid != userData.uid) ? size.width * .3 : 0,
        ),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: (senderData?.uid == userData.uid)
                ? userChatColor
                : senderChatColor,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              topLeft: Radius.circular(20),
              bottomLeft: (senderData?.uid == userData.uid)
                  ? Radius.circular(20)
                  : Radius.zero,
              bottomRight: (senderData?.uid != userData.uid)
                  ? Radius.circular(20)
                  : Radius.zero,
            )),
        child: (chatData.isImage != true)
            ? Text(
                "${chatData.massage}",
                textAlign: (senderData?.uid == userData.uid)
                    ? TextAlign.right
                    : TextAlign.left,
                style: TextStyle(color: color2),
              )
            : CachedNetworkImage(
                imageUrl: chatData.massage.toString(),
                imageBuilder: (context, imageProvider) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image(image: imageProvider),
                ),
                errorWidget: (context, url, error) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        "⚠️ Error loading image",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                placeholder: (context, url) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                ),
              ),
      ),
      // date time
      subtitle: Text(
        "${chatData.date?.day}-${chatData.date?.month}-${chatData.date?.year}, ${chatData.time?.format(context)}",
        textAlign: (senderData?.uid == userData.uid)
            ? TextAlign.right
            : TextAlign.left,
        style: TextStyle(
          color: Colors.grey,
        ),
      ),

      onLongPress: () => (senderData?.uid == userData.uid)
          ? showYesNoDialog(context,
              title: "Delete Massage?",
              contentWidget: SizedBox(), onTapYes: () async {
              try {
                await groupChatCollection(widget.group.gid ?? "")
                    .doc(chatData.cid)
                    .delete()
                    .then((value) {
                  Navigate().goBack();
                });
              } catch (e) {
                Logger().e("Error deleting message ❗");
                snackbarToast(
                    context: context,
                    text: "Error deleting message ❗",
                    icon: Icons.error_outline_rounded);
              }
            }, onTapNo: () {
              Navigate().goBack();
            })
          : null,
    );
  }

  Widget massageTextField(UserData userData) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      color: Colors.transparent,
      child: Row(
        spacing: 5,
        children: [
          IconButton(
              onPressed: () {
                sendPic(userData, widget.group);
              },
              icon: (isSending)
                  ? CircularProgressIndicator.adaptive()
                  : Icon(
                      Icons.add_photo_alternate_sharp,
                      color: color2,
                      size: 30,
                    )),
          Expanded(
            child: TextField(
              controller: messageController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey.withAlpha(60),
                filled: true,
                hintText: "Write a Message...",
                suffixIcon: IconButton(
                  onPressed: () => onTapSend(userData, widget.group),
                  icon: Icon(Icons.send_rounded),
                  color: color3,
                  iconSize: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onTapSend(UserData userData, Group group) async {
    try {
      if (messageController.text.isNotEmpty) {
        await groupChatCollection(group.gid ?? "")
            .add(Chat(
          senderId: userData.uid,
          massage: messageController.text.trim(),
        ))
            .then((value) async {
          messageController.clear();
          await value.update({'cid': value.id});
          Logger().i("Message sent ✅");
        });
      }
    } catch (e) {
      snackbarToast(
          context: context,
          text: "Error Sending message",
          icon: Icons.error_outline_rounded);
      Logger().e("Error sending message: $e");
    }
  }

  void sendPic(UserData userData, Group group) async {
    setState(() {
      isSending = true;
    });
    try {
      selectedPic = await getImageFromGallery();
      if (selectedPic!.path.isNotEmpty) {
        Logger().i("Pic selected: ${selectedPic?.path}");
        final picUrl = await uploadGroupChatPics(
            file: selectedPic!, uid: userData.uid ?? "", gid: group.gid ?? "");
        await groupChatCollection(group.gid ?? "")
            .add(Chat(
          senderId: userData.uid,
          massage: picUrl,
          isImage: true,
        ))
            .then((value) async {
          messageController.clear();
          await value.update({'cid': value.id});
          Logger().i("Message sent ✅");
        });
      }
    } catch (e) {
      snackbarToast(
          context: context,
          text: "Error Sending message",
          icon: Icons.error_outline_rounded);
      Logger().e("Error sending message: $e");
    }
    setState(() {
      isSending = false;
    });
  }
}
