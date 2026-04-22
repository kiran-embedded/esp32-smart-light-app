import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class TFInferenceEngine {
  bool _initialized = false;
  List<String> _vocabulary = [];
  List<String> _classes = [];
  
  // Layer 1 (Dense + ReLU)
  List<List<double>> _layer1Weights = [];
  List<double> _layer1Bias = [];
  
  // Layer 2 (Dense + Softmax)
  List<List<double>> _layer2Weights = [];
  List<double> _layer2Bias = [];

  Future<void> init() async {
    if (_initialized) return;
    try {
      final String jsonStr = await rootBundle.loadString('assets/ai_model.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);

      _vocabulary = List<String>.from(data['vocabulary']);
      _classes = List<String>.from(data['classes']);
      
      _layer1Weights = _parseMatrix(data['layer1_weights']);
      _layer1Bias = _parseVector(data['layer1_bias']);
      
      _layer2Weights = _parseMatrix(data['layer2_weights']);
      _layer2Bias = _parseVector(data['layer2_bias']);
      
      _initialized = true;
      print("TensorFlow Inference Engine (Dart) initialized! Matrix dimensions loaded.");
    } catch (e) {
      print("Failed to load TF Model: $e");
    }
  }

  List<List<double>> _parseMatrix(List<dynamic> list) {
    return list.map((row) => _parseVector(row)).toList();
  }

  List<double> _parseVector(List<dynamic> list) {
    return list.map((v) => (v as num).toDouble()).toList();
  }

  String _simpleStemmer(String word) {
    if (word.length <= 3) return word;
    if (word.endsWith('ing')) return word.substring(0, word.length - 3);
    if (word.endsWith('ed')) return word.substring(0, word.length - 2);
    if (word.endsWith('es')) return word.substring(0, word.length - 2);
    if (word.endsWith('s') && !word.endsWith('ss')) return word.substring(0, word.length - 1);
    return word;
  }

  String _cleanWord(String word) {
    final cleaned = word.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    return _simpleStemmer(cleaned);
  }

  List<double> _bagOfWords(String text) {
    final words = text.split(' ')
        .map((w) => _cleanWord(w))
        .where((w) => w.isNotEmpty)
        .toList();

    List<double> bag = List.filled(_vocabulary.length, 0.0);
    for (String w in words) {
      final idx = _vocabulary.indexOf(w);
      if (idx != -1) {
        bag[idx] = 1.0;
      }
    }
    return bag;
  }

  // --- MATRIX MATH UTILS ---
  List<double> _dotProduct(List<double> input, List<List<double>> weights, List<double> bias) {
    int outSize = weights[0].length;
    List<double> output = List.filled(outSize, 0.0);
    
    for (int col = 0; col < outSize; col++) {
      double sum = 0;
      for (int row = 0; row < weights.length; row++) {
        sum += input[row] * weights[row][col];
      }
      output[col] = sum + bias[col];
    }
    return output;
  }

  List<double> _relu(List<double> input) {
    return input.map((v) => max(0.0, v)).toList();
  }

  List<double> _softmax(List<double> input) {
    double maxVal = input.reduce(max);
    List<double> exps = input.map((v) => exp(v - maxVal)).toList();
    double sumExps = exps.reduce((a, b) => a + b);
    return exps.map((v) => v / sumExps).toList();
  }

  // Predict Intent
  Map<String, double> predict(String text) {
    if (!_initialized) return {"unknown": 1.0};

    final bag = _bagOfWords(text);
    
    // Check if the user said nothing matching vocab
    if (!bag.any((v) => v > 0.0)) {
      return {"unknown": 1.0};
    }

    // Forward Pass Layer 1
    final l1_out = _dotProduct(bag, _layer1Weights, _layer1Bias);
    final l1_act = _relu(l1_out);

    // Forward Pass Layer 2
    final l2_out = _dotProduct(l1_act, _layer2Weights, _layer2Bias);
    final probabilities = _softmax(l2_out);

    // Find Best Match
    int bestIdx = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
            maxProb = probabilities[i];
            bestIdx = i;
        }
    }
    
    return {
      _classes[bestIdx]: maxProb
    };
  }
}
