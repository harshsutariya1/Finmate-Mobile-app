// import 'package:finmate/constants/colors.dart';
// import 'package:finmate/constants/const_widgets.dart';
// import 'package:finmate/models/accounts.dart';
// import 'package:finmate/models/group.dart';
// import 'package:finmate/models/transaction.dart';
// import 'package:finmate/models/user.dart';
// import 'package:finmate/models/user_finance_data.dart';
// import 'package:finmate/providers/user_financedata_provider.dart';
// import 'package:finmate/providers/userdata_provider.dart';
// import 'package:finmate/screens/home/Transaction%20screens/select_category.dart';
// import 'package:finmate/services/navigation_services.dart';
// import 'package:finmate/widgets/snackbar.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:logger/logger.dart';

// class EditTransactionScreen extends ConsumerStatefulWidget {
//   const EditTransactionScreen({super.key, required this.transaction});
//   final Transaction transaction;

//   @override
//   ConsumerState<EditTransactionScreen> createState() =>
//       _EditTransactionScreenState();
// }

// class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
//   // Controllers
//   final TextEditingController _amountController = TextEditingController();
//   final TextEditingController _payeeController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _categoryController = TextEditingController();
//   final TextEditingController _groupController = TextEditingController();
//   final TextEditingController _paymentModeController = TextEditingController();

//   // Selected entities
//   Group? selectedGroup;
//   BankAccount? selectedBank;

//   // State variables
//   late DateTime _selectedDate;
//   late TimeOfDay _selectedTime;
//   late bool isIncomeSelected;
//   bool isButtonDisabled = false;
//   bool isButtonLoading = false;

//   // Original transaction values for comparison
//   late String originalAmount;
//   late String originalPaymentMode;
//   late String? originalBankId;
//   late String? originalGroupId;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize controllers with transaction data
//     // UserFinanceData userFinanceData =
//     //     ref.watch(userFinanceDataNotifierProvider);
//     _initializeControllers();

//     // Store original values for comparison when updating
//     originalAmount = widget.transaction.amount ?? '0';
//     originalPaymentMode = widget.transaction.methodOfPayment ?? 'Cash';
//     originalBankId = widget.transaction.bankAccountId;
//     originalGroupId = widget.transaction.gid;
//   }

//   void _initializeControllers() {
//     // Get the transaction data
//     final transaction = widget.transaction;

//     // Set isIncomeSelected based on transaction type
//     isIncomeSelected =
//         transaction.transactionType == TransactionType.income.displayName;

//     // Initialize date and time
//     _selectedDate = transaction.date ?? DateTime.now();
//     _selectedTime = transaction.time ?? TimeOfDay.now();

//     // Initialize text controllers
//     _amountController.text = (transaction.amount ?? '0').replaceAll('-', '');
//     _payeeController.text = transaction.payee ?? '';
//     _descriptionController.text = transaction.description ?? '';
//     _categoryController.text = transaction.category ?? '';
//     _paymentModeController.text = transaction.methodOfPayment ?? '';

//     // Initialize group if applicable
//     if (transaction.isGroupTransaction && widget.transaction.gid != null) {
//       _groupController.text = transaction.groupName ?? '';
//       // selectedGroup = userFinanceData.listOfGroups?.firstWhere(
//       //   (group) => group.gid == transaction.gid,
//       //   orElse: () => Group(),
//       // );
//     }

//     // Load selected bank if applicable
//     if (transaction.methodOfPayment == PaymentModes.bankAccount.displayName &&
//         widget.transaction.bankAccountId != null) {
//       // We'll set selectedBank in the build method when we have access to userFinanceData
//       // selectedBank = userFinanceData.listOfBankAccounts?.firstWhere(
//       //   (bank) => bank.bid == transaction.bankAccountId,
//       //   orElse: () => BankAccount(),
//       // );
//     }
//   }

//   @override
//   void dispose() {
//     // Clean up controllers
//     _amountController.dispose();
//     _payeeController.dispose();
//     _descriptionController.dispose();
//     _categoryController.dispose();
//     _groupController.dispose();
//     _paymentModeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     UserData userData = ref.watch(userDataNotifierProvider);
//     UserFinanceData userFinanceData =
//         ref.watch(userFinanceDataNotifierProvider);

//     // Initialize selectedBank if not already set
//     if (selectedBank == null && widget.transaction.bankAccountId != null) {
//       selectedBank = userFinanceData.listOfBankAccounts?.firstWhere(
//         (bank) => bank.bid == widget.transaction.bankAccountId,
//         orElse: () => BankAccount(),
//       );
//     }

//     // Initialize selectedGroup if not already set
//     if (selectedGroup == null && widget.transaction.gid != null) {
//       selectedGroup = userFinanceData.listOfGroups?.firstWhere(
//         (group) => group.gid == widget.transaction.gid,
//         orElse: () => Group(),
//       );
//     }

//     return Scaffold(
//       backgroundColor: color4,
//       appBar: AppBar(
//         backgroundColor: color4,
//         title: Text(
//           'Edit Transaction',
//           style: TextStyle(color: color1),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios, color: color1),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       floatingActionButton: _updateButton(userData, userFinanceData),
//       body: _bodyForm(
//         userData: userData,
//         userFinanceData: userFinanceData,
//       ),
//     );
//   }

//   Widget _bodyForm(
//       {required UserData userData, required UserFinanceData userFinanceData}) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         spacing: 20,
//         children: [
//           // Transaction type badge
//           _buildTransactionTypeBadge(),
//           sbh20,

//           // Date and time picker
//           _dateTimePicker(),
//           sbh20,

//           // Amount with income/expense toggle
//           Row(
//             children: [
//               // Income/expense toggle button
//               Padding(
//                 padding: const EdgeInsets.only(right: 10),
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     backgroundColor: isIncomeSelected
//                         ? color3.withAlpha(150)
//                         : Colors.redAccent,
//                     minimumSize: Size(120, 50),
//                   ),
//                   child: Text(
//                     isIncomeSelected ? "Income" : "Expense",
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: color4,
//                     ),
//                   ),
//                   onPressed: () => setState(() {
//                     isIncomeSelected = !isIncomeSelected;
//                   }),
//                 ),
//               ),

//               // Amount field
//               Expanded(
//                 child: textfield(
//                   controller: _amountController,
//                   hintText: "00.00",
//                   lableText: "Amount",
//                   prefixIconData: Icons.currency_rupee_sharp,
//                 ),
//               ),
//             ],
//           ),
//           sbh20,

//           // Payee field
//           textfield(
//             controller: _payeeController,
//             hintText: isIncomeSelected ? "From Payeer" : "To Payee",
//             lableText: isIncomeSelected ? "From Payeer" : "To Payee",
//             prefixIconData: Icons.person_outline,
//           ),
//           sbh20,

//           // Description field
//           textfield(
//             controller: _descriptionController,
//             hintText: "Description",
//             lableText: "Description",
//             prefixIconData: Icons.description_outlined,
//           ),
//           sbh20,

//           // Category field
//           textfield(
//             controller: _categoryController,
//             prefixIconData: Icons.category_rounded,
//             hintText: "Select Category",
//             lableText: "Category",
//             readOnly: true,
//             sufixIconData: Icons.arrow_drop_down_circle_outlined,
//             onTap: () => _showCategorySelector(context),
//           ),
//           sbh20,

//           // Payment mode field
//           textfield(
//             controller: _paymentModeController,
//             prefixIconData: Icons.payments_rounded,
//             hintText: "Select Payment Mode",
//             lableText: "Payment Mode",
//             readOnly: true,
//             sufixIconData: Icons.arrow_drop_down_circle_outlined,
//             onTap: () => _showAccountSelection(userFinanceData),
//           ),

//           // Show selected bank details if applicable
//           if (selectedBank != null) _buildSelectedBankCard(),

//           sbh20,

//           // Group field
//           textfield(
//             controller: _groupController,
//             prefixIconData: Icons.group_add_rounded,
//             hintText: "Add Group Transaction",
//             lableText: "Group Transaction",
//             readOnly: true,
//             sufixIconData: Icons.arrow_drop_down_circle_outlined,
//             onTap: () => _showGroupSelection(userFinanceData, userData),
//           ),

//           // Show selected group details if applicable
//           if (selectedGroup != null) _buildSelectedGroupCard(userData),

//           // Extra space at bottom for floating button
//           SizedBox(height: 80),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionTypeBadge() {
//     final transactionType = widget.transaction.transactionType;
//     final bool isTransfer =
//         transactionType == TransactionType.transfer.displayName;
//     final Color badgeColor =
//         isTransfer ? color2 : (isIncomeSelected ? Colors.green : Colors.red);

//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: badgeColor.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: badgeColor, width: 1.5),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isTransfer
//                 ? Icons.swap_horiz
//                 : (isIncomeSelected
//                     ? Icons.arrow_upward
//                     : Icons.arrow_downward),
//             color: badgeColor,
//           ),
//           sbw5,
//           Text(
//             "Original: ${widget.transaction.transactionType}",
//             style: TextStyle(
//               color: badgeColor,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _dateTimePicker() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       spacing: 20,
//       children: [
//         Expanded(
//           child: textfield(
//             controller: TextEditingController(
//               text: "${_selectedDate.toLocal()}".split(' ')[0],
//             ),
//             hintText: "Select Date",
//             prefixIconData: Icons.calendar_today,
//             readOnly: true,
//             onTap: () async {
//               DateTime? pickedDate = await showDatePicker(
//                 context: context,
//                 initialDate: _selectedDate,
//                 firstDate: DateTime(2000),
//                 lastDate: DateTime.now(),
//               );
//               if (pickedDate != null) {
//                 setState(() {
//                   _selectedDate = pickedDate;
//                 });
//               }
//             },
//           ),
//         ),
//         Expanded(
//           child: textfield(
//             controller: TextEditingController(
//               text: _selectedTime.format(context),
//             ),
//             hintText: "Select Time",
//             prefixIconData: Icons.access_time,
//             readOnly: true,
//             onTap: () async {
//               TimeOfDay? pickedTime = await showTimePicker(
//                 context: context,
//                 initialTime: _selectedTime,
//               );
//               if (pickedTime != null) {
//                 setState(() {
//                   _selectedTime = pickedTime;
//                 });
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSelectedBankCard() {
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 10),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: color3.withAlpha(100), width: 1),
//       ),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.account_balance, color: color3),
//                 sbw10,
//                 Text(
//                   selectedBank!.bankAccountName ?? "Bank Account",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//             Divider(),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Total Balance:"),
//                 Text(
//                   "₹ ${selectedBank!.totalBalance ?? '0'}",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             sbh5,
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Available Balance:"),
//                 Text(
//                   "₹ ${selectedBank!.availableBalance ?? '0'}",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSelectedGroupCard(UserData userData) {
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 10),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: color3.withAlpha(100), width: 1),
//       ),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.group, color: color3),
//                 sbw10,
//                 Text(
//                   selectedGroup!.name ?? "Group",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 if (selectedGroup?.creatorId == userData.uid)
//                   Chip(
//                     label: Text("Creator",
//                         style: TextStyle(fontSize: 10, color: Colors.white)),
//                     backgroundColor: Colors.green,
//                     padding: EdgeInsets.zero,
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     visualDensity: VisualDensity.compact,
//                   ),
//               ],
//             ),
//             Divider(),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Total Amount:"),
//                 Text(
//                   "₹ ${selectedGroup!.totalAmount ?? '0'}",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             sbh5,
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Your Balance:"),
//                 Text(
//                   "₹ ${selectedGroup!.membersBalance?[userData.uid] ?? '0'}",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _updateButton(UserData userData, UserFinanceData userFinanceData) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//       width: double.infinity,
//       height: 60,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color3,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//           elevation: 3,
//         ),
//         onPressed: isButtonDisabled
//             ? null
//             : () => _updateTransaction(userData, userFinanceData),
//         child: isButtonLoading
//             ? CircularProgressIndicator.adaptive(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               )
//             : Text(
//                 "Update Transaction",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                 ),
//               ),
//       ),
//     );
//   }

//   void _showCategorySelector(BuildContext context) {
//     showModalBottomSheet(
//       isScrollControlled: true,
//       context: context,
//       builder: (context) {
//         return Container(
//           height: MediaQuery.of(context).size.height * 0.7,
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: color4,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight: Radius.circular(20),
//             ),
//           ),
//           child: SelectCategory(
//             isIncome: isIncomeSelected,
//             onTap: (selectedCategory) {
//               setState(() {
//                 _categoryController.text = selectedCategory;
//               });
//               Navigator.pop(context);
//             },
//             selectedCategory: _categoryController.text,
//           ),
//         );
//       },
//     );
//   }

//   void _showAccountSelection(UserFinanceData userFinanceData) {
//     showModalBottomSheet(
//       isScrollControlled: true,
//       context: context,
//       builder: (context) {
//         bool isCash =
//             _paymentModeController.text == PaymentModes.cash.displayName;

//         return Container(
//           height: MediaQuery.of(context).size.height * 0.7,
//           padding: EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Select Account",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: color3,
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () => Navigate().goBack(),
//                     icon: Icon(Icons.close, color: color3),
//                   ),
//                 ],
//               ),
//               Divider(),
//               Expanded(
//                 child: ListView(
//                   children: [
//                     // Cash option
//                     _buildAccountSelectionTile(
//                       title: "Cash",
//                       leadingIcon: Icons.wallet,
//                       subtitle: "Balance: ${userFinanceData.cash?.amount}",
//                       isSelected: isCash,
//                       onTap: () {
//                         setState(() {
//                           _paymentModeController.text =
//                               PaymentModes.cash.displayName;
//                           selectedBank = null;
//                           _groupController.clear();
//                           selectedGroup = null;
//                         });
//                         Navigator.pop(context);
//                       },
//                     ),

//                     // Bank accounts
//                     ...userFinanceData.listOfBankAccounts!.map((bankAccount) {
//                       bool isBankAccount =
//                           (selectedBank?.bid == bankAccount.bid);
//                       return _buildAccountSelectionTile(
//                         title: bankAccount.bankAccountName ?? "Bank Account",
//                         leadingIcon: Icons.account_balance,
//                         subtitle:
//                             "Total: ${bankAccount.totalBalance} | Available: ${bankAccount.availableBalance}",
//                         isSelected: isBankAccount,
//                         onTap: () {
//                           setState(() {
//                             _paymentModeController.text =
//                                 PaymentModes.bankAccount.displayName;
//                             selectedBank = bankAccount;
//                             _groupController.clear();
//                             selectedGroup = null;
//                           });
//                           Navigator.pop(context);
//                         },
//                       );
//                     }),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildAccountSelectionTile({
//     required String title,
//     required IconData leadingIcon,
//     required String subtitle,
//     required bool isSelected,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 6),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//         side: BorderSide(
//           color: isSelected ? color3 : Colors.grey.shade300,
//           width: isSelected ? 2 : 1,
//         ),
//       ),
//       elevation: isSelected ? 3 : 1,
//       child: ListTile(
//         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         leading: CircleAvatar(
//           backgroundColor:
//               isSelected ? color3.withOpacity(0.2) : Colors.grey.shade100,
//           child: Icon(leadingIcon, color: isSelected ? color3 : color2),
//         ),
//         title: Text(
//           title,
//           style: TextStyle(
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//             color: isSelected ? color3 : color1,
//           ),
//         ),
//         subtitle: Text(subtitle),
//         trailing: isSelected ? Icon(Icons.check_circle, color: color3) : null,
//         onTap: onTap,
//       ),
//     );
//   }

//   void _showGroupSelection(UserFinanceData userFinanceData, UserData userData) {
//     showModalBottomSheet(
//       isScrollControlled: true,
//       context: context,
//       builder: (context) {
//         List<Group> groupList = userFinanceData.listOfGroups!.toList();

//         return Container(
//           height: MediaQuery.of(context).size.height * 0.7,
//           padding: EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Select Group",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: color3,
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () => Navigate().goBack(),
//                     icon: Icon(Icons.close, color: color3),
//                   ),
//                 ],
//               ),
//               Divider(),
//               Text(
//                 "Your Groups",
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey,
//                 ),
//               ),
//               sbh10,
//               Expanded(
//                 child: groupList.isEmpty
//                     ? Center(child: Text("No groups found"))
//                     : ListView.builder(
//                         itemCount: groupList.length,
//                         itemBuilder: (context, index) {
//                           Group group = groupList[index];
//                           bool isSelected = _groupController.text == group.name;
//                           return _buildGroupSelectionTile(
//                             group: group,
//                             isSelected: isSelected,
//                             isCreator: group.creatorId == userData.uid,
//                             userData: userData,
//                             onTap: () {
//                               setState(() {
//                                 _groupController.text =
//                                     isSelected ? '' : group.name ?? '';
//                                 selectedGroup = isSelected ? null : group;

//                                 // Clear payment mode selection
//                                 if (!isSelected) {
//                                   _paymentModeController.clear();
//                                   selectedBank = null;
//                                 }
//                               });
//                               Navigator.pop(context);
//                             },
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildGroupSelectionTile({
//     required Group group,
//     required bool isSelected,
//     required bool isCreator,
//     required UserData userData,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 6),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//         side: BorderSide(
//           color: isSelected ? color3 : Colors.grey.shade300,
//           width: isSelected ? 2 : 1,
//         ),
//       ),
//       elevation: isSelected ? 3 : 1,
//       child: ListTile(
//         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         leading: CircleAvatar(
//           backgroundColor:
//               isSelected ? color3.withOpacity(0.2) : Colors.grey.shade100,
//           child: Icon(Icons.group, color: isSelected ? color3 : color2),
//         ),
//         title: Row(
//           children: [
//             Text(
//               group.name ?? "Group",
//               style: TextStyle(
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 color: isSelected ? color3 : color1,
//               ),
//             ),
//             sbw5,
//             if (isCreator)
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: Colors.green,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   "Creator",
//                   style: TextStyle(fontSize: 10, color: Colors.white),
//                 ),
//               ),
//           ],
//         ),
//         subtitle: Text(
//             "Your Balance: ${group.membersBalance?[userData.uid] ?? '0'} ₹"),
//         trailing: isSelected ? Icon(Icons.check_circle, color: color3) : null,
//         onTap: onTap,
//       ),
//     );
//   }

// // __________________________________________________________________________ //

//   Future<void> _updateTransaction(
//       UserData userData, UserFinanceData userFinanceData) async {
//     setState(() {
//       isButtonDisabled = true;
//       isButtonLoading = true;
//     });

//     try {
//       // Validate inputs
//       final validationError = _validateInputs(userFinanceData, userData);
//       if (validationError != null) {
//         snackbarToast(
//           context: context,
//           text: validationError,
//           icon: Icons.error,
//         );
//         _resetButtonState();
//         return;
//       }

//       // Get the updated transaction data
//       final updatedTransaction = _prepareUpdatedTransaction();

//       if (updatedTransaction == null) {
//         snackbarToast(
//           context: context,
//           text: "Failed to prepare transaction data.",
//           icon: Icons.error,
//         );
//         _resetButtonState();
//         return;
//       }

//       // Update transaction
//       final success = await ref
//           .read(userFinanceDataNotifierProvider.notifier)
//           .updateTransaction(updatedTransaction);

//       // Handle balance updates based on changes
//       if (success) {
//         _handleBalanceUpdates(userData, userFinanceData, updatedTransaction);

//         snackbarToast(
//           context: context,
//           text: "Transaction Updated ✅",
//           icon: Icons.check_circle,
//         );

//         // Return the updated transaction to the previous screen
//         Navigator.pop(context, updatedTransaction);
//       } else {
//         snackbarToast(
//           context: context,
//           text: "Failed to update transaction.",
//           icon: Icons.error,
//         );
//       }
//     } catch (e) {
//       Logger().e("Error updating transaction: $e");
//       snackbarToast(
//         context: context,
//         text: "An error occurred: $e",
//         icon: Icons.error,
//       );
//     }

//     _resetButtonState();
//   }

//   String? _validateInputs(UserFinanceData userFinanceData, UserData userData) {
//     final amountText = _amountController.text.trim();
//     final category = _categoryController.text.trim();
//     final paymentMode = _paymentModeController.text.trim();
//     final group = _groupController.text.trim();

//     // Amount validation
//     if (amountText.isEmpty) return "Amount cannot be empty.";
//     final amount = double.tryParse(amountText);
//     if (amount == null) return "Invalid amount entered.";
//     if (amount == 0) return "Amount cannot be zero.";

//     // Ensure only one of payment mode or group is selected
//     if (paymentMode.isNotEmpty && group.isNotEmpty) {
//       return "You cannot select both a payment mode and a group.";
//     }

//     // Payee validation
//     if (_payeeController.text.trim().isEmpty) {
//       return "Payee cannot be empty.";
//     }

//     // Payment mode validation
//     if (paymentMode.isEmpty && group.isEmpty) {
//       return "Please select a payment mode or a group.";
//     }

//     // Check for sufficient balance in the selected payment mode
//     // We need to account for the original transaction amount when checking balances
//     double originalAmount = double.tryParse(this.originalAmount) ?? 0;
//     double newAmount = isIncomeSelected ? amount : -amount;

//     if (paymentMode == "Cash" && !isIncomeSelected) {
//       double currentCash = double.parse(userFinanceData.cash?.amount ?? '0');
//       // Add back original amount if it was an expense
//       if (originalAmount < 0) {
//         currentCash -= originalAmount; // Double negative = addition
//       }
//       if (amount > currentCash) {
//         return "Insufficient cash balance.";
//       }
//     }

//     if (paymentMode == "Bank Account" && !isIncomeSelected) {
//       double bankBalance = double.parse(selectedBank?.availableBalance ?? '0');
//       // If this was also originally a bank transaction for the same bank
//       if (originalPaymentMode == "Bank Account" &&
//           originalBankId == selectedBank?.bid) {
//         // Add back original amount if it was an expense
//         if (originalAmount < 0) {
//           bankBalance -= originalAmount; // Double negative = addition
//         }
//       }
//       if (amount > bankBalance) {
//         return "Insufficient bank account balance.";
//       }
//     }

//     // Category validation
//     if (category.isEmpty) return "Please select a category.";

//     // Group validation
//     if (group.isNotEmpty) {
//       if (selectedGroup == null) {
//         return "Invalid group selected.";
//       }

//       double memberBalance =
//           double.parse(selectedGroup!.membersBalance?[userData.uid] ?? '0');
//       double groupBalance = double.parse(selectedGroup!.totalAmount ?? '0');

//       // If this was also originally a group transaction for the same group
//       if (widget.transaction.isGroupTransaction &&
//           originalGroupId == selectedGroup?.gid) {
//         // Add back original amount
//         if (originalAmount < 0) {
//           memberBalance -= originalAmount; // Double negative = addition
//           groupBalance -= originalAmount;
//         } else {
//           memberBalance -= originalAmount; // Subtract positive amount
//           groupBalance -= originalAmount;
//         }
//       }

//       if (!isIncomeSelected &&
//           memberBalance < amount &&
//           (selectedGroup?.creatorId != userData.uid)) {
//         return "Insufficient member balance in the group.";
//       } else if (!isIncomeSelected &&
//           (selectedGroup?.creatorId == userData.uid) &&
//           groupBalance < amount) {
//         return "Insufficient group balance.";
//       }
//     }

//     // Date and time validation
//     final now = DateTime.now();
//     final selectedDateTime = DateTime(
//       _selectedDate.year,
//       _selectedDate.month,
//       _selectedDate.day,
//       _selectedTime.hour,
//       _selectedTime.minute,
//     );
//     if (selectedDateTime.isAfter(now)) {
//       return "Date and time cannot be in the future.";
//     }

//     return null; // No validation errors
//   }

//   Transaction? _prepareUpdatedTransaction() {
//     // Format amount string with appropriate sign
//     String amount = _amountController.text.replaceAll('-', '').trim();
//     if (!isIncomeSelected) amount = "-$amount";

//     // Create updated transaction based on original with changes
//     return widget.transaction.copyWith(
//       amount: amount,
//       category: _categoryController.text.trim(),
//       date: _selectedDate,
//       time: _selectedTime,
//       description: _descriptionController.text.trim(),
//       methodOfPayment: _paymentModeController.text.trim(),
//       payee: _payeeController.text.trim(),
//       transactionType: isIncomeSelected
//           ? TransactionType.income.displayName
//           : TransactionType.expense.displayName,
//       isGroupTransaction: _groupController.text.isNotEmpty,
//       gid: selectedGroup?.gid,
//       groupName: selectedGroup?.name,
//       bankAccountId: selectedBank?.bid,
//       bankAccountName: selectedBank?.bankAccountName,
//     );
//   }

//   Future<void> _handleBalanceUpdates(UserData userData,
//       UserFinanceData userFinanceData, Transaction updatedTransaction) async {
//     final userFinanceProvider =
//         ref.read(userFinanceDataNotifierProvider.notifier);

//     // Compare old and new payment methods
//     final oldPaymentMode = widget.transaction.methodOfPayment;
//     final newPaymentMode = updatedTransaction.methodOfPayment;

//     // Calculate amount changes
//     final oldAmount = double.parse(widget.transaction.amount ?? '0');
//     final newAmount = double.parse(updatedTransaction.amount ?? '0');
//     final amountDifference = newAmount - oldAmount;

//     // Handle cash updates
//     if (oldPaymentMode == PaymentModes.cash.displayName &&
//         newPaymentMode == PaymentModes.cash.displayName) {
//       // Update cash by the difference
//       final currentCash = double.parse(userFinanceData.cash?.amount ?? '0');
//       final newCash = (currentCash + amountDifference).toString();

//       await userFinanceProvider.updateUserCashAmount(
//         uid: userData.uid ?? '',
//         amount: newCash,
//       );
//     } else if (oldPaymentMode == PaymentModes.cash.displayName) {
//       // Reverse old cash transaction
//       final currentCash = double.parse(userFinanceData.cash?.amount ?? '0');
//       final newCash = (currentCash - oldAmount).toString();

//       await userFinanceProvider.updateUserCashAmount(
//         uid: userData.uid ?? '',
//         amount: newCash,
//       );
//     } else if (newPaymentMode == PaymentModes.cash.displayName) {
//       // Add new cash transaction
//       final currentCash = double.parse(userFinanceData.cash?.amount ?? '0');
//       final newCash = (currentCash + newAmount).toString();

//       await userFinanceProvider.updateUserCashAmount(
//         uid: userData.uid ?? '',
//         amount: newCash,
//       );
//     }

//     // Handle bank account updates
//     if (oldPaymentMode == PaymentModes.bankAccount.displayName) {
//       // Find original bank account
//       final oldBank = userFinanceData.listOfBankAccounts?.firstWhere(
//         (bank) => bank.bid == widget.transaction.bankAccountId,
//         orElse: () => BankAccount(),
//       );

//       if (oldBank?.bid != null) {
//         // Reverse old bank transaction
//         final currentAvailable = double.parse(oldBank!.availableBalance ?? '0');
//         final currentTotal = double.parse(oldBank.totalBalance ?? '0');

//         final newAvailable = (currentAvailable - oldAmount).toString();
//         final newTotal = (currentTotal - oldAmount).toString();

//         await userFinanceProvider.updateBankAccountBalance(
//           uid: userData.uid ?? '',
//           bankAccountId: oldBank.bid!,
//           availableBalance: newAvailable,
//           totalBalance: newTotal,
//         );
//       }
//     }

//     if (newPaymentMode == PaymentModes.bankAccount.displayName &&
//         selectedBank?.bid != null) {
//       // Add new bank transaction
//       final currentAvailable =
//           double.parse(selectedBank!.availableBalance ?? '0');
//       final currentTotal = double.parse(selectedBank!.totalBalance ?? '0');

//       final newAvailable = (currentAvailable + newAmount).toString();
//       final newTotal = (currentTotal + newAmount).toString();

//       await userFinanceProvider.updateBankAccountBalance(
//         uid: userData.uid ?? '',
//         bankAccountId: selectedBank!.bid!,
//         availableBalance: newAvailable,
//         totalBalance: newTotal,
//       );
//     }

//     // Handle group updates
//     if (widget.transaction.isGroupTransaction) {
//       // Find original group
//       final oldGroup = userFinanceData.listOfGroups?.firstWhere(
//         (group) => group.gid == widget.transaction.gid,
//         orElse: () => Group(),
//       );

//       if (oldGroup?.gid != null) {
//         // Reverse old group transaction
//         final currentGroupAmount = double.parse(oldGroup!.totalAmount ?? '0');
//         final currentMemberAmount =
//             double.parse(oldGroup.membersBalance?[userData.uid] ?? '0');

//         final newGroupAmount = (currentGroupAmount - oldAmount).toString();
//         final newMemberAmount = (currentMemberAmount - oldAmount).toString();

//         await userFinanceProvider.updateGroupAmount(
//           gid: oldGroup.gid!,
//           amount: newGroupAmount,
//           uid: userData.uid ?? '',
//           memberAmount: newMemberAmount,
//         );
//       }
//     }

//     if (updatedTransaction.isGroupTransaction && selectedGroup?.gid != null) {
//       // Add new group transaction
//       final currentGroupAmount =
//           double.parse(selectedGroup!.totalAmount ?? '0');
//       final currentMemberAmount =
//           double.parse(selectedGroup!.membersBalance?[userData.uid] ?? '0');

//       final newGroupAmount = (currentGroupAmount + newAmount).toString();
//       final newMemberAmount = (currentMemberAmount + newAmount).toString();

//       await userFinanceProvider.updateGroupAmount(
//         gid: selectedGroup!.gid!,
//         amount: newGroupAmount,
//         uid: userData.uid ?? '',
//         memberAmount: newMemberAmount,
//       );
//     }
//   }

//   void _resetButtonState() {
//     setState(() {
//       isButtonDisabled = false;
//       isButtonLoading = false;
//     });
//   }
// }

// // Helper TextField widget - same as in ExpenseIncomeFields
// Widget textfield({
//   required TextEditingController controller,
//   String? hintText,
//   String? lableText,
//   IconData? prefixIconData,
//   IconData? sufixIconData,
//   bool isSufixWidget = false,
//   Widget? sufixWidget,
//   bool readOnly = false,
//   void Function()? onTap,
// }) {
//   return TextFormField(
//     controller: controller,
//     readOnly: readOnly,
//     onTap: (onTap != null) ? onTap : null,
//     keyboardType:
//         (lableText == "Amount") ? TextInputType.numberWithOptions() : null,
//     decoration: InputDecoration(
//       labelText: (lableText != null) ? lableText : null,
//       hintText: (hintText != null) ? hintText : null,
//       labelStyle: TextStyle(
//         color: color1,
//       ),
//       prefixIcon: (prefixIconData != null)
//           ? Icon(
//               prefixIconData,
//               color: color3,
//             )
//           : null,
//       suffixIcon: (isSufixWidget)
//           ? sufixWidget
//           : (sufixIconData != null)
//               ? Icon(
//                   sufixIconData,
//                   color: color3,
//                   size: 30,
//                 )
//               : null,
//       border: OutlineInputBorder(
//         borderSide: BorderSide(color: color1),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderSide: BorderSide(
//           color: color3,
//         ),
//         borderRadius: BorderRadius.circular(10),
//       ),
//     ),
//   );
// }
