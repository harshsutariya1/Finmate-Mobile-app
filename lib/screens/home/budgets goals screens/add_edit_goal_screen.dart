import 'package:finmate/constants/colors.dart';
import 'package:finmate/models/accounts.dart';
import 'package:finmate/models/goal.dart';
import 'package:finmate/providers/goals_provider.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  final String? goalId;

  const AddEditGoalScreen({super.key, this.goalId});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _initialAmountController;
  late TextEditingController _notesController;
  late TextEditingController _contributionAmountController;

  // Add TabController for edit mode
  late TabController _tabController;

  DateTime? _selectedDeadline;
  BankAccount? _selectedBankAccount;
  BankAccount? _selectedContributionBank;
  bool _isLoading = false;
  bool _isAddingContribution = false;
  GoalStatus _selectedStatus = GoalStatus.active;

  // To keep track if this is an edit (true) or add (false) operation
  bool get isEditing => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _targetAmountController = TextEditingController();
    _initialAmountController = TextEditingController(text: '0');
    _notesController = TextEditingController();
    _contributionAmountController = TextEditingController(text: '0');

    // Initialize TabController if in edit mode
    _tabController = TabController(length: 2, vsync: this);

    // If editing, populate form with existing goal data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditing) {
        _loadGoalData();
      }
    });
  }

  void _loadGoalData() {
    final goals = ref.read(goalsNotifierProvider);
    final goal = goals.firstWhere((g) => g.id == widget.goalId);

    _nameController.text = goal.name;
    _targetAmountController.text = goal.targetAmount.toStringAsFixed(0);
    _notesController.text = goal.notes ?? '';
    _selectedDeadline = goal.deadline;
    _selectedStatus = goal.status;

    // We don't populate initial amount when editing as it doesn't make sense
    _initialAmountController.text = '0';

    // Bank account info is retrieved but used only in the view
    if (goal.primaryBankAccountId != null) {
      final bankAccounts =
          ref.read(userFinanceDataNotifierProvider).listOfBankAccounts ?? [];
      // Use where().firstOrNull to safely find the bank account or get null
      _selectedBankAccount = bankAccounts
          .where((bank) => bank.bid == goal.primaryBankAccountId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _initialAmountController.dispose();
    _notesController.dispose();
    _contributionAmountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bankAccounts =
        ref.watch(userFinanceDataNotifierProvider).listOfBankAccounts ?? [];

    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
        elevation: 0,
        title: Text(isEditing ? 'Edit Goal' : 'Create New Goal'),
        centerTitle: true,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmDeleteGoal,
            ),
        ],
        bottom: isEditing
            ? TabBar(
                controller: _tabController,
                labelColor: color3,
                unselectedLabelColor: Colors.grey,
                indicatorColor: color3,
                tabs: const [
                  Tab(text: "GOAL DETAILS"),
                  Tab(text: "ADD CONTRIBUTION"),
                ],
              )
            : null,
      ),
      body: isEditing
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildEditGoalForm(bankAccounts),
                _buildContributionForm(bankAccounts),
              ],
            )
          : _buildCreateGoalForm(bankAccounts),
    );
  }

  Widget _buildCreateGoalForm(List<BankAccount> bankAccounts) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Goal Name
            _buildTextField(
              controller: _nameController,
              label: 'Goal Name',
              icon: Icons.flag,
              validator: (value) => value != null && value.trim().isEmpty
                  ? 'Please enter a goal name'
                  : null,
            ),
            const SizedBox(height: 16),

            // Target Amount
            _buildTextField(
              controller: _targetAmountController,
              label: 'Target Amount (₹)',
              icon: Icons.account_balance_wallet,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a target amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Initial Amount
            _buildTextField(
              controller: _initialAmountController,
              label: 'Initial Contribution (₹)',
              icon: Icons.savings,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Initial amount can be empty
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }

                // Validate initial amount against target
                final targetAmount =
                    double.tryParse(_targetAmountController.text) ?? 0;
                if (amount > targetAmount) {
                  return 'Initial amount cannot exceed target';
                }

                // Validate selected bank account if amount > 0
                if (amount > 0 && _selectedBankAccount == null) {
                  return 'Please select a bank account';
                }

                // Check if bank has sufficient funds
                if (amount > 0 && _selectedBankAccount != null) {
                  final balance = double.parse(
                      _selectedBankAccount!.availableBalance ?? '0');
                  if (amount > balance) {
                    return 'Insufficient funds in selected account';
                  }
                }

                return null;
              },
            ),
            const SizedBox(height: 16),

            // Bank Account Selection
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Bank Account',
                prefixIcon: const Icon(Icons.account_balance, color: color3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: color3, width: 2),
                ),
              ),
              value: _selectedBankAccount?.bid,
              hint: const Text('Select Bank Account'),
              items: bankAccounts.map((bank) {
                return DropdownMenuItem<String>(
                  value: bank.bid,
                  child: Text(
                    '${bank.bankAccountName} (₹${bank.availableBalance})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? bankId) {
                setState(() {
                  _selectedBankAccount = bankAccounts.firstWhere((bank) => bank.bid == bankId);
                });
              },
              validator: (value) {
                final initialAmount =
                    double.tryParse(_initialAmountController.text) ?? 0;
                if (initialAmount > 0 && value == null) {
                  return 'Please select a bank account';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Deadline Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Deadline (Optional)',
                  prefixIcon: const Icon(Icons.calendar_today, color: color3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _selectedDeadline != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedDeadline = null;
                            });
                          },
                        )
                      : null,
                ),
                child: Text(
                  _selectedDeadline != null
                      ? DateFormat.yMMMd().format(_selectedDeadline!)
                      : 'No Deadline Set',
                  style: TextStyle(
                    color: _selectedDeadline != null
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            _buildTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              icon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Create Goal Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _saveGoal,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Goal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditGoalForm(List<BankAccount> bankAccounts) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Goal Name
            _buildTextField(
              controller: _nameController,
              label: 'Goal Name',
              icon: Icons.flag,
              validator: (value) => value != null && value.trim().isEmpty
                  ? 'Please enter a goal name'
                  : null,
            ),
            const SizedBox(height: 16),

            // Target Amount
            _buildTextField(
              controller: _targetAmountController,
              label: 'Target Amount (₹)',
              icon: Icons.account_balance_wallet,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a target amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Deadline Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Deadline (Optional)',
                  prefixIcon: const Icon(Icons.calendar_today, color: color3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _selectedDeadline != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedDeadline = null;
                            });
                          },
                        )
                      : null,
                ),
                child: Text(
                  _selectedDeadline != null
                      ? DateFormat.yMMMd().format(_selectedDeadline!)
                      : 'No Deadline Set',
                  style: TextStyle(
                    color: _selectedDeadline != null
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            _buildTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              icon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Status Selection
            DropdownButtonFormField<GoalStatus>(
              decoration: InputDecoration(
                labelText: 'Status',
                prefixIcon:
                    const Icon(Icons.check_circle_outline, color: color3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: _selectedStatus,
              items: GoalStatus.values.map((status) {
                return DropdownMenuItem<GoalStatus>(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Update Goal Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _saveGoal,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Goal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionForm(List<BankAccount> bankAccounts) {
    return Form(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Goal Progress Info
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<Goal?>(
                      future: _getCurrentGoal(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final goal = snapshot.data;
                        if (goal == null) {
                          return const Text('Goal details not available');
                        }

                        final currencyFormat = NumberFormat.currency(
                            locale: 'en_IN', symbol: '₹', decimalDigits: 0);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current: ${currencyFormat.format(goal.currentAmount)}',
                              style: const TextStyle(fontSize: 15),
                            ),
                            Text(
                              'Target: ${currencyFormat.format(goal.targetAmount)}',
                              style: const TextStyle(fontSize: 15),
                            ),
                            Text(
                              'Remaining: ${currencyFormat.format(goal.remainingAmount)}',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: goal.progressPercentage,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  goal.progressPercentage >= 1.0
                                      ? Colors.green
                                      : color3),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(goal.progressPercentage * 100).round()}% complete',
                              style: TextStyle(
                                color: goal.progressPercentage >= 1.0
                                    ? Colors.green
                                    : color3,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contribution Amount
            _buildTextField(
              controller: _contributionAmountController,
              label: 'Contribution Amount (₹)',
              icon: Icons.savings,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 16),

            // Bank Account Selection for contribution
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Source Bank Account',
                prefixIcon: const Icon(Icons.account_balance, color: color3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: color3, width: 2),
                ),
              ),
              value: _selectedContributionBank?.bid,
              hint: const Text('Select Bank Account'),
              items: bankAccounts.map((bank) {
                return DropdownMenuItem<String>(
                  value: bank.bid,
                  child: Text(
                    '${bank.bankAccountName} (₹${bank.availableBalance})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? bankId) {
                setState(() {
                  _selectedContributionBank = bankAccounts.firstWhere((bank) => bank.bid == bankId);
                });
              },
            ),
            const SizedBox(height: 24),

            // Add Contribution Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isAddingContribution ? null : _addContribution,
                child: _isAddingContribution
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Add Contribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Contribution History Section
            const Text(
              'Contribution History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<Goal?>(
              future: _getCurrentGoal(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final goal = snapshot.data;
                if (goal == null || goal.contributions.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('No contributions yet'),
                      ),
                    ),
                  );
                }

                // Sort contributions by date - newest first
                final sortedContributions =
                    List<GoalContribution>.from(goal.contributions)
                      ..sort((a, b) => b.date.compareTo(a.date));

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: sortedContributions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final contribution = sortedContributions[index];
                      final currencyFormat = NumberFormat.currency(
                          locale: 'en_IN', symbol: '₹', decimalDigits: 0);

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: color3,
                          child: Icon(Icons.savings, color: Colors.white),
                        ),
                        title: Text(
                          currencyFormat.format(contribution.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From: ${contribution.bankAccountName}'),
                            Text(
                                'Date: ${DateFormat.yMMMd().format(contribution.date)}'),
                          ],
                        ),
                        trailing: Text(
                          DateFormat.jm().format(contribution.date),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get current goal data
  Future<Goal?> _getCurrentGoal() async {
    final goals = ref.read(goalsNotifierProvider);
    try {
      return goals.firstWhere((g) => g.id == widget.goalId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: color3, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: color3,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  void _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(userDataNotifierProvider).uid!;
      final targetAmount = double.parse(_targetAmountController.text);
      final initialAmount =
          isEditing ? 0.0 : double.parse(_initialAmountController.text);

      if (isEditing) {
        // Updating existing goal
        final goals = ref.read(goalsNotifierProvider);
        final existingGoal = goals.firstWhere((g) => g.id == widget.goalId);

        final updatedGoal = existingGoal.copyWith(
          name: _nameController.text.trim(),
          targetAmount: targetAmount,
          deadline: _selectedDeadline,
          notes: _notesController.text.trim(),
          status: _selectedStatus,
          setDeadlineToNull: _selectedDeadline == null,
        );

        final success = await ref
            .read(goalsNotifierProvider.notifier)
            .updateGoal(userId, updatedGoal);

        if (success) {
          Navigator.pop(context);
          snackbarToast(
              context: context,
              text: "Goal updated successfully!",
              icon: Icons.check_circle);
        } else {
          snackbarToast(
              context: context,
              text: "Failed to update goal",
              icon: Icons.error);
        }
      } else {
        // Creating new goal
        final newGoal = Goal(
          name: _nameController.text.trim(),
          targetAmount: targetAmount,
          currentAmount: initialAmount,
          deadline: _selectedDeadline,
          notes: _notesController.text.trim(),
          primaryBankAccountId:
              initialAmount > 0 ? _selectedBankAccount!.bid : null,
          primaryBankAccountName:
              initialAmount > 0 ? _selectedBankAccount!.bankAccountName : null,
        );

        final success = await ref.read(goalsNotifierProvider.notifier).addGoal(
              userId,
              newGoal,
              ref,
            );

        if (success) {
          Navigator.pop(context);
          snackbarToast(
              context: context,
              text: "Goal created successfully!",
              icon: Icons.check_circle);
        } else {
          snackbarToast(
              context: context,
              text: "Failed to create goal",
              icon: Icons.error);
        }
      }
    } catch (e) {
      snackbarToast(context: context, text: "Error: $e", icon: Icons.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmDeleteGoal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text(
          'Are you sure you want to delete this goal? All funds will be returned to their original bank accounts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigate().goBack(); // Close dialog

              setState(() {
                _isLoading = true;
              });

              try {
                final userId = ref.read(userDataNotifierProvider).uid!;
                final success =
                    await ref.read(goalsNotifierProvider.notifier).deleteGoal(
                          userId,
                          widget.goalId!,
                          ref,
                        );

                if (success) {
                  snackbarToast(
                    context: context,
                    text: "Goal deleted and funds returned",
                    icon: Icons.check_circle,
                  );
                  Navigate().goBack(); // Return to goals list
                } else {
                  snackbarToast(
                    context: context,
                    text: "Failed to delete goal",
                    icon: Icons.error,
                  );
                }
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addContribution() async {
    // Validate inputs
    final contributionAmount =
        double.tryParse(_contributionAmountController.text);
    if (contributionAmount == null || contributionAmount <= 0) {
      snackbarToast(
        context: context,
        text: "Please enter a valid contribution amount",
        icon: Icons.error,
      );
      return;
    }

    if (_selectedContributionBank == null) {
      snackbarToast(
        context: context,
        text: "Please select a bank account",
        icon: Icons.error,
      );
      return;
    }

    // Check if bank has sufficient funds
    final bankBalance =
        double.parse(_selectedContributionBank!.availableBalance ?? '0');
    if (contributionAmount > bankBalance) {
      snackbarToast(
        context: context,
        text: "Insufficient funds in selected bank account",
        icon: Icons.error,
      );
      return;
    }

    setState(() {
      _isAddingContribution = true;
    });

    try {
      final userId = ref.read(userDataNotifierProvider).uid!;

      final success =
          await ref.read(goalsNotifierProvider.notifier).addContribution(
                userId,
                widget.goalId!,
                contributionAmount,
                _selectedContributionBank!.bid!,
                _selectedContributionBank!.bankAccountName!,
                ref,
              );

      if (success) {
        _contributionAmountController.clear();
        setState(() {
          _selectedContributionBank = null;
        });

        // Reload goal data to reflect the new contribution
        await ref.read(goalsNotifierProvider.notifier).fetchUserGoals(userId);
        _loadGoalData();

        snackbarToast(
          context: context,
          text: "Contribution added successfully!",
          icon: Icons.check_circle,
        );
      } else {
        snackbarToast(
          context: context,
          text: "Failed to add contribution",
          icon: Icons.error,
        );
      }
    } catch (e) {
      snackbarToast(
        context: context,
        text: "Error: $e",
        icon: Icons.error,
      );
    } finally {
      setState(() {
        _isAddingContribution = false;
      });
    }
  }
}
