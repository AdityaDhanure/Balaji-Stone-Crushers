import { Router } from 'express';
import { login, getMe, logout, updateProfile, changePassword } from './controller.js';
import { protect } from '../../middleware/auth.js';

const router = Router();

router.post('/login', login);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.put('/change-password', protect, changePassword);
router.post('/logout', protect, logout);

export default router;
