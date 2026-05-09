  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:balaji_crushers_app/core/utils/ist_date_utils.dart';

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  bool parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return true;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  DateTime _istNowDate() {
    return appTodayIstDate();
  }

  DateTime _toDate(dynamic v) {
    final raw = v?.toString() ?? '';
    if (raw.isEmpty) return _istNowDate();

    final hasExplicitTimezone =
        RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);
    if (raw.contains('T') && hasExplicitTimezone) {
      return appParseIstDate(raw) ?? _istNowDate();
    }

    final datePart = raw.split('T').first;
    final parts = datePart.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    return appParseIstDate(raw) ?? _istNowDate();
  }

  int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  Map<String, dynamic>? _parseSubInfo(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }

  // ─── ExpenseCategory ──────────────────────────────────────────────────────────

  class ExpenseCategory {
    final int? id;
    final String name;
    final String? description;
    final String? icon;
    final String? color;
    final bool isActive;

    const ExpenseCategory({
      this.id,
      required this.name,
      this.description,
      this.icon,
      this.color,
      this.isActive = true,
    });

    factory ExpenseCategory.fromJson(Map<String, dynamic> json) => ExpenseCategory(
          id: _toIntOrNull(json['id']),
          name: json['name']?.toString() ?? '',
          description: json['description'] as String?,
          icon: json['icon'] as String?,
          color: json['color'] as String?,
          isActive: parseBool(json['is_active']),
        );
  }

  // ─── Expense (manual entries only) ───────────────────────────────────────────

  class Expense {
    final int? id;
    final String? expenseNumber;
    final int? categoryId;
    final DateTime expenseDate;
    final double amount;
    final String paymentMode;
    final String? vendorName;
    final String? description;
    final String? referenceNumber;
    final String status;
    final int? createdBy;
    final DateTime? createdAt;
    final String? categoryName;
    final String? categoryIcon;
    final String? categoryColor;
    final String? createdByName;

    const Expense({
      this.id,
      this.expenseNumber,
      this.categoryId,
      required this.expenseDate,
      this.amount = 0,
      this.paymentMode = 'cash',
      this.vendorName,
      this.description,
      this.referenceNumber,
      this.status = 'approved',
      this.createdBy,
      this.createdAt,
      this.categoryName,
      this.categoryIcon,
      this.categoryColor,
      this.createdByName,
    });

    factory Expense.fromJson(Map<String, dynamic> json) => Expense(
      id: _toIntOrNull(json['id']),
      expenseNumber: json['expense_number']?.toString(),
      categoryId: _toIntOrNull(json['category_id']),
      expenseDate: _toDate(json['expense_date']),
      amount: _toDouble(json['amount']),
      paymentMode: json['payment_mode']?.toString() ?? 'cash',
      vendorName: json['vendor_name']?.toString(),
      description: json['description']?.toString(),
      referenceNumber: json['reference_number']?.toString(),
      status: json['status']?.toString() ?? 'approved',
      createdBy: _toIntOrNull(json['created_by']),
      createdAt: appParseIstDateTime(json['created_at']),
      categoryName: json['category_name']?.toString(),
      categoryIcon: json['category_icon']?.toString(),
      categoryColor: json['category_color']?.toString(),
      createdByName: json['created_by_name']?.toString(),
    );
  }

  // ─── UnifiedExpense (all 9 sources) ──────────────────────────────────────────

  class UnifiedExpense {
    /// One of: manual | diesel | blast | royalty | maintenance | salary | advance | production
    final String source;
    final int id;
    final String? reference;
    final DateTime expenseDate;
    final double amount;
    final String? description;
    final String? vendorName;
    final String? paymentMode;
    final String status;
    final String categoryName;
    final String? categoryIcon;
    final String? categoryColor;
    /// Source-specific extra fields parsed from JSON
    final Map<String, dynamic>? subInfo;

    const UnifiedExpense({
      required this.source,
      required this.id,
      this.reference,
      required this.expenseDate,
      required this.amount,
      this.description,
      this.vendorName,
      this.paymentMode,
      required this.status,
      required this.categoryName,
      this.categoryIcon,
      this.categoryColor,
      this.subInfo,
    });

    factory UnifiedExpense.fromJson(Map<String, dynamic> json) => UnifiedExpense(
      source: json['source']?.toString() ?? 'manual',
      id: _toIntOrNull(json['id']) ?? 0,
      reference: json['reference']?.toString(),
      expenseDate: _toDate(json['expense_date']),
      amount: _toDouble(json['amount']),
      description: json['description']?.toString(),
      vendorName: json['vendor_name']?.toString(),
      paymentMode: json['payment_mode']?.toString(),
      status: json['status']?.toString() ?? 'paid',
      categoryName: json['category_name']?.toString() ?? 'Unknown',
      categoryIcon: json['category_icon']?.toString(),
      categoryColor: json['category_color']?.toString(),
      subInfo: _parseSubInfo(json['sub_info']),
    );

    // ─── Helpers ────────────────────────────────────────────────────────────────

    bool get isPending => status == 'pending' || status == 'draft';

    String get sourceDisplay {
      switch (source) {
        case 'manual':      return 'Manual';
        case 'diesel':      return 'Diesel';
        case 'blast':       return 'Blast';
        case 'royalty':     return 'Royalty';
        case 'maintenance': return 'Maintenance';
        case 'salary':      return 'Salary';
        case 'advance':     return 'Advance';
        case 'production':  return 'Production';
        default:            return source;
      }
    }

    IconData get sourceIcon {
      switch (source) {
        case 'manual':      return Icons.receipt_long;
        case 'diesel':      return Icons.local_gas_station;
        case 'blast':       return Icons.flash_on;
        case 'royalty':     return Icons.account_balance;
        case 'maintenance': return Icons.build;
        case 'salary':      return Icons.people;
        case 'advance':     return Icons.account_balance_wallet;
        case 'production':  return Icons.factory;
        default:            return Icons.attach_money;
      }
    }

    Color get sourceColor {
      switch (source) {
        case 'manual':      return const Color(0xFF2196F3);
        case 'diesel':      return const Color(0xFF4CAF50);
        case 'blast':       return const Color(0xFFF44336);
        case 'royalty':     return const Color(0xFF9C27B0);
        case 'maintenance': return const Color(0xFFFF9800);
        case 'salary':      return const Color(0xFF3F51B5);
        case 'advance':     return const Color(0xFF009688);
        case 'production':  return const Color(0xFF607D8B);
        default:            return const Color(0xFF9E9E9E);
      }
    }
  }

  // ─── UnifiedExpenseSummary (all 9 sources) ────────────────────────────────────

  class UnifiedExpenseSummary {
    final double manual;
    final double dieselPaid;
    final double dieselPending;
    final double blast;
    final double royalty;
    final double maintenance;
    final double salariesPaid;
    final double salariesPending;
    final double advances;
    final double productionCost;
    final double total;

    const UnifiedExpenseSummary({
      this.manual = 0,
      this.dieselPaid = 0,
      this.dieselPending = 0,
      this.blast = 0,
      this.royalty = 0,
      this.maintenance = 0,
      this.salariesPaid = 0,
      this.salariesPending = 0,
      this.advances = 0,
      this.productionCost = 0,
      this.total = 0,
    });

    static const empty = UnifiedExpenseSummary();

    factory UnifiedExpenseSummary.fromJson(Map<String, dynamic> json) =>
      UnifiedExpenseSummary(
        manual:           _toDouble(json['manual']),
        dieselPaid:       _toDouble(json['diesel_paid']),
        dieselPending:    _toDouble(json['diesel_pending']),
        blast:            _toDouble(json['blast']),
        royalty:          _toDouble(json['royalty']),
        maintenance:      _toDouble(json['maintenance']),
        salariesPaid:     _toDouble(json['salaries_paid']),
        salariesPending:  _toDouble(json['salaries_pending']),
        advances:         _toDouble(json['advances']),
        productionCost:   _toDouble(json['production_cost']),
        total:            _toDouble(json['total']),
      );
  }
