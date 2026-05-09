import express from 'express';
import { vehicleController, usageController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = express.Router();

router.use(protect);

router.get('/expiries', vehicleController.getUpcomingExpiries);
router.get('/type', vehicleController.getVehiclesByType);
router.get('/', vehicleController.getAllVehicles);
router.get('/:id', vehicleController.getVehicleById);
router.post('/', vehicleController.createVehicle);
router.put('/:id', vehicleController.updateVehicle);
router.delete('/:id', vehicleController.deleteVehicle);
router.patch('/:id/odometer', vehicleController.updateOdometer);

router.get('/:vehicleId/usage', usageController.getUsageByVehicleId);
router.get('/:vehicleId/usage/by-date', usageController.getUsageByVehicleIdGroupedByDate);
router.get('/:vehicleId/usage/dates', usageController.getDistinctDatesByVehicleId);
router.get('/usage/daily', usageController.getDailyUsage);
router.get('/usage/range', usageController.getUsageByDateRange);
router.post('/usage', usageController.createUsage);
router.put('/usage/:id', usageController.updateUsage);
router.delete('/usage/:id', usageController.deleteUsage);

export default router;
