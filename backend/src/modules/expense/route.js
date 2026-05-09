import { Router } from 'express';
import { expenseController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = Router();

// All routes require authentication
router.use(protect);

// Category endpoints
router.get('/categories', expenseController.getCategories);
router.post('/categories', expenseController.createCategory);

// Unified endpoints (must be before /:id to avoid param conflicts)
router.get('/unified',      expenseController.getUnifiedExpenses);
router.get('/summary',      expenseController.getExpenseSummary);
router.get('/next-number',  expenseController.getNextNumber);

// Manual expense CRUD
router.get('/',        expenseController.getExpenses);
router.get('/:id',     expenseController.getExpense);
router.post('/',       expenseController.createExpense);
router.patch('/:id',          expenseController.updateExpense);
router.patch('/:id/approve',  expenseController.approveExpense);
router.delete('/:id',         expenseController.deleteExpense);

export default router;