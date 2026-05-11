import db from '../../config/db.js';
import { IST_DATE_SQL, IST_TIMESTAMP_SQL } from '../../utils/istDateTime.js';

const dieselDate = (col) => `(${col})::date`;
const istDate = IST_DATE_SQL;
const istTimestamp = IST_TIMESTAMP_SQL;

export const dieselQueries = {
  // Get all diesel purchases
  getAllPurchases: async () => {
    const result = await db.query(`
      SELECT 
        id, pump_name, 
        CAST(quantity AS DECIMAL(10,2)) as quantity,
        CAST(rate_per_liter AS DECIMAL(8,2)) as rate_per_liter,
        CAST(total_amount AS DECIMAL(12,2)) as total_amount,
        payment_status, purchase_date, remarks,
        created_by, created_at
      FROM diesel_purchases
      ORDER BY purchase_date DESC
    `);
    return result.rows;
  },

  // Get single purchase by ID
  getPurchaseById: async (id) => {
    const result = await db.query(`
      SELECT 
        id, pump_name, 
        CAST(quantity AS DECIMAL(10,2)) as quantity,
        CAST(rate_per_liter AS DECIMAL(8,2)) as rate_per_liter,
        CAST(total_amount AS DECIMAL(12,2)) as total_amount,
        payment_status, purchase_date, remarks,
        created_by, created_at
      FROM diesel_purchases
      WHERE id = $1
    `, [id]);
    return result.rows[0];
  },

  // Create new diesel purchase
  createPurchase: async (data) => {
    const result = await db.query(`
      INSERT INTO diesel_purchases (
        pump_name, quantity, rate_per_liter, total_amount,
        payment_status, purchase_date, remarks, created_by, created_at
      ) VALUES ($1, $2, $3, $4, $5, COALESCE($6::date, ${istDate}), $7, $8, ${istTimestamp})
      RETURNING id, pump_name, quantity, rate_per_liter, total_amount,
                payment_status, purchase_date, remarks, created_by, created_at
    `, [
      data.pump_name,
      Number(data.quantity),
      Number(data.rate_per_liter),
      Number(data.total_amount),
      data.payment_status || 'pending',
      data.purchase_date || null,
      data.remarks,
      data.created_by
    ]);
    return result.rows[0];
  },

  // Update purchase
  updatePurchase: async (id, data) => {
    const result = await db.query(`
      UPDATE diesel_purchases SET
        pump_name = COALESCE($1, pump_name),
        quantity = COALESCE($2, quantity),
        rate_per_liter = COALESCE($3, rate_per_liter),
        total_amount = COALESCE($4, total_amount),
        payment_status = COALESCE($5, payment_status),
        purchase_date = COALESCE($6::date, purchase_date),
        remarks = COALESCE($7, remarks)
      WHERE id = $8
      RETURNING id, pump_name, quantity, rate_per_liter, total_amount,
                payment_status, purchase_date, remarks, created_by, created_at
    `, [
      data.pump_name,
      data.quantity ? Number(data.quantity) : null,
      data.rate_per_liter ? Number(data.rate_per_liter) : null,
      data.total_amount ? Number(data.total_amount) : null,
      data.payment_status,
      data.purchase_date,
      data.remarks,
      id
    ]);
    return result.rows[0];
  },

  // Delete purchase
  deletePurchase: async (id) => {
    await db.query('DELETE FROM diesel_purchases WHERE id = $1', [id]);
    return { deleted: true };
  },

  // Get stock overview (total purchased, consumed, current stock, payments)
  getStockOverview: async () => {
    const result = await db.query(`
      SELECT 
        (SELECT COALESCE(CAST(SUM(quantity) AS DECIMAL(12,2)), 0) FROM diesel_purchases) as total_purchased,
        (SELECT COALESCE(CAST(SUM(quantity) AS DECIMAL(12,2)), 0) FROM diesel_consumption) as total_consumed,
        (SELECT COALESCE(CAST(SUM(total_amount) AS DECIMAL(12,2)), 0) FROM diesel_purchases WHERE payment_status = 'pending') as pending_payments,
        (SELECT COALESCE(CAST(SUM(total_amount) AS DECIMAL(12,2)), 0) FROM diesel_purchases WHERE payment_status = 'paid') as total_paid
    `);
    const row = result.rows[0];
    return {
      total_purchased: Number(row.total_purchased ?? 0) || 0,
      total_consumed: Number(row.total_consumed ?? 0) || 0,
      current_stock: (Number(row.total_purchased ?? 0) || 0) - (Number(row.total_consumed ?? 0) || 0),
      pending_payments: Number(row.pending_payments ?? 0) || 0,
      total_paid: Number(row.total_paid ?? 0) || 0
    };
  }
};

export const consumptionQueries = {
  // Get all diesel consumption records
  getAll: async () => {
    const result = await db.query(`
      SELECT 
        dc.id, dc.vehicle_id, 
        CAST(dc.quantity AS DECIMAL(10,2)) as quantity,
        dc.consumption_date, dc.purpose, dc.remarks,
        dc.created_by, dc.created_at,
        v.vehicle_number, v.vehicle_type
      FROM diesel_consumption dc
      LEFT JOIN vehicles v ON dc.vehicle_id = v.id
      ORDER BY dc.consumption_date DESC
    `);
    return result.rows;
  },

  // Get consumption for specific vehicle
  getByVehicleId: async (vehicleId) => {
    const result = await db.query(`
      SELECT 
        dc.id, dc.vehicle_id, 
        CAST(dc.quantity AS DECIMAL(10,2)) as quantity,
        dc.consumption_date, dc.purpose, dc.remarks,
        dc.created_by, dc.created_at,
        v.vehicle_number, v.vehicle_type
      FROM diesel_consumption dc
      LEFT JOIN vehicles v ON dc.vehicle_id = v.id
      WHERE dc.vehicle_id = $1
      ORDER BY dc.consumption_date DESC
    `, [vehicleId]);
    return result.rows;
  },

  // Get consumption within date range
  getByDateRange: async (startDate, endDate) => {
    const result = await db.query(`
      SELECT 
        dc.id, dc.vehicle_id, 
        CAST(dc.quantity AS DECIMAL(10,2)) as quantity,
        dc.consumption_date, dc.purpose, dc.remarks,
        dc.created_by, dc.created_at,
        v.vehicle_number, v.vehicle_type
      FROM diesel_consumption dc
      LEFT JOIN vehicles v ON dc.vehicle_id = v.id
      WHERE ${dieselDate('dc.consumption_date')} >= $1::date
        AND ${dieselDate('dc.consumption_date')} <= $2::date
      ORDER BY dc.consumption_date DESC
    `, [startDate, endDate]);
    return result.rows;
  },

  // Create consumption record
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO diesel_consumption (
        vehicle_id, quantity, consumption_date, purpose, remarks, created_by, created_at
      ) VALUES ($1, $2, COALESCE($3::date, ${istDate}), $4, $5, $6, ${istTimestamp})
      RETURNING id, vehicle_id, quantity, consumption_date, purpose, remarks, created_by, created_at
    `, [
      data.vehicle_id,
      Number(data.quantity),
      data.consumption_date || null,
      data.purpose,
      data.remarks,
      data.created_by
    ]);
    return result.rows[0];
  },

  // Delete consumption record
  delete: async (id) => {
    await db.query('DELETE FROM diesel_consumption WHERE id = $1', [id]);
    return { deleted: true };
  },

  // Update consumption record
  update: async (id, data) => {
    const result = await db.query(`
      UPDATE diesel_consumption SET
        vehicle_id = COALESCE($1, vehicle_id),
        quantity = COALESCE($2, quantity),
        consumption_date = COALESCE($3::date, consumption_date),
        purpose = COALESCE($4, purpose),
        remarks = COALESCE($5, remarks)
      WHERE id = $6
      RETURNING id, vehicle_id, quantity, consumption_date, purpose, remarks, created_by, created_at
    `, [
      data.vehicle_id,
      data.quantity ? Number(data.quantity) : null,
      data.consumption_date,
      data.purpose,
      data.remarks,
      id
    ]);
    return result.rows[0];
  },

  // Get consumption grouped by date
  getGroupedByDate: async () => {
    const result = await db.query(`
      SELECT 
        ${dieselDate('dc.consumption_date')} AS consumption_date,
        CAST(COALESCE(SUM(dc.quantity), 0) AS DECIMAL(12,2)) as total_quantity,
        COUNT(dc.id) as entries_count,
        json_agg(
          json_build_object(
            'id', dc.id,
            'vehicle_id', dc.vehicle_id,
            'vehicle_number', v.vehicle_number,
            'vehicle_type', v.vehicle_type,
            'quantity', dc.quantity,
            'purpose', dc.purpose,
            'remarks', dc.remarks,
            'consumption_date', dc.consumption_date
          ) ORDER BY dc.created_at DESC
        ) as entries
      FROM diesel_consumption dc
      LEFT JOIN vehicles v ON dc.vehicle_id = v.id
      GROUP BY ${dieselDate('dc.consumption_date')}
      ORDER BY ${dieselDate('dc.consumption_date')} DESC
    `);
    return result.rows;
  },

  // Get vehicle-wise consumption in date range
  getVehicleWiseConsumption: async (startDate, endDate) => {
    const result = await db.query(`
      SELECT 
        v.id as vehicle_id, v.vehicle_number, v.vehicle_type,
        CAST(COALESCE(SUM(dc.quantity), 0) AS DECIMAL(12,2)) as total_consumed,
        COUNT(dc.id) as refills
      FROM vehicles v
      LEFT JOIN diesel_consumption dc ON v.id = dc.vehicle_id
        AND ${dieselDate('dc.consumption_date')} >= $1::date
        AND ${dieselDate('dc.consumption_date')} <= $2::date
      GROUP BY v.id, v.vehicle_number, v.vehicle_type
      ORDER BY total_consumed DESC
    `, [startDate, endDate]);
    return result.rows;
  },

  // Get pump-wise payment summary
  getPumpWisePayments: async () => {
    const result = await db.query(`
      SELECT 
        pump_name,
        COUNT(id) as purchases,
        CAST(COALESCE(SUM(quantity), 0) AS DECIMAL(12,2)) as total_quantity,
        CAST(COALESCE(SUM(total_amount), 0) AS DECIMAL(12,2)) as total_amount,
        CAST(COALESCE(SUM(CASE WHEN payment_status = 'pending' THEN total_amount ELSE 0 END), 0) AS DECIMAL(12,2)) as pending_amount
      FROM diesel_purchases
      GROUP BY pump_name
      ORDER BY total_amount DESC
    `);
    return result.rows;
  }
};
