import db from '../../config/db.js';
import { IST_DATE_SQL, IST_TIMESTAMP_SQL } from '../../utils/istDateTime.js';

export const blastQueries = {
  // Get all blasts with trip counts and expenses
  getAll: async () => {
    const result = await db.query(`
      SELECT b.*, 
             u.username as created_by_name,
             COALESCE(SUM(bt.trips_count), 0) as total_trips,
             b.total_expense as total_expenses
      FROM blasts b
      LEFT JOIN users u ON b.created_by = u.id
      LEFT JOIN blast_trips bt ON b.id = bt.blast_id
      GROUP BY b.id, u.username
      ORDER BY b.blast_date DESC
    `);
    return result.rows;
  },

  // Get single blast by ID
  getById: async (id) => {
    const result = await db.query(`
      SELECT b.*, 
             u.username as created_by_name
      FROM blasts b
      LEFT JOIN users u ON b.created_by = u.id
      WHERE b.id = $1
    `, [id]);
    return result.rows[0];
  },

  // Create new blast
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO blasts (
        blast_number, blast_type, blast_date, feet, rate,
        total_expense, status, notes, created_by
      ) VALUES ($1, $2, COALESCE($3::date, ${IST_DATE_SQL}), $4, $5, $6, $7, $8, $9)
      RETURNING *
    `, [
      data.blast_number,
      data.blast_type,
      data.blast_date || null,
      data.feet || 0,
      data.rate || 190,
      data.total_expense || 0,
      data.status || 'active',
      data.notes,
      data.created_by
    ]);
    return result.rows[0];
  },

  // Update blast (partial update using COALESCE)
  update: async (id, data) => {
    const result = await db.query(`
      UPDATE blasts SET
        blast_type = COALESCE($1, blast_type),
        blast_date = COALESCE($2, blast_date),
        feet = COALESCE($3, feet),
        rate = COALESCE($4, rate),
        total_expense = COALESCE($5, total_expense),
        status = COALESCE($6, status),
        notes = COALESCE($7, notes),
        updated_at = ${IST_TIMESTAMP_SQL}
      WHERE id = $8
      RETURNING *
    `, [
      data.blast_type,
      data.blast_date,
      data.feet,
      data.rate,
      data.total_expense,
      data.status,
      data.notes,
      id
    ]);
    return result.rows[0];
  },

  // Delete blast
  delete: async (id) => {
    await db.query('DELETE FROM blasts WHERE id = $1', [id]);
    return { deleted: true };
  },

  // Get next blast number for current month
  getNextBlastNumber: async () => {
    const result = await db.query(`
      SELECT COALESCE(MAX(blast_number), 0) + 1 as next_number
      FROM blasts
    `);
    return result.rows[0].next_number;
  },

  // Get currently active blast
  getActiveBlast: async () => {
    const result = await db.query(`
      SELECT b.*, 
             COALESCE(SUM(bt.trips_count), 0) as total_trips,
             b.total_expense as total_expenses
      FROM blasts b
      LEFT JOIN blast_trips bt ON b.id = bt.blast_id
      WHERE b.status = 'active'
      GROUP BY b.id
      ORDER BY b.blast_date DESC
      LIMIT 1
    `);
    return result.rows[0];
  }
};

// Trip queries for tracking vehicle trips to blasts
export const tripQueries = {
  // Get all trips for a blast grouped by vehicle
  getByBlastId: async (blastId) => {
    const result = await db.query(`
      SELECT 
        vehicle_id, vehicle_number, vehicle_type,
        SUM(trips_count) as trips_count,
        MIN(trip_date) as first_trip_date,
        MAX(trip_date) as last_trip_date,
        COUNT(*) as entries_count,
        json_agg(id ORDER BY trip_date DESC) as trip_ids
      FROM blast_trips 
      WHERE blast_id = $1 
      GROUP BY vehicle_id, vehicle_number, vehicle_type
      ORDER BY last_trip_date DESC
    `, [blastId]);
    return result.rows;
  },

  // Get trips grouped by date for a blast
  getByBlastIdGroupedByDate: async (blastId) => {
    const result = await db.query(`
      SELECT 
        trip_date,
        SUM(trips_count) as total_trips,
        COUNT(*) as entries_count,
        json_agg(
          json_build_object(
            'id', id,
            'vehicle_id', vehicle_id,
            'vehicle_number', vehicle_number,
            'vehicle_type', vehicle_type,
            'trips_count', trips_count,
            'material_type', material_type
          ) ORDER BY created_at DESC
        ) as trips
      FROM blast_trips 
      WHERE blast_id = $1 
      GROUP BY trip_date
      ORDER BY trip_date DESC
    `, [blastId]);
    return result.rows;
  },

  // Get distinct trip dates for a blast
  getDistinctDatesByBlastId: async (blastId) => {
    const result = await db.query(`
      SELECT DISTINCT trip_date::text as trip_date
      FROM blast_trips 
      WHERE blast_id = $1 
      ORDER BY trip_date DESC
    `, [blastId]);
    return result.rows;
  },

  // Create new trip record
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO blast_trips (
        blast_id, vehicle_id, vehicle_number, vehicle_type,
        trip_date, trips_count, material_type, created_by
      ) VALUES ($1, $2, $3, $4, COALESCE($5::date, ${IST_DATE_SQL}), $6, $7, $8)
      RETURNING *
    `, [
      data.blast_id,
      data.vehicle_id,
      data.vehicle_number,
      data.vehicle_type,
      data.trip_date || null,
      data.trips_count || 1,
      data.material_type || 'raw_rock',
      data.created_by
    ]);
    return result.rows[0];
  },

  // Delete trip and update blast totals
  delete: async (id) => {
    const trip = await db.query('SELECT blast_id FROM blast_trips WHERE id = $1', [id]);
    await db.query('DELETE FROM blast_trips WHERE id = $1', [id]);
    if (trip.rows[0]) {
      const sum = await db.query('SELECT COALESCE(SUM(trips_count), 0) as total FROM blast_trips WHERE blast_id = $1', [trip.rows[0].blast_id]);
      await db.query('UPDATE blasts SET total_trips = $1 WHERE id = $2', [parseInt(sum.rows[0].total), trip.rows[0].blast_id]);
    }
    return { deleted: true };
  },

  // Update total_trips count on blast after trip changes
  updateBlastTripTotals: async (blastId) => {
    const result = await db.query('SELECT COALESCE(SUM(trips_count), 0) as total FROM blast_trips WHERE blast_id = $1', [blastId]);
    await db.query('UPDATE blasts SET total_trips = $1 WHERE id = $2', [parseInt(result.rows[0].total), blastId]);
    return result.rows[0];
  },

  // Get vehicles by type for dropdown
  getVehiclesByType: async (vehicleType) => {
    const result = await db.query('SELECT id, vehicle_number FROM vehicles WHERE vehicle_type = $1 AND status = $2 ORDER BY vehicle_number', [vehicleType, 'active']);
    return result.rows;
  },

  // Get all distinct vehicle types
  getVehicleTypes: async () => {
    const result = await db.query('SELECT DISTINCT vehicle_type FROM vehicles WHERE status = $1 ORDER BY vehicle_type', ['active']);
    return result.rows;
  },

  // Get all trips for a specific date
  getDailyTrips: async (date) => {
    const result = await db.query(`
      SELECT bt.*, b.blast_number
      FROM blast_trips bt
      JOIN blasts b ON bt.blast_id = b.id
      WHERE bt.trip_date = $1
      ORDER BY bt.created_at DESC
    `, [date]);
    return result.rows;
  },

  // Update trip record
  update: async (id, data) => {
    const result = await db.query(`
      UPDATE blast_trips SET
        vehicle_id = COALESCE($1, vehicle_id),
        vehicle_number = COALESCE($2, vehicle_number),
        vehicle_type = COALESCE($3, vehicle_type),
        trips_count = COALESCE($4, trips_count),
        trip_date = COALESCE($5, trip_date),
        material_type = COALESCE($6, material_type)
      WHERE id = $7
      RETURNING *
    `, [data.vehicle_id, data.vehicle_number, data.vehicle_type, data.trips_count, data.trip_date, data.material_type, id]);
    return result.rows[0];
  }
};

// Expense queries for blast-related expenses (drilling, royalty, etc.)
export const expenseQueries = {
  // Get all expenses for a blast
  getByBlastId: async (blastId) => {
    const result = await db.query(`
      SELECT * FROM blast_expenses 
      WHERE blast_id = $1 
      ORDER BY expense_date DESC
    `, [blastId]);
    return result.rows;
  },

  // Get expenses grouped by date
  getByBlastIdGroupedByDate: async (blastId) => {
    const result = await db.query(`
      SELECT 
        expense_date,
        SUM(amount) as total_amount,
        COUNT(*) as entries_count,
        json_agg(
          json_build_object(
            'id', id,
            'expense_type', expense_type,
            'description', description,
            'amount', amount
          ) ORDER BY created_at DESC
        ) as expenses
      FROM blast_expenses 
      WHERE blast_id = $1 
      GROUP BY expense_date
      ORDER BY expense_date DESC
    `, [blastId]);
    return result.rows;
  },

  // Get distinct expense dates
  getDistinctDatesByBlastId: async (blastId) => {
    const result = await db.query(`
      SELECT DISTINCT expense_date::text as expense_date
      FROM blast_expenses 
      WHERE blast_id = $1 
      ORDER BY expense_date DESC
    `, [blastId]);
    return result.rows;
  },

  // Get single expense by ID
  getById: async (id) => {
    const result = await db.query('SELECT * FROM blast_expenses WHERE id = $1', [id]);
    return result.rows[0];
  },

  // Create expense (drilling, royalty, etc.)
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO blast_expenses (
        blast_id, expense_type, description, amount, expense_date, created_by
      ) VALUES ($1, $2, $3, $4, COALESCE($5::date, ${IST_DATE_SQL}), $6)
      RETURNING *
    `, [
      data.blast_id,
      data.expense_type,
      data.description,
      data.amount,
      data.expense_date || null,
      data.created_by
    ]);
    return result.rows[0];
  },

  // Update expense
  update: async (id, data) => {
    const result = await db.query(`
      UPDATE blast_expenses SET
        expense_type = COALESCE($1, expense_type),
        description = COALESCE($2, description),
        amount = COALESCE($3, amount),
        expense_date = COALESCE($4, expense_date)
      WHERE id = $5
      RETURNING *
    `, [data.expense_type, data.description, data.amount, data.expense_date, id]);
    return result.rows[0];
  },

  // Delete expense
  delete: async (id) => {
    const expense = await db.query('SELECT blast_id FROM blast_expenses WHERE id = $1', [id]);
    await db.query('DELETE FROM blast_expenses WHERE id = $1', [id]);
    return expense.rows[0];
  },

  // Update total_expense on blast after expense changes
  updateBlastExpenseTotals: async (blastId) => {
    const result = await db.query('SELECT COALESCE(SUM(amount), 0) as total FROM blast_expenses WHERE blast_id = $1', [blastId]);
    await db.query('UPDATE blasts SET total_expense = $1 WHERE id = $2', [parseFloat(result.rows[0].total), blastId]);
    return result.rows[0];
  }
};
