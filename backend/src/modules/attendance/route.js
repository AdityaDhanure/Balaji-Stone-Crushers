import express from 'express';
import { attendanceController, shiftController, leaveController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = express.Router();

// All routes require authentication
router.use(protect);

// Summary endpoints
router.get('/summary/daily', attendanceController.getDailySummary);
router.get('/summary/monthly/:employeeId/:year/:month', attendanceController.getMonthlySummary);

// Attendance endpoints
router.get('/by-date/:date', attendanceController.getByDate);
router.get('/employee/:employeeId', attendanceController.getByEmployee);
router.get('/', attendanceController.getAll);
router.post('/bulk', attendanceController.bulkMarkAttendance);
router.post('/', attendanceController.markAttendance);
router.put('/:id', attendanceController.update);
router.delete('/by-date/:date', attendanceController.deleteAllByDate);
router.delete('/:id', attendanceController.delete);

// Leave balance endpoint
router.get('/leave-balance/:employeeId', leaveController.getBalance);

// Shift management endpoints
router.get('/shifts', shiftController.getAll);
router.post('/shifts', shiftController.create);
router.post('/shifts/assign', shiftController.assignShift);

export default router;