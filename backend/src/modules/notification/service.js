import { notificationQueries } from './query.js';

export const notificationService = {
  async getNotifications(userId, limit = 50) {
    return await notificationQueries.getByUser(userId, limit);
  },

  async getUnreadCount(userId) {
    return await notificationQueries.getUnreadCount(userId);
  },

  async markAsRead(id) {
    return await notificationQueries.markAsRead(id);
  },

  async markAllAsRead(userId) {
    return await notificationQueries.markAllAsRead(userId);
  },

  async create(data) {
    return await notificationQueries.create(data);
  },

  async delete(id) {
    return await notificationQueries.delete(id);
  },

  async getDueAlerts() {
    return await notificationQueries.getDueAlerts();
  },

  async sendToUser(userId, title, message, type = 'info', data = null) {
    return await notificationQueries.create({ user_id: userId, title, message, type, data });
  },

  async sendToAll(title, message, type = 'info', data = null) {
    return await notificationQueries.create({ user_id: null, title, message, type, data });
  },
};