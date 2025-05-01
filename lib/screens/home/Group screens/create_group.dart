import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
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
  final TextEditingController _paymentModeController = TextEditingController();

  List<String> selectedUserUid = [];
  List<UserData> listOfSelectedUsers = [];

  BankAccount? selectedBank;

  bool isLoading = false;

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
      title: Text('Create Group'),
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
            _paymentModeField(userData, ref),
            if (selectedBank != null)
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text(selectedBank!.bankAccountName ?? "Bank Account"),
                subtitle: Text(
                    "Total Balance: ${selectedBank!.availableBalance ?? '0'} \nAvailable Balance: ${selectedBank!.availableBalance ?? '0'}"),
              ),
            // group members selection section
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
                                spacing: 10,
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

  Widget _paymentModeField(UserData userData, WidgetRef ref) {
    return _textfield(
      controller: _paymentModeController,
      prefixIconData: Icons.payments_rounded,
      hintText: "Select Payment Mode",
      lableText: "Payment Mode",
      readOnly: true,
      sufixIconData: Icons.arrow_drop_down_circle_outlined,
      onTap: () {
        // show modal bottom sheet to select payment mode
        _showPaymentModeSelectionBottomSheet(userData, ref);
      },
    );
  }

  void _showPaymentModeSelectionBottomSheet(UserData userData, WidgetRef ref) {
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Payment Mode",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color3,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.close,
                        color: color3,
                      ),
                    ),
                  ],
                ),
                sbh10,
                // Bank Accounts
                ...userFinanceData.listOfBankAccounts!.map((bankAccount) {
                  bool isSelected = selectedBank?.bid == bankAccount.bid;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _paymentModeController.text =
                            PaymentModes.bankAccount.displayName;
                        selectedBank = bankAccount;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border(
                                bottom: BorderSide(
                                  color: color3,
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: whiteColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(10),
                            topRight: const Radius.circular(10),
                            bottomLeft: isSelected
                                ? const Radius.circular(0)
                                : const Radius.circular(10),
                            bottomRight: isSelected
                                ? const Radius.circular(0)
                                : const Radius.circular(10),
                          ),
                          border: Border.all(
                            color: color2.withAlpha(150),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              children: [
                                Text(
                                  "Account: ",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? color3 : color1,
                                  ),
                                ),
                                Text(
                                  bankAccount.bankAccountName ?? "Bank Account",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? color3 : color1,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "Total Balance: ${bankAccount.totalBalance}",
                              style: TextStyle(
                                fontSize: 16,
                                color: color1,
                              ),
                            ),
                            Text(
                              "Available Balance: ${bankAccount.availableBalance}",
                              style: TextStyle(
                                fontSize: 16,
                                color: color1,
                              ),
                            ),
                            Text(
                              "Linked Group Balances:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color1,
                              ),
                            ),
                            if (bankAccount.groupsBalance == null ||
                                bankAccount.groupsBalance!.isEmpty)
                              Text(
                                "No groups linked",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              )
                            else
                              ...bankAccount.groupsBalance!.entries.map(
                                (entry) {
                                  final key = entry.key;
                                  final value = entry.value;
                                  
                                  // Find the group safely
                                  final Group? foundGroup = userFinanceData.listOfGroups?.where(
                                    (group) => group.gid == key
                                  ).firstOrNull;
                                  
                                  final String groupName = foundGroup?.name ?? "Unknown Group";
                                  
                                  return Row(
                                    spacing: 10,
                                    children: [
                                      Text(
                                        "◗ $groupName:",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: color1.withAlpha(200),
                                        ),
                                      ),
                                      Text("$value ₹",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: color2,
                                          )),
                                    ],
                                  );
                                },
                              ),
                              
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
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
                ? CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  void onTapButton(UserData userData, WidgetRef ref) async {
    if (!_validateGroupDetails()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final membersBalance = _calculateMembersBalance();
    final group = _createGroupObject(userData, membersBalance);

    final success = await _saveGroup(ref, group);

    if (success) {
      snackbarToast(
        context: context,
        text: "Group Created!",
        icon: Icons.done_all,
      );
      Navigate().goBack();
    } else {
      snackbarToast(
        context: context,
        text: "Error creating group",
        icon: Icons.error_outline,
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  bool _validateGroupDetails() {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
      snackbarToast(
        context: context,
        text: "Please Enter all the fields!",
        icon: Icons.error_outline,
      );
      return false;
    }

    if (listOfSelectedUsers.length <= 1) {
      snackbarToast(
        context: context,
        text: "Select minimum two members ⚠️",
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }

    if (_paymentModeController.text.isEmpty) {
      snackbarToast(
        context: context,
        text: "Please select a payment mode!",
        icon: Icons.warning_amber_rounded,
      );
      return false;
    }

    return true;
  }

  Map<String, String> _calculateMembersBalance() {
    final double totalAmount = double.parse(_amountController.text);
    final int memberCount = listOfSelectedUsers.length;
    final double distributedAmount = totalAmount / memberCount;

    return {
      for (var user in listOfSelectedUsers)
        user.uid!: distributedAmount.toStringAsFixed(2),
    };
  }

  Group _createGroupObject(
      UserData userData, Map<String, String> membersBalance) {
    return Group(
      creatorId: userData.uid,
      name: _nameController.text,
      description: _descriptionController.text,
      totalAmount: _amountController.text,
      memberIds: selectedUserUid,
      listOfMembers: listOfSelectedUsers,
      membersBalance: membersBalance,
      linkedBankAccountId: selectedBank?.bid,
    );
  }

  Future<bool> _saveGroup(WidgetRef ref, Group group) async {
    return await ref
        .read(userFinanceDataNotifierProvider.notifier)
        .createGroupProfile(groupProfile: group);
  }
}
