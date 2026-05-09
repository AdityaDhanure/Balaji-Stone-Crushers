import { Router } from 'express';
import { notificationController } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = Router();
router.use(protect);

router.get('/', notificationController.getNotifications);
router.get('/unread-count', notificationController.getUnreadCount);
router.get('/alerts', notificationController.getDueAlerts);
router.patch('/:id/read', notificationController.markAsRead);
router.patch('/read-all', notificationController.markAllAsRead);
router.post('/', notificationController.create);
router.delete('/:id', notificationController.delete);

export default router;