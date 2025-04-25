import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionDetails extends ConsumerStatefulWidget {
  final Transaction transaction;
  final bool isFromDetailScreen;

  const TransactionDetails({
    super.key,
    required this.transaction,
    this.isFromDetailScreen = false,
  });

  @override
  ConsumerState<TransactionDetails> createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends ConsumerState<TransactionDetails>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataNotifierProvider);
    final userFinanceData = ref.watch(userFinanceDataNotifierProvider);

    // Format transaction information
    final amountValue = double.tryParse(
            widget.transaction.amount?.replaceAll('-', '') ?? '0') ??
        0;
    final isExpense = widget.transaction.transactionType ==
        TransactionType.expense.displayName;
    final isIncome = widget.transaction.transactionType ==
        TransactionType.income.displayName;
    final isTransfer = widget.transaction.transactionType ==
        TransactionType.transfer.displayName;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: color4,
        appBar: _buildAppBar(userData),
        body: _isDeleting
            ? _buildDeletingIndicator()
            : _buildTransactionDetails(context, userData, userFinanceData,
                amountValue, isExpense, isIncome, isTransfer),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(UserData userData) {
    return AppBar(
      backgroundColor: color4,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Transaction Details',
        style: TextStyle(
          color: color1,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (userData.uid == widget.transaction.uid)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: color1),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (String value) {
              if (value == 'edit') {
                _editTransaction();
              } else if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
          ),
      ],
    );
  }

  Widget _buildDeletingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: color3),
          const SizedBox(height: 16),
          Text(
            'Deleting transaction...',
            style: TextStyle(
              fontSize: 16,
              color: color1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(
      BuildContext context,
      UserData userData,
      dynamic userFinanceData,
      double amountValue,
      bool isExpense,
      bool isIncome,
      bool isTransfer) {
    // Format date and time
    final dateFormatted = widget.transaction.date != null
        ? DateFormat('MMM dd, yyyy').format(widget.transaction.date!)
        : 'N/A';
    final timeFormatted = widget.transaction.time != null
        ? widget.transaction.time!.format(context)
        : 'N/A';

    // Get type-based colors and icons
    final typeColor = isExpense
        ? Colors.red
        : isIncome
            ? Colors.green
            : color3;
    final typeIcon = isExpense
        ? Icons.arrow_downward
        : isIncome
            ? Icons.arrow_upward
            : Icons.swap_horiz;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount and Transaction Type Card
            _buildAmountCard(amountValue, typeColor, typeIcon, isExpense,
                isIncome, isTransfer),
            const SizedBox(height: 24),

            // Transaction Details Section
            _buildSectionHeader('Transaction Details'),
            _buildDetailsCard([
              _buildDetailRow('Category',
                  widget.transaction.category ?? 'Unknown', Icons.category),
              _buildDetailRow(
                  'Description',
                  widget.transaction.description ?? 'No description',
                  Icons.description),
              if (widget.transaction.payee?.isNotEmpty ?? false)
                _buildDetailRow(
                    'Payee', widget.transaction.payee!, Icons.person),
              _buildDetailRow('Date & Time', '$dateFormatted at $timeFormatted',
                  Icons.calendar_today),
              _buildDetailRow(
                  'Payment Method',
                  widget.transaction.methodOfPayment ?? 'Not specified',
                  Icons.payment),
              if (widget.transaction.isTransferTransaction == true &&
                  widget.transaction.methodOfPayment2?.isNotEmpty == true)
                _buildDetailRow('Transfer To',
                    widget.transaction.methodOfPayment2!, Icons.swap_horiz),
            ]),
            const SizedBox(height: 24),

            // Bank/Group Information (if applicable)
            _buildAccountInformation(),

            // Notes (if any)
            if (widget.transaction.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              _buildSectionHeader('Notes'),
              _buildNotesCard(widget.transaction.description!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(
    double amount,
    Color typeColor,
    IconData typeIcon,
    bool isExpense,
    bool isIncome,
    bool isTransfer,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // colors: [typeColor.withAlpha(204), typeColor.withAlpha(51)],
            colors: [
              typeColor.withAlpha(100),
              typeColor.withAlpha(200),
              typeColor.withAlpha(200),
              typeColor.withAlpha(100)
            ],
            stops: const [
              0.0,
              0.25,
              0.75,
              1.0
            ], // Adjust stops to give typeColor more space
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withAlpha(77), // 0.3 * 255 ≈ 77
                  child: Icon(typeIcon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExpense
                          ? 'Expense'
                          : isIncome
                              ? 'Income'
                              : 'Transfer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color1,
        ),
      ),
    );
  }

  Widget _buildDetailsCard(List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color3, size: 22),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInformation() {
    // Only show account info if bank or group data exists
    if (widget.transaction.bankAccountName != null ||
        widget.transaction.groupName != null ||
        widget.transaction.bankAccountName2 != null ||
        widget.transaction.groupName2 != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Account Information'),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (widget.transaction.bankAccountName != null)
                    _buildDetailRow(
                        widget.transaction.isTransferTransaction == true
                            ? 'From Account'
                            : 'Bank Account',
                        widget.transaction.bankAccountName!,
                        Icons.account_balance),
                  if (widget.transaction.groupName != null)
                    _buildDetailRow(
                        widget.transaction.isTransferTransaction == true
                            ? 'From Group'
                            : 'Group',
                        widget.transaction.groupName!,
                        Icons.group),
                  if (widget.transaction.bankAccountName2 != null)
                    _buildDetailRow(
                        'To Account',
                        widget.transaction.bankAccountName2!,
                        Icons.account_balance),
                  if (widget.transaction.groupName2 != null)
                    _buildDetailRow('To Group', widget.transaction.groupName2!,
                        Icons.group),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildNotesCard(String notes) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(),
            Text(
              notes,
              style: TextStyle(
                fontSize: 16,
                color: color1,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editTransaction() {
    // Navigate().push(
    //   EditTransactionDetails(transaction: widget.transaction),
    // );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
            'Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: color3)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTransaction();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction() async {
    setState(() {
      _isDeleting = true;
    });

    final success = await ref
        .read(userFinanceDataNotifierProvider.notifier)
        .deleteTransaction(
          widget.transaction.uid ?? '',
          widget.transaction.tid ?? '',
        );

    if (success) {
      snackbarToast(
        context: context,
        text: 'Transaction deleted successfully',
        icon: Icons.check_circle,
      );

      // Give the snackbar time to appear before navigating
      await Future.delayed(const Duration(milliseconds: 300));

      if (context.mounted) {
        if (widget.isFromDetailScreen) {
          Navigate().goBack();
          Navigate().goBack();
        } else {
          Navigate().goBack();
        }
      }
    } else {
      setState(() {
        _isDeleting = false;
      });

      if (context.mounted) {
        snackbarToast(
          context: context,
          text: 'Failed to delete transaction',
          icon: Icons.error_outline,
        );
      }
    }
  }
}
