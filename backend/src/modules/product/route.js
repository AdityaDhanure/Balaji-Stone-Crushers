import express from 'express';
import { productController, categoryController, rateController, productionController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = express.Router();

router.use(protect);

router.get('/next-code', productController.getNextCode);
router.get('/active', productController.getActive);

router.get('/production/daily/:date', productionController.getDailySummary);
router.get('/production/monthly/:year/:month', productionController.getMonthlyStats);
router.get('/production/by-date/:date', productionController.getByDate);
router.get('/production/', productionController.getAll);
router.get('/production/grouped', productionController.getGroupedByDate);
router.post('/production', productionController.create);
router.put('/production/:id', productionController.update);
router.delete('/production/:id', productionController.delete);

router.get('/categories/all', categoryController.getAll);
router.post('/categories', categoryController.create);
router.delete('/categories/:id', categoryController.delete);

router.get('/:productId/rates', rateController.getByProduct);
router.post('/rates', rateController.create);
router.put('/rates/:id', rateController.update);
router.delete('/rates/:id', rateController.delete);

router.get('/', productController.getAll);
router.get('/:id', productController.getById);
router.post('/', productController.create);
router.put('/:id', productController.update);
router.delete('/:id', productController.delete);

export default router;
