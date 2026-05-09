import { notificationService } from './service.js';

const getAuthUser = (req) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  try {
    const jwt = require('jsonwebtoken');
    const { verify } = jwt;
    const { JWT_SECRET } = require('../../config/env.js');
    return verify(authHeader.split(' ')[1], JWT_SECRET);
  } catch {
    return null;
  }
};

export const notificationController = {
  async getNotifications(req, res, next) {
    try {
      const user = getAuthUser(req);
      const limit = parseInt(req.query.limit) || 50;
      const notifications = await notificationService.getNotifications(user?.id, limit);
      res.json({ success: true, data: notifications });
    } catch (err) {
      next(err);
    }
  },

  async getUnreadCount(req, res, next) {
    try {
      const user = getAuthUser(req);
      const count = await notificationService.getUnreadCount(user?.id);
      res.json({ success: true, data: { count } });
    } catch (err) {
      next(err);
    }
  },

  async markAsRead(req, res, next) {
    try {
      const notification = await notificationService.markAsRead(req.params.id);
      res.json({ success: true, data: notification });
    } catch (err) {
      next(err);
    }
  },

  async markAllAsRead(req, res, next) {
    try {
      const user = getAuthUser(req);
      const count = await notificationService.markAllAsRead(user?.id);
      res.json({ success: true, data: { count } });
    } catch (err) {
      next(err);
    }
  },

  async create(req, res, next) {
    try {
      const notification = await notificationService.create(req.body);
      res.status(201).json({ success: true, data: notification });
    } catch (err) {
      next(err);
    }
  },

  async delete(req, res, next) {
    try {
      await notificationService.delete(req.params.id);
      res.json({ success: true, message: 'Deleted' });
    } catch (err) {
      next(err);
    }
  },

  async getDueAlerts(req, res, next) {
    try {
      const alerts = await notificationService.getDueAlerts();
      res.json({ success: true, data: alerts });
    } catch (err) {
      next(err);
    }
  },
};