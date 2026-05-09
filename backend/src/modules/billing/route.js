import express from 'express';
import { invoiceController, itemController, paymentController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = express.Router();

// All routes require authentication
router.use(protect);

// Invoice endpoints
router.get('/stats', invoiceController.getStats);
router.get('/next-number', invoiceController.getNextNumber);
router.get('/', invoiceController.getAll);
router.get('/:id', invoiceController.getById);
router.post('/', invoiceController.create);
router.put('/:id', invoiceController.update);
router.patch('/:id/status', invoiceController.updateStatus);
router.delete('/:id', invoiceController.delete);

// Invoice item endpoints
router.get('/:invoiceId/items', itemController.getByInvoice);
router.post('/items', itemController.create);
router.put('/items/:id', itemController.update);
router.delete('/items/:id', itemController.delete);

// Payment endpoints
router.get('/:invoiceId/payments', paymentController.getByInvoice);
router.post('/payments', paymentController.create);
router.delete('/payments/:id', paymentController.delete);

export default router;