// Create a model class for chart data
import 'dart:ui';

// Add this class outside your widget (preferably at the bottom of file or in a separate model file)
class CategoryChartData {
  final String category;
  final double amount;
  final Color color;
  final String percentText;

  CategoryChartData(
      {required this.category,
      required this.amount,
      required this.color,
      required this.percentText});
}