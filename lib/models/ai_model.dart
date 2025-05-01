import 'package:flutter/material.dart';

// Simplified AI model class with a single model
class AIModel {
  static const String modelId = 'gpt-4.1-nano';
  static const String modelName = 'GPT-4.1 Nano';
  static const String modelDescription = 'Advanced AI for financial assistance';
  static const IconData modelIcon = Icons.auto_awesome;
  
  // Get the model name for display
  static String getModelName() {
    return modelName;
  }
  
  // Get the model ID for API calls
  static String getModelId() {
    return modelId;
  }
}
