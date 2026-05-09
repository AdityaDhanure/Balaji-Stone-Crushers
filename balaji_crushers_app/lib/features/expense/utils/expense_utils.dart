import 'package:flutter/material.dart';

/// Converts a backend icon-name string to a Flutter [IconData].
/// Used across the expense module widgets — single source of truth.
IconData expenseIconData(String? iconName) {
  switch (iconName) {
    case 'construction':        return Icons.construction;
    case 'bolt':                return Icons.bolt;
    case 'local_gas_station':   return Icons.local_gas_station;
    case 'build':               return Icons.build;
    case 'business_center':     return Icons.business_center;
    case 'payments':            return Icons.payments;
    case 'security':            return Icons.security;
    case 'home':                return Icons.home;
    case 'phone':               return Icons.phone;
    case 'more_horiz':          return Icons.more_horiz;
    case 'flash_on':            return Icons.flash_on;
    case 'account_balance':     return Icons.account_balance;
    case 'people':              return Icons.people;
    case 'account_balance_wallet': return Icons.account_balance_wallet;
    case 'factory':             return Icons.factory;
    case 'receipt_long':        return Icons.receipt_long;
    default:                    return Icons.category;
  }
}

/// Parses a hex color string like '#FF9800' into a Flutter [Color].
Color parseHexColor(String? hex, {Color fallback = const Color(0xFF9E9E9E)}) {
  if (hex == null) return fallback;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return fallback;
  }
}

/// Formats a double amount into a readable Indian currency string.
String formatAmount(double value) {
  if (value >= 10000000) return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
  if (value >= 100000)   return '₹${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000)     return '₹${(value / 1000).toStringAsFixed(1)}K';
  return '₹${value.toStringAsFixed(0)}';
}
