import { Router } from 'express';
import { settingsController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = Router();

router.use(protect);

router.get('/', settingsController.getAll);
router.get('/export', settingsController.exportSettings);
router.get('/company', settingsController.getCompanyInfo);
router.get('/invoice', settingsController.getInvoiceSettings);
router.get('/alerts', settingsController.getAlertSettings);
router.get('/category/:category', settingsController.getByCategory);
router.get('/:key', settingsController.getByKey);

router.post('/', settingsController.create);
router.post('/bulk', settingsController.bulkUpdate);
router.post('/import', settingsController.importSettings);

router.patch('/', settingsController.update);

router.delete('/:key', settingsController.delete);
router.post('/reset', settingsController.resetToDefaults);

export default router;