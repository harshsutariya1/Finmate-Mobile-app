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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _paymentModeController = TextEditingController();
  final Logger _logger = Logger();

  List<String> selectedUserUid = [];
  List<UserData> listOfSelectedUsers = [];

  BankAccount? selectedBank;

  bool isLoading = false;
  bool hasAttemptedSubmit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _paymentModeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserData userData = ref.watch(userDataNotifierProvider);
    
    // Add current user to selected users if not already added
    if (!listOfSelectedUsers.contains(userData)) {
      listOfSelectedUsers.add(userData);
    }
    
    if (userData.uid != null && !selectedUserUid.contains(userData.uid)) {
      selectedUserUid.add(userData.uid!);
    }

    return Scaffold(
      backgroundColor: color4,
      appBar: _buildAppBar(),
      body: _buildBody(userData, ref),
      floatingActionButton: _buildCreateButton(userData, ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: color4,
      centerTitle: true,
      title: const Text(
        'Create Group',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: color2),
        onPressed: () => Navigate().goBack(),
      ),
    );
  }

  Widget _buildBody(UserData userData, WidgetRef ref) {
    return Form(
      key: _formKey,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 80),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic information header
                _buildSectionHeader('Basic Information'),
                const SizedBox(height: 16),
                
                // Group name field
                _buildTextField(
                  controller: _nameController,
                  labelText: "Group Name",
                  hintText: "Enter group name",
                  prefixIconData: Icons.group_add_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Amount field
                _buildTextField(
                  controller: _amountController,
                  hintText: "00.00",
                  labelText: "Total Amount",
                  prefixIconData: Icons.currency_rupee_sharp,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than zero';
                    }
                    return null;
                  },
                ),
                // Amount distribution info
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: color3.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "This amount will be divided equally among all members",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description field
                _buildTextField(
                  controller: _descriptionController,
                  labelText: "Group Description",
                  hintText: "Describe the purpose of this group",
                  prefixIconData: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                // Payment section header
                _buildSectionHeader('Payment Details'),
                const SizedBox(height: 16),
                
                // Payment mode field
                _buildPaymentModeField(userData, ref),
                if (selectedBank != null) _buildSelectedBankInfo(),
                const SizedBox(height: 24),
                
                // Members section header
                _buildSectionHeader('Group Members'),
                const SizedBox(height: 16),
                
                // Group members selection
                _buildMembersSection(userData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color3,
          ),
        ),
        Container(
          width: 60,
          height: 3,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color3,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIconData,
    bool readOnly = false,
    Function()? onTap,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: 1,
      onTap: onTap,
      keyboardType: keyboardType,
      style: TextStyle(color: color1),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        alignLabelWithHint: maxLines > 1,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(color: color1),
        hintStyle: TextStyle(color: Colors.grey),
        prefixIcon: prefixIconData != null
            ? Icon(prefixIconData, color: color3)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color3, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      autovalidateMode: hasAttemptedSubmit 
          ? AutovalidateMode.onUserInteraction 
          : AutovalidateMode.disabled,
    );
  }

  Widget _buildPaymentModeField(UserData userData, WidgetRef ref) {
    return _buildTextField(
      controller: _paymentModeController,
      prefixIconData: Icons.payments_rounded,
      hintText: "Tap to select payment mode",
      labelText: "Payment Mode",
      readOnly: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a payment mode';
        }
        return null;
      },
      onTap: () => _showPaymentModeSelectionBottomSheet(userData, ref),
    );
  }

  Widget _buildSelectedBankInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color3.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color3.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance, color: color3, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedBank?.bankAccountName ?? "Bank Account",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Available Balance: ${selectedBank?.availableBalance ?? '0'} ₹",
                  style: TextStyle(
                    color: color2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(UserData userData) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected members counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Selected Members (${listOfSelectedUsers.length})",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color1,
                  fontSize: 15,
                ),
              ),
              // Hint text for you
              Text(
                "You + ${listOfSelectedUsers.length - 1} others",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          // Error message if needed
          if (hasAttemptedSubmit && listOfSelectedUsers.length < 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Please select at least one more member",
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 12,
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Selected members chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...listOfSelectedUsers.map((user) => _buildMemberChip(user, userData)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Add members button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _addGroupMembers(),
              icon: Icon(Icons.person_add_alt, color: Colors.white),
              label: Text(
                "Add Members",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color3,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberChip(UserData user, UserData currentUser) {
    final bool isCurrentUser = user.uid == currentUser.uid;
    
    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser ? color3.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isCurrentUser ? color3.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 30, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                userProfilePicInCircle(
                  imageUrl: user.pfpURL ?? "",
                  outerRadius: 16,
                  innerRadius: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  user.name ?? "User",
                  style: TextStyle(
                    color: isCurrentUser ? color3 : color1,
                    fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      "(You)",
                      style: TextStyle(
                        color: color3,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Delete button - only for non-current users
          if (!isCurrentUser)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedUserUid.remove(user.uid);
                    listOfSelectedUsers.remove(user);
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(UserData userData, WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _createGroup(userData, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: color3,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Creating Group...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                "Create Group",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showPaymentModeSelectionBottomSheet(UserData userData, WidgetRef ref) {
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    final List<BankAccount> bankAccounts = userFinanceData.listOfBankAccounts ?? [];

    if (bankAccounts.isEmpty) {
      snackbarToast(
        context: context,
        text: "No bank accounts available. Please add a bank account first.",
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Payment Mode",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color1,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigate().goBack(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: color2,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Subheader
              Text(
                "Choose a bank account to link with this group",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Divider
              Divider(height: 1, color: Colors.grey.shade300),
              
              // Bank accounts list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: bankAccounts.length,
                  itemBuilder: (context, index) {
                    return _buildBankAccountItem(bankAccounts[index], userFinanceData);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankAccountItem(BankAccount bankAccount, UserFinanceData userFinanceData) {
    final bool isSelected = selectedBank?.bid == bankAccount.bid;
    final hasLinkedGroups = bankAccount.groupsBalance != null && 
                            bankAccount.groupsBalance!.isNotEmpty;

    return InkWell(
      onTap: () {
        setState(() {
          _paymentModeController.text = PaymentModes.bankAccount.displayName;
          selectedBank = bankAccount;
        });
        Navigate().goBack();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? color3.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color3 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bank account header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color3.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: color3,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bankAccount.bankAccountName ?? "Bank Account",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: color1,
                          ),
                        ),
                        Text(
                          "Available: ${bankAccount.availableBalance} ₹",
                          style: TextStyle(
                            fontSize: 14,
                            color: color2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color3,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
              
              // Linked groups section if any
              if (hasLinkedGroups) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Text(
                  "Linked Groups:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bankAccount.groupsBalance!.entries.map((entry) {
                    // Find the group safely
                    final Group? foundGroup = userFinanceData.listOfGroups ?? []
                        .where((group) => group.gid == entry.key)
                        .firstOrNull;
                    
                    final String groupName = foundGroup?.name ?? "Unknown Group";
                    final String balance = entry.value;
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "$groupName: $balance ₹",
                        style: TextStyle(
                          fontSize: 12,
                          color: color1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addGroupMembers() async {
    try {
      final result = await Navigate().push(
        AddMembers(selectedUsers: listOfSelectedUsers),
      );
      
      if (result != null && result is List<UserData> && result.isNotEmpty) {
        setState(() {
          for (final user in result) {
            if (!listOfSelectedUsers.any((u) => u.uid == user.uid)) {
              listOfSelectedUsers.add(user);
              if (user.uid != null) {
                selectedUserUid.add(user.uid!);
              }
            }
          }
        });
        
        // Show a success toast
        snackbarToast(
          context: context,
          text: "${result.length} member${result.length > 1 ? 's' : ''} added",
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      _logger.e("Error adding members: $e");
      
      // Show an error toast
      snackbarToast(
        context: context,
        text: "Failed to add members",
        icon: Icons.error_outline,
      );
    }
  }

  void _createGroup(UserData userData, WidgetRef ref) async {
    // Mark that we've attempted to submit the form
    setState(() {
      hasAttemptedSubmit = true;
    });
    
    // Validate form and members
    if (!_validateForm()) {
      return;
    }

    // Show loading indicator
    setState(() {
      isLoading = true;
    });

    try {
      // Calculate member balances
      final membersBalance = _calculateMembersBalance();
      
      // Create group object
      final group = Group(
        creatorId: userData.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        totalAmount: _amountController.text.trim(),
        memberIds: selectedUserUid,
        listOfMembers: listOfSelectedUsers,
        membersBalance: membersBalance,
        linkedBankAccountId: selectedBank?.bid,
        date: DateTime.now(),
      );

      // Save the group
      final success = await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .createGroupProfile(groupProfile: group);

      if (success) {
        // Show success message and navigate back
        snackbarToast(
          context: context,
          text: "Group Created Successfully!",
          icon: Icons.check_circle_outline,
        );
        Navigate().goBack();
      } else {
        // Show error message
        snackbarToast(
          context: context,
          text: "Failed to create group",
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      _logger.e("Error creating group: $e");
      snackbarToast(
        context: context,
        text: "An error occurred while creating the group",
        icon: Icons.error_outline,
      );
    } finally {
      // Hide loading indicator if still on this screen
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool _validateForm() {
    // Validate the form fields
    final isFormValid = _formKey.currentState?.validate() ?? false;
    
    // Validate that we have at least 2 members
    final hasSufficientMembers = listOfSelectedUsers.length >= 2;
    
    if (!hasSufficientMembers) {
      snackbarToast(
        context: context,
        text: "Please add at least one more member",
        icon: Icons.warning_amber_rounded,
      );
    }
    
    return isFormValid && hasSufficientMembers;
  }

  Map<String, String> _calculateMembersBalance() {
    final double totalAmount = double.parse(_amountController.text.trim());
    final int memberCount = listOfSelectedUsers.length;
    final double distributedAmount = totalAmount / memberCount;

    return {
      for (var user in listOfSelectedUsers)
        if (user.uid != null) user.uid!: distributedAmount.toStringAsFixed(2),
    };
  }
}
