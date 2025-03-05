import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:searchfield/searchfield.dart';

class AddGroupDetails extends StatefulWidget {
  const AddGroupDetails({super.key});

  @override
  State<AddGroupDetails> createState() => _AddGroupDetailsState();
}

class _AddGroupDetailsState extends State<AddGroupDetails> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool isLoading = false;
  List<String> selectedUserUid = [];
  List<UserData> listOfSelectedUsers = [];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final UserData userData = ref.watch(userDataNotifierProvider);
        final listOfUsers = ref.watch(allAppUsers);
        listOfSelectedUsers.contains(userData)
            ? null
            : listOfSelectedUsers.add(userData);
        selectedUserUid.contains(userData.uid)
            ? null
            : selectedUserUid.add(userData.uid!);

        return Scaffold(
          backgroundColor: color4,
          appBar: _appBar(),
          body: listOfUsers.when(
            data: (users) => _body(userData, ref, users),
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
          resizeToAvoidBottomInset: true,
        );
      },
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: color4,
      centerTitle: true,
      title: Text('Add Group Details'),
    );
  }

  Widget _body(UserData userData, WidgetRef ref, List<UserData> listOfUsers) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 20,
        bottom: 0,
        right: 30,
        left: 30,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          spacing: 20,
          children: [
            _textfield(
              controller: _nameController,
              lableText: "Group Name",
              prefixIconData: Icons.group_add_outlined,
            ),
            _textfield(
              controller: _amountController,
              hintText: "00.00",
              lableText: "Amount",
              prefixIconData: Icons.currency_rupee_sharp,
            ),
            _textfield(
              controller: _descriptionController,
              lableText: "Group Description",
              hintText: "Description",
              prefixIconData: Icons.description_outlined,
            ),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.start,
                children: [
                  ...listOfSelectedUsers.map((user) => InkWell(
                        onTap: () {
                          setState(() {
                            if (userData.uid != user.uid) {
                              selectedUserUid.remove(user.uid);
                              listOfSelectedUsers.remove(user);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 5,
                            children: [
                              userProfilePicInCircle(
                                imageUrl: user.pfpURL.toString(),
                                outerRadius: 18,
                                innerRadius: 17,
                              ),
                              Text(
                                "${user.name}",
                                style: TextStyle(color: color1),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
            SearchField(
              hint: "Search Members",
              suggestions: listOfUsers
                  .map((e) => SearchFieldListItem("${e.uid}",
                      child: Text(e.email ?? "")))
                  .toList(),
              onSuggestionTap: (value) {
                final String uid = value.searchKey;
                final UserData selectedUser =
                    listOfUsers.firstWhere((user) => user.uid == uid);
                if (!selectedUserUid.contains(uid)) {
                  setState(() {
                    selectedUserUid.add(uid);
                    listOfSelectedUsers.add(selectedUser);
                  });
                } else {
                  setState(() {});
                }
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: createGroupButton(userData, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textfield({
    required TextEditingController controller,
    String? hintText,
    String? lableText,
    IconData? prefixIconData,
    IconData? sufixIconData,
    bool readOnly = false,
    void Function()? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: (onTap != null) ? onTap : null,
      keyboardType:
          (lableText == "Amount") ? TextInputType.numberWithOptions() : null,
      minLines: (hintText == "Description") ? 1 : 1,
      maxLines: (hintText == "Description") ? 3 : 1,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        labelText: (lableText != null) ? lableText : null,
        hintText: (hintText != null) ? hintText : null,
        hintStyle: TextStyle(
          textBaseline: TextBaseline.alphabetic,
        ),
        labelStyle: TextStyle(
          color: color1,
        ),
        prefixIcon: (prefixIconData != null)
            ? Icon(
                prefixIconData,
                color: color3,
              )
            : null,
        suffixIcon: (sufixIconData != null)
            ? Icon(
                sufixIconData,
                color: color3,
                size: 30,
              )
            : null,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: color1),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: color3,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget createGroupButton(UserData userData, WidgetRef ref) {
    return InkWell(
      onTap: () => onTapButton(userData, ref),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15),
        margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        decoration: BoxDecoration(
          color: color2.withAlpha(200),
          border: Border.all(color: color1, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "Create Group",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  void onTapButton(UserData userData, WidgetRef ref) async {
    setState(() {
      isLoading = true;
    });
    final groupName = _nameController.text;
    final groupDescription = _descriptionController.text;
    final groupAmount = _amountController.text;
    if (groupName.isNotEmpty && groupAmount.isNotEmpty) {
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .createGroupProfile(
            groupProfile: Group(
              creatorId: userData.uid,
              name: groupName,
              description: groupDescription,
              totalAmount: groupAmount,
              memberIds: selectedUserUid,
              memberPfpics:
                  listOfSelectedUsers.map((user) => user.pfpURL!).toList(),
            ),
            ref: ref,
          )
          .then((value) {
        if (value) {
          snackbarToast(
              context: context, text: "Group Created!", icon: Icons.done_all);
          Navigate().goBack();
        } else {
          snackbarToast(
              context: context,
              text: "Error creating group",
              icon: Icons.error_outline);
        }
      });
    } else {
      snackbarToast(
          context: context,
          text: "Please Enter all the fields!",
          icon: Icons.error_outline);
    }
    setState(() {
      isLoading = false;
    });
  }
}
