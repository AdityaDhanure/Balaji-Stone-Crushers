import express from 'express';
import { customerController, contactController, walletController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = express.Router();

// All routes require authentication
router.use(protect);

// Utility endpoints
router.get('/search', customerController.search);
router.get('/next-code', customerController.getNextCode);
router.get('/active', customerController.getActive);

// Customer CRUD
router.get('/', customerController.getAll);
router.get('/:id', customerController.getById);
router.post('/', customerController.create);
router.put('/:id', customerController.update);
router.delete('/:id', customerController.delete);

// Contact management
router.get('/:customerId/contacts', contactController.getByCustomer);
router.post('/:customerId/contacts', contactController.create);
router.delete('/contacts/:id', contactController.delete);

// Wallet/ledger management
router.get('/:customerId/wallet', walletController.getByCustomer);
router.post('/wallet/transactions', walletController.create);
router.delete('/wallet/transactions/:id', walletController.delete);

export default router;