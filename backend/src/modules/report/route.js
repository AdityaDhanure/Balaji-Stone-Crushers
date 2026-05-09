import { Router } from 'express';
import { reportController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = Router();
router.use(protect);

router.get('/overview',       reportController.getOverviewSummary);
router.get('/sales',          reportController.getSalesReport);
router.get('/expense-summary', reportController.getExpenseSummary);
router.get('/profit-loss',    reportController.getProfitLoss);
router.get('/yearly-trend',   reportController.getYearlyTrend);

export default router;
