import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/transaction_category.dart';
import 'package:flutter/material.dart';

class SelectCategory extends StatefulWidget {
  const SelectCategory({
    super.key,
    required this.onTap,
    required this.selectedCategory,
    required this.isIncome,
  });

  final String selectedCategory;
  final ValueChanged<String> onTap;
  final bool isIncome;

  @override
  State<SelectCategory> createState() => _SelectCategoryState();
}

class _SelectCategoryState extends State<SelectCategory> {
  late List<String> _filteredCategories;
  late List<String> _allCategories;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Get appropriate categories based on transaction type
    _allCategories = widget.isIncome
        ? CategoryHelpers.getAllIncomeCategories()
        : CategoryHelpers.getAllExpenseCategories();

    _filteredCategories = List.from(_allCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = List.from(_allCategories);
      } else {
        _filteredCategories = _allCategories
            .where((category) =>
                category.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search input
            _buildSearchBar(),
            sbh15,

            // Categories header
            Text(
              widget.isIncome ? "Income Categories" : "Expense Categories",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isIncome
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
            sbh15,

            // No results message
            if (_filteredCategories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: color2),
                      sbh10,
                      Text(
                        "No matching categories found",
                        style: TextStyle(color: color2),
                      ),
                    ],
                  ),
                ),
              ),

            // Category grid
            Expanded(
              child: _buildCategoryGrid(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: color3,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Done",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _filterCategories,
      decoration: InputDecoration(
        hintText: 'Search categories',
        prefixIcon: Icon(Icons.search, color: color2),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        final isSelected = widget.selectedCategory == category;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onTap(category),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? color3.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? color3 : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isSelected
                        ? color3.withOpacity(0.2)
                        : Colors.grey.shade100,
                    radius: 16,
                    child: Icon(
                      CategoryHelpers.getIconForCategory(category),
                      size: 18,
                      color: isSelected ? color3 : color2,
                    ),
                  ),
                  sbw10,
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? color3 : color1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: color3,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
