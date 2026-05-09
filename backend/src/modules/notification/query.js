import db from '../../config/db.js';
import { IST_DATE_SQL } from '../../utils/istDateTime.js';

export const notificationQueries = {
  getByUser: async (userId, limit = 50) => {
    const result = await db.query(`
      SELECT * FROM notifications
      WHERE user_id = $1 OR user_id IS NULL
      ORDER BY created_at DESC LIMIT $2
    `, [userId, limit]);
    return result.rows;
  },

  getUnreadCount: async (userId) => {
    const result = await db.query(`
      SELECT COUNT(*) FROM notifications
      WHERE (user_id = $1 OR user_id IS NULL) AND is_read = false
    `, [userId]);
    return parseInt(result.rows[0].count);
  },

  markAsRead: async (id) => {
    const result = await db.query('UPDATE notifications SET is_read = true WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  },

  markAllAsRead: async (userId) => {
    const result = await db.query(`
      UPDATE notifications SET is_read = true
      WHERE (user_id = $1 OR user_id IS NULL) AND is_read = false
    `, [userId]);
    return result.rowCount;
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO notifications (user_id, title, message, type, data)
      VALUES ($1, $2, $3, $4, $5) RETURNING *
    `, [data.user_id, data.title, data.message, data.type || 'info', data.data ? JSON.stringify(data.data) : null]);
    return result.rows[0];
  },

  delete: async (id) => {
    const result = await db.query('DELETE FROM notifications WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  },

  getDueAlerts: async () => {
    const result = await db.query(`
      SELECT 'vehicle' as type, id, registration_number as name, 'Insurance Expiry' as alert
      FROM vehicles WHERE insurance_expiry BETWEEN ${IST_DATE_SQL} AND ${IST_DATE_SQL} + INTERVAL '30 days'
      UNION ALL
      SELECT 'equipment' as type, id, name, 'Maintenance Due' as alert
      FROM equipment WHERE next_maintenance_date <= ${IST_DATE_SQL} + INTERVAL '7 days'
    `);
    return result.rows;
  },
};
