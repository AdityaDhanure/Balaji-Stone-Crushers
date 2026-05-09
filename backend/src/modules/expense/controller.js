import { expenseService } from './service.js';

// req.user is injected by the protect middleware on all routes

export const expenseController = {
  // ─── Categories ───────────────────────────────────────────────────────────

  async getCategories(req, res) {
    try {
      const activeOnly = req.query.active !== 'false';
      const data = await expenseService.getCategories(activeOnly);
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async createCategory(req, res) {
    try {
      const data = await expenseService.createCategory(req.body);
      res.status(201).json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // ─── Manual Expenses ──────────────────────────────────────────────────────

  async getExpenses(req, res) {
    try {
      const { category_id, start_date, end_date, status, limit } = req.query;
      const filters = {};
      if (category_id) filters.category_id = parseInt(category_id);
      if (start_date)  filters.start_date  = start_date;
      if (end_date)    filters.end_date    = end_date;
      if (status)      filters.status      = status;
      if (limit)       filters.limit       = parseInt(limit);
      const data = await expenseService.getExpenses(filters);
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getExpense(req, res) {
    try {
      const data = await expenseService.getExpense(req.params.id);
      if (!data) return res.status(404).json({ success: false, message: 'Expense not found' });
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async createExpense(req, res) {
    try {
      const data = await expenseService.createExpense({ ...req.body, created_by: req.user?.id });
      res.status(201).json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async updateExpense(req, res) {
    try {
      const data = await expenseService.updateExpense(req.params.id, req.body);
      if (!data) return res.status(404).json({ success: false, message: 'Expense not found' });
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async deleteExpense(req, res) {
    try {
      const data = await expenseService.deleteExpense(req.params.id);
      if (!data) return res.status(404).json({ success: false, message: 'Expense not found' });
      res.json({ success: true, message: 'Expense deleted' });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async approveExpense(req, res) {
    try {
      const data = await expenseService.approveExpense(req.params.id, req.user?.id);
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getNextNumber(req, res) {
    try {
      const number = await expenseService.getNextExpenseNumber();
      res.json({ success: true, data: { expense_number: number } });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // ─── Unified (all 9 sources) ──────────────────────────────────────────────

  async getUnifiedExpenses(req, res) {
    try {
      const { start_date, end_date, type, limit } = req.query;
      const filters = {};
      if (start_date) filters.start_date = start_date;
      if (end_date)   filters.end_date   = end_date;
      if (type)       filters.type       = type;
      if (limit)      filters.limit      = parseInt(limit);
      const data = await expenseService.getFullUnifiedExpenses(filters);
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },

  async getExpenseSummary(req, res) {
    try {
      const { start_date, end_date } = req.query;
      const filters = {};
      if (start_date) filters.start_date = start_date;
      if (end_date)   filters.end_date   = end_date;
      const data = await expenseService.getFullExpenseSummary(filters);
      res.json({ success: true, data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  },
};