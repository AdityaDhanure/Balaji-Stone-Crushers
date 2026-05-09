import express from 'express';
import { equipmentController, maintenanceController, scheduleController, vendorController, partsController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = express.Router();

router.use(protect);

// Vendor routes (before parameterized routes)
router.get('/vendors', vendorController.getAll);
router.get('/vendors/active', vendorController.getActive);
router.get('/vendors/:id', vendorController.getById);
router.post('/vendors', vendorController.create);
router.put('/vendors/:id', vendorController.update);
router.delete('/vendors/:id', vendorController.delete);

// Parts/Spare parts routes (before parameterized routes)
router.get('/parts', partsController.getAll);
router.get('/parts/active', partsController.getActive);
router.get('/parts/next-part-number', partsController.getNextPartNumber);
router.get('/parts/predefined', partsController.getPredefinedParts);
router.get('/parts/:id', partsController.getById);
router.post('/parts', partsController.create);
router.put('/parts/:id', partsController.update);
router.delete('/parts/:id', partsController.delete);
router.post('/parts/usage', partsController.recordUsage);

// Maintenance schedules (before parameterized routes)
router.get('/schedules/due', scheduleController.getDue);
router.get('/schedules', scheduleController.getAll);
router.post('/schedules', scheduleController.create);
router.patch('/schedules/:id/complete', scheduleController.markComplete);
router.delete('/schedules/:id', scheduleController.delete);

// Equipment routes (before parameterized routes)
router.get('/equipment/next-code', equipmentController.getNextCode);
router.get('/equipment/active', equipmentController.getActive);
router.get('/equipment', equipmentController.getAll);
router.get('/equipment/:equipmentId/records', maintenanceController.getByEquipment);
router.get('/equipment/:id', equipmentController.getById);
router.post('/equipment', equipmentController.create);
router.put('/equipment/:id', equipmentController.update);
router.delete('/equipment/:id', equipmentController.delete);

// Vehicle routes (before parameterized routes)
router.get('/vehicle/:vehicleId/records', maintenanceController.getByVehicle);

// Maintenance records - specific routes first, then parameterized
router.get('/due-soon', maintenanceController.getDueSoon);
router.get('/stats', maintenanceController.getStats);
router.get('/record-parts/:id', maintenanceController.getRecordParts);
router.get('/', maintenanceController.getAll);
router.get('/:id', maintenanceController.getById);
router.post('/', maintenanceController.create);
router.put('/:id', maintenanceController.update);
router.delete('/:id', maintenanceController.delete);

export default router;
