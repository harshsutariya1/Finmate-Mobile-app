import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/investment.dart';
import 'package:finmate/providers/investment_provider.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddInvestmentScreen extends ConsumerStatefulWidget {
  final Investment? existingInvestment;

  const AddInvestmentScreen({
    super.key, 
    this.existingInvestment,
  });

  @override
  ConsumerState<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends ConsumerState<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _currentValueController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedType = 'Stocks';
  DateTime _purchaseDate = DateTime.now();
  DateTime? _maturityDate;

  final List<String> _investmentTypes = [
    'Stocks',
    'Mutual Funds',
    'Fixed Deposits',
    'Crypto',
    'Gold',
    'Real Estate',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingInvestment != null) {
      _initializeWithExistingData();
    }
  }

  void _initializeWithExistingData() {
    final investment = widget.existingInvestment!;
    _nameController.text = investment.name;
    _amountController.text = investment.initialAmount.toString();
    _currentValueController.text = investment.currentAmount.toString();
    _targetController.text = investment.targetAmount.toString();
    _institutionController.text = investment.institution;
    _accountNumberController.text = investment.accountNumber;
    _notesController.text = investment.notes;
    _selectedType = investment.type;
    _purchaseDate = investment.purchaseDate;
    _maturityDate = investment.maturityDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _currentValueController.dispose();
    _targetController.dispose();
    _institutionController.dispose();
    _accountNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingInvestment != null;
    
    return Scaffold(
      backgroundColor: color4,
      appBar: AppBar(
        backgroundColor: color4,
        title: Text(isEditing ? 'Edit Investment' : 'Add Investment'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isMaturityDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMaturityDate ? (_maturityDate ?? DateTime.now()) : _purchaseDate,
      firstDate: isMaturityDate ? _purchaseDate : DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isMaturityDate) {
          _maturityDate = picked;
        } else {
          _purchaseDate = picked;
        }
      });
    }
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Investment Type
            _buildSectionTitle('Investment Type'),
            _buildInvestmentTypeSelector(),
            sbh20,
            
            // Basic Details
            _buildSectionTitle('Basic Details'),
            _buildTextField(
              controller: _nameController,
              labelText: 'Investment Name',
              prefixIcon: Icons.label_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            sbh15,
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _amountController,
                    labelText: 'Initial Amount',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                sbw15,
                Expanded(
                  child: _buildTextField(
                    controller: _currentValueController,
                    labelText: 'Current Value',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            sbh15,
            _buildTextField(
              controller: _targetController,
              labelText: 'Target Amount (Optional)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.flag,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                }
                return null;
              },
            ),
            sbh20,
            
            // Dates
            _buildSectionTitle('Dates'),
            _buildDateSelector(
              title: 'Purchase Date',
              date: _purchaseDate,
              onTap: () => _selectDate(context, false),
            ),
            sbh15,
            _buildDateSelector(
              title: 'Maturity Date (Optional)',
              date: _maturityDate,
              onTap: () => _selectDate(context, true),
              isOptional: true,
            ),
            sbh20,
            
            // Additional Details
            _buildSectionTitle('Additional Details (Optional)'),
            _buildTextField(
              controller: _institutionController,
              labelText: 'Institution/Broker',
              prefixIcon: Icons.business,
            ),
            sbh15,
            _buildTextField(
              controller: _accountNumberController,
              labelText: 'Account/Reference Number',
              prefixIcon: Icons.numbers,
            ),
            sbh15,
            _buildTextField(
              controller: _notesController,
              labelText: 'Notes',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),
            sbh20,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color1,
        ),
      ),
    );
  }

  Widget _buildInvestmentTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _investmentTypes.map((type) {
        final isSelected = _selectedType == type;
        
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedType = type;
              });
            }
          },
          backgroundColor: Colors.white,
            selectedColor: color3.withAlpha(51), 
          labelStyle: TextStyle(
            color: isSelected ? color3 : color1,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: color2),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: color3) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color3, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildDateSelector({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
    bool isOptional = false,
  }) {
    final formattedDate = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : 'Select Date';
        
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: color3),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color2,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 16,
                    color: date != null ? color1 : Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isOptional && date != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _maturityDate = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveInvestment,
        style: ElevatedButton.styleFrom(
          backgroundColor: color3,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.existingInvestment != null ? 'Update Investment' : 'Add Investment',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = ref.read(userDataNotifierProvider);
      final initialAmount = double.parse(_amountController.text);
      final currentAmount = double.parse(_currentValueController.text);
      final targetAmount = _targetController.text.isNotEmpty
          ? double.parse(_targetController.text)
          : 0.0;

      final investment = Investment(
        id: widget.existingInvestment?.id ?? const Uuid().v4(),
        uid: userData.uid ?? '',
        name: _nameController.text,
        type: _selectedType,
        initialAmount: initialAmount,
        currentAmount: currentAmount,
        targetAmount: targetAmount,
        progressPercentage: 0, // Will be calculated in provider
        purchaseDate: _purchaseDate,
        maturityDate: _maturityDate,
        notes: _notesController.text,
        institution: _institutionController.text,
        accountNumber: _accountNumberController.text,
      );

      bool success = false;
      if (widget.existingInvestment == null) {
        success = await ref.read(investmentNotifierProvider.notifier)
            .addInvestment(investment);
      } else {
        success = await ref.read(investmentNotifierProvider.notifier)
            .updateInvestment(investment);
      }

      if (success && mounted) {
        Navigate().goBack();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving investment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: const Text('Are you sure you want to delete this investment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.existingInvestment != null) {
      setState(() {
        _isLoading = true;
      });
      
      final success = await ref.read(investmentNotifierProvider.notifier)
          .deleteInvestment(widget.existingInvestment!.uid, widget.existingInvestment!.id);
          
      if (success && mounted) {
        Navigate().goBack();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting investment')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
