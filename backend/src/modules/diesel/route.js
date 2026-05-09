import express from 'express';
import { dieselController, consumptionController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = express.Router();

router.use(protect);

// Stock overview
router.get('/stock', dieselController.getStockOverview);

// Diesel purchase endpoints
router.get('/purchases', dieselController.getAllPurchases);
router.get('/purchases/:id', dieselController.getPurchaseById);
router.post('/purchases', dieselController.createPurchase);
router.put('/purchases/:id', dieselController.updatePurchase);
router.delete('/purchases/:id', dieselController.deletePurchase);

// Consumption endpoints
router.get('/consumption', consumptionController.getAllConsumption);
router.get('/consumption/vehicle/:vehicleId', consumptionController.getConsumptionByVehicleId);
router.get('/consumption/range', consumptionController.getConsumptionByDateRange);
router.get('/consumption/grouped', consumptionController.getConsumptionGroupedByDate);
router.get('/consumption/vehicle-wise', consumptionController.getVehicleWiseConsumption);
router.get('/pump-wise', consumptionController.getPumpWisePayments);
router.post('/consumption', consumptionController.createConsumption);
router.put('/consumption/:id', consumptionController.updateConsumption);
router.delete('/consumption/:id', consumptionController.deleteConsumption);

export default router;