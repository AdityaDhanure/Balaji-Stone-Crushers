import 'package:flutter/material.dart';

class FormatUtils {
  static String formatNumber(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)} L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} K';
    return value.toStringAsFixed(0);
  }

  static String formatCurrency(double value) {
    return '₹${formatNumber(value)}';
  }

  static String formatTons(double value) {
    return '${value.toStringAsFixed(1)} tons';
  }

  static String formatLiters(double value) {
    return '${value.toStringAsFixed(0)} L';
  }

  static Color parseColor(String? colorStr) {
    if (colorStr == null) return Colors.grey;
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}