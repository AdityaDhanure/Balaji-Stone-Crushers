import express from 'express';
import { blastController, tripController, expenseController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = express.Router();

// All routes require authentication
router.use(protect);

// Utility endpoints
router.get('/next-number', blastController.getNextBlastNumber);
router.get('/active', blastController.getActiveBlast);
router.get('/trips/daily', tripController.getDailyTrips);
router.get('/vehicles/types', tripController.getVehicleTypes);
router.get('/vehicles/by-type/:type', tripController.getVehiclesByType);

// Trip endpoints for specific blast
router.get('/:blastId/trips', tripController.getTripsByBlastId);
router.get('/:blastId/trips/by-date', tripController.getTripsByBlastIdGroupedByDate);
router.get('/:blastId/trips/dates', tripController.getDistinctDatesByBlastId);

// Expense endpoints for specific blast
router.get('/:blastId/expenses', expenseController.getExpensesByBlastId);
router.get('/:blastId/expenses/by-date', expenseController.getExpensesByBlastIdGroupedByDate);
router.get('/:blastId/expenses/dates', expenseController.getDistinctExpenseDatesByBlastId);

// Main blast CRUD
router.get('/', blastController.getAllBlasts);
router.get('/:id', blastController.getBlastById);
router.post('/', blastController.createBlast);
router.put('/:id', blastController.updateBlast);
router.delete('/:id', blastController.deleteBlast);
router.patch('/:id/complete', blastController.completeBlast);
router.patch('/:id/reopen', blastController.reopenBlast);

// Trip management
router.post('/trips', tripController.createTrip);
router.put('/trips/:id', tripController.updateTrip);
router.delete('/trips/:id', tripController.deleteTrip);

// Expense management
router.post('/expenses', expenseController.createExpense);
router.put('/expenses/:id', expenseController.updateExpense);
router.delete('/expenses/:id', expenseController.deleteExpense);

export default router;