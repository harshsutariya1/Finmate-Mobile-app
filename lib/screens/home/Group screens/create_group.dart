import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/Group%20screens/add_members.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/settings_widgets.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class AddGroupDetails extends ConsumerStatefulWidget {
  const AddGroupDetails({super.key});

  @override
  ConsumerState<AddGroupDetails> createState() => _AddGroupDetailsState();
}

class _AddGroupDetailsState extends ConsumerState<AddGroupDetails> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool isLoading = false;
  List<String> selectedUserUid = [];
  List<UserData> listOfSelectedUsers = [];

  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider);
    listOfSelectedUsers.contains(userData)
        ? null
        : listOfSelectedUsers.add(userData);
    selectedUserUid.contains(userData.uid)
        ? null
        : selectedUserUid.add(userData.uid!);

    return Scaffold(
      backgroundColor: color4,
      appBar: _appBar(),
      body: _body(userData, ref),
      resizeToAvoidBottomInset: false,
      floatingActionButton: createGroupButton(userData, ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: color4,
      centerTitle: true,
      title: Text('Add Group Details'),
    );
  }

  Widget _body(UserData userData, WidgetRef ref) {
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
            borderedContainer(
              [
                // title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Group Members",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color3,
                    ),
                  ),
                ),
                // selected members
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
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
                // view all button
                ElevatedButton(
                  onPressed: () async {
                    final List<UserData>? selectedMembers = await Navigate()
                        .push(AddMembers(selectedUsers: listOfSelectedUsers));
                    if (selectedMembers != null) {
                      Logger().i("Members Selected: ${selectedMembers.length}");
                      setState(() {
                        listOfSelectedUsers.addAll(selectedMembers);
                        selectedUserUid.addAll(
                            selectedMembers.map((user) => user.uid!).toList());
                      });
                    } else {
                      Logger()
                          .i("Members Selected: ${selectedMembers?.length}");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Add members",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              customMargin: EdgeInsets.all(0),
              customPadding: EdgeInsets.all(10),
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
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: color3,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
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
          color: color3.withAlpha(200),
          border: Border.all(color: color3, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Create Group",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            (isLoading)
                ? CircularProgressIndicator.adaptive()
                : SizedBox.shrink(),
          ],
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
      Map<String, String> calculateMembersBalance() {
        final double totalAmount = double.parse(groupAmount);
        final int memberCount = listOfSelectedUsers.length;
        final double distributedAmount = totalAmount / memberCount;
        return {
          for (var user in listOfSelectedUsers)
            user.uid!: distributedAmount.toStringAsFixed(2)
        };
      }

      final Map<String, String> membersBalance = calculateMembersBalance();

      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .createGroupProfile(
            groupProfile: Group(
              creatorId: userData.uid,
              name: groupName,
              description: groupDescription,
              totalAmount: groupAmount,
              memberIds: selectedUserUid,
              listOfMembers: listOfSelectedUsers,
              membersBalance: membersBalance,
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
