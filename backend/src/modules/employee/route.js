import express from 'express';
import { departmentController, employeeController, documentController, leaveController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = express.Router();

router.use(protect);

// Department endpoints
router.get('/departments', departmentController.getAll);
router.post('/departments', departmentController.create);
router.put('/departments/:id', departmentController.update);
router.delete('/departments/:id', departmentController.delete);

// Employee endpoints
router.get('/next-code', employeeController.getNextCode);
router.get('/stats', employeeController.getStats);
router.get('/active', employeeController.getActive);
router.get('/all', employeeController.getAll);
router.get('/:id', employeeController.getById);
router.get('/', employeeController.getAll);
router.post('/', employeeController.create);
router.put('/:id', employeeController.update);
router.delete('/:id', employeeController.delete);

// Document endpoints
router.get('/:employeeId/documents', documentController.getByEmployee);
router.post('/:employeeId/documents', documentController.create);
router.delete('/documents/:id', documentController.delete);

// Leave management endpoints
router.get('/leaves/pending', leaveController.getPending);
router.get('/:employeeId/leaves', leaveController.getByEmployee);
router.post('/leaves', leaveController.create);
router.patch('/leaves/:id/status', leaveController.updateStatus);
router.delete('/leaves/:id', leaveController.delete);

export default router;