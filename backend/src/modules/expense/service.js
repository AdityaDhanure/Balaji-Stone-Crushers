import { expenseQueries } from './query.js';
import { withCache, invalidateExpenseCache } from '../../middleware/cacheMiddleware.js';

export const expenseService = {
  // ─── Categories ────────────────────────────────────────────────────────────

  async getCategories(activeOnly = true) {
    return withCache.get(
      `expenses:categories:${activeOnly}`,
      () => expenseQueries.getAllCategories(activeOnly)
    );
  },

  async createCategory(data) {
    const result = await expenseQueries.createCategory(data);
    await invalidateExpenseCache();
    return result;
  },

  // ─── Manual Expenses ────────────────────────────────────────────────────────

  async getExpenses(filters = {}) {
    // Cache only when there are no active filters
    const hasFilters = filters.category_id || filters.start_date || filters.end_date || filters.status;
    if (!hasFilters) {
      return withCache.get('expenses:all', () => expenseQueries.getAllExpenses(filters));
    }
    return expenseQueries.getAllExpenses(filters);
  },

  async getExpense(id) {
    return withCache.get(`expenses:detail:${id}`, () => expenseQueries.getExpenseById(id));
  },

  async createExpense(data) {
    const expenseNumber = await expenseQueries.getNextExpenseNumber();
    const result = await expenseQueries.createExpense({ ...data, expense_number: expenseNumber });
    await invalidateExpenseCache();
    return result;
  },

  async updateExpense(id, data) {
    const result = await expenseQueries.updateExpense(id, data);
    await invalidateExpenseCache();
    return result;
  },

  async deleteExpense(id) {
    const result = await expenseQueries.deleteExpense(id);
    await invalidateExpenseCache();
    return result;
  },

  async getNextExpenseNumber() {
    return withCache.get('expenses:next_number', () => expenseQueries.getNextExpenseNumber());
  },

  async approveExpense(id, approvedBy) {
    const result = await expenseQueries.approveExpense(id, approvedBy);
    await invalidateExpenseCache();
    return result;
  },

  // ─── Unified (all 9 sources) ───────────────────────────────────────────────

  async getFullUnifiedExpenses(filters = {}) {
    // Never cache the unified list — it spans multiple tables
    return expenseQueries.getFullUnifiedExpenses(filters);
  },

  async getFullExpenseSummary(filters = {}) {
    return expenseQueries.getFullExpenseSummary(filters);
  },
};