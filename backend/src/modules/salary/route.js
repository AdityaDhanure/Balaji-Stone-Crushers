import { Router } from 'express';
import { salaryController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = Router();

router.use(protect);

router.get('/periods', salaryController.getPeriods);
router.get('/periods/:id', salaryController.getPeriod);
router.post('/periods', salaryController.createPeriod);
router.patch('/periods/:id/lock', salaryController.lockPeriod);

router.get('/employees', salaryController.getEmployees);

router.get('/slips/summary/:periodId', salaryController.getSalarySummary);
router.get('/slips/period/:periodId', salaryController.getSalarySlipsByPeriod);
router.get('/slips', salaryController.getSalarySlips);
router.get('/slips/:id', salaryController.getSalarySlip);
router.post('/slips/bulk/:periodId', salaryController.bulkGenerateSlips);
router.post('/slips', salaryController.generateSalarySlip);
router.patch('/slips/:id/payment', salaryController.processPayment);
router.patch('/slips/:id', salaryController.updateSalarySlip);
router.delete('/slips/:id', salaryController.deleteSalarySlip);

router.get('/advances', salaryController.getAdvances);
router.post('/advances', salaryController.createAdvance);
router.patch('/advances/:id/approve', salaryController.approveAdvance);
router.patch('/advances/:id/reject', salaryController.rejectAdvance);

router.get('/deductions', salaryController.getDeductions);
router.post('/deductions', salaryController.createDeduction);
router.patch('/deductions/:id', salaryController.updateDeduction);
router.delete('/deductions/:id', salaryController.deleteDeduction);

router.get('/earnings', salaryController.getEarnings);
router.post('/earnings', salaryController.createEarning);
router.patch('/earnings/:id', salaryController.updateEarning);
router.delete('/earnings/:id', salaryController.deleteEarning);

export default router;
