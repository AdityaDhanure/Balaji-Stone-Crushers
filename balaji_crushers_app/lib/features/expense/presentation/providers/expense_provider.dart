import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/features/expense/data/models/expense_models.dart';
import 'package:balaji_crushers_app/features/expense/data/repositories/expense_repository.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (_) => ExpenseRepository(),
);

int _compareUnifiedExpensesNewestFirst(UnifiedExpense a, UnifiedExpense b) {
  final byDate = b.expenseDate.compareTo(a.expenseDate);
  if (byDate != 0) return byDate;
  return b.id.compareTo(a.id);
}

int _compareExpensesNewestFirst(Expense a, Expense b) {
  final byDate = b.expenseDate.compareTo(a.expenseDate);
  if (byDate != 0) return byDate;
  return (b.id ?? 0).compareTo(a.id ?? 0);
}

// ─── Category Provider ────────────────────────────────────────────────────────

final expenseCategoriesProvider =
    FutureProvider<List<ExpenseCategory>>((ref) async {
  return ref.read(expenseRepositoryProvider).getCategories();
});

// ─── Next Expense Number ──────────────────────────────────────────────────────

final nextExpenseNumberProvider = FutureProvider<String>((ref) async {
  return ref.read(expenseRepositoryProvider).getNextExpenseNumber();
});

// ─── Unified Expense List ─────────────────────────────────────────────────────

typedef UnifiedExpenseParams = ({
  DateTime startDate,
  DateTime endDate,
  String? type,
});

final unifiedExpensesProvider = FutureProvider.family<List<UnifiedExpense>,
    UnifiedExpenseParams>((ref, p) async {
  return (await ref.read(expenseRepositoryProvider).getUnifiedExpenses(
        startDate: p.startDate,
        endDate: p.endDate,
        type: p.type,
      ))
    ..sort(_compareUnifiedExpensesNewestFirst);
});

// ─── Unified Expense Summary ──────────────────────────────────────────────────

typedef ExpenseSummaryParams = ({DateTime startDate, DateTime endDate});

final expenseSummaryProvider = FutureProvider.family<UnifiedExpenseSummary,
    ExpenseSummaryParams>((ref, p) async {
  return ref.read(expenseRepositoryProvider).getExpenseSummary(
        startDate: p.startDate,
        endDate: p.endDate,
      );
});

// ─── Manual Expenses (filtered list for add/edit context) ────────────────────

final expensesProvider =
    FutureProvider.family<List<Expense>, Map<String, dynamic>?>((ref, filters) async {
  final repo = ref.read(expenseRepositoryProvider);
  return (await repo.getExpenses(
    categoryId: filters?['category_id'] as int?,
    startDate: filters?['start_date'] as DateTime?,
    endDate: filters?['end_date'] as DateTime?,
    status: filters?['status'] as String?,
    limit: filters?['limit'] as int?,
  ))
    ..sort(_compareExpensesNewestFirst);
});
