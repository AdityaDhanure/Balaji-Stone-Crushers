import db from '../../config/db.js';
import { IST_DATE_SQL, IST_TIMESTAMP_SQL } from '../../utils/istDateTime.js';

export const vehicleQueries = {
  getAll: async () => {
    const result = await db.query(`
      SELECT 
        v.id, v.vehicle_number, v.vehicle_type, v.owner_name,
        v.insurance_expiry, v.puc_expiry, v.passing_expiry, v.road_tax_expiry,
        CAST(v.rto_emi_amount AS DECIMAL(10,2)) as rto_emi_amount,
        v.rto_emi_due_date,
        CAST(v.odometer_reading AS DECIMAL(12,2)) as odometer_reading,
        v.status, v.notes, v.created_by, v.created_at, v.updated_at,
        u.username as created_by_name,
        COALESCE((
          SELECT SUM(bt.trips_count) FROM blast_trips bt WHERE bt.vehicle_id = v.id
        ), 0) + COALESCE((
          SELECT SUM(vdu.trips_count) FROM vehicle_daily_usage vdu WHERE vdu.vehicle_id = v.id
        ), 0) as total_trips,
        COALESCE((
          SELECT SUM(vdu.distance) FROM vehicle_daily_usage vdu WHERE vdu.vehicle_id = v.id
        ), 0) as total_distance
      FROM vehicles v
      LEFT JOIN users u ON v.created_by = u.id
      GROUP BY v.id, u.username
      ORDER BY v.created_at DESC
    `);
    return result.rows;
  },

  getById: async (id) => {
    const result = await db.query(`
      SELECT 
        v.id, v.vehicle_number, v.vehicle_type, v.owner_name,
        v.insurance_expiry, v.puc_expiry, v.passing_expiry, v.road_tax_expiry,
        CAST(v.rto_emi_amount AS DECIMAL(10,2)) as rto_emi_amount,
        v.rto_emi_due_date,
        CAST(v.odometer_reading AS DECIMAL(12,2)) as odometer_reading,
        v.status, v.notes, v.created_by, v.created_at, v.updated_at,
        u.username as created_by_name
      FROM vehicles v
      LEFT JOIN users u ON v.created_by = u.id
      WHERE v.id = $1
    `, [id]);
    return result.rows[0];
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO vehicles (
        vehicle_number, vehicle_type, owner_name, insurance_expiry,
        puc_expiry, passing_expiry, road_tax_expiry, rto_emi_amount,
        rto_emi_due_date, odometer_reading, status, notes, created_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING id, vehicle_number, vehicle_type, owner_name, insurance_expiry,
        puc_expiry, passing_expiry, road_tax_expiry, rto_emi_amount,
        rto_emi_due_date, odometer_reading, status, notes, created_by, created_at
    `, [
      data.vehicle_number,
      data.vehicle_type,
      data.owner_name,
      data.insurance_expiry,
      data.puc_expiry,
      data.passing_expiry,
      data.road_tax_expiry,
      Number(data.rto_emi_amount) || 0,
      data.rto_emi_due_date,
      Number(data.odometer_reading) || 0,
      data.status || 'active',
      data.notes,
      data.created_by
    ]);
    return result.rows[0];
  },

  update: async (id, data) => {
    const result = await db.query(`
      UPDATE vehicles SET
        vehicle_number = COALESCE($1, vehicle_number),
        vehicle_type = COALESCE($2, vehicle_type),
        owner_name = COALESCE($3, owner_name),
        insurance_expiry = COALESCE($4, insurance_expiry),
        puc_expiry = COALESCE($5, puc_expiry),
        passing_expiry = COALESCE($6, passing_expiry),
        road_tax_expiry = COALESCE($7, road_tax_expiry),
        rto_emi_amount = COALESCE($8, rto_emi_amount),
        rto_emi_due_date = COALESCE($9, rto_emi_due_date),
        odometer_reading = COALESCE($10, odometer_reading),
        status = COALESCE($11, status),
        notes = COALESCE($12, notes),
        updated_at = ${IST_TIMESTAMP_SQL}
      WHERE id = $13
      RETURNING id, vehicle_number, vehicle_type, owner_name, insurance_expiry,
        puc_expiry, passing_expiry, road_tax_expiry, rto_emi_amount,
        rto_emi_due_date, odometer_reading, status, notes, created_by, created_at, updated_at
    `, [
      data.vehicle_number,
      data.vehicle_type,
      data.owner_name,
      data.insurance_expiry,
      data.puc_expiry,
      data.passing_expiry,
      data.road_tax_expiry,
      data.rto_emi_amount ? Number(data.rto_emi_amount) : null,
      data.rto_emi_due_date,
      data.odometer_reading ? Number(data.odometer_reading) : null,
      data.status,
      data.notes,
      id
    ]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM vehicles WHERE id = $1', [id]);
    return { deleted: true };
  },

  getByType: async (type) => {
    const result = await db.query(`
      SELECT id, vehicle_number, vehicle_type, status FROM vehicles 
      WHERE vehicle_type = $1 AND status = 'active' 
      ORDER BY vehicle_number
    `, [type]);
    return result.rows;
  },

  updateOdometer: async (id, reading) => {
    const result = await db.query(`
      UPDATE vehicles SET odometer_reading = $1, updated_at = ${IST_TIMESTAMP_SQL}
      WHERE id = $2 
      RETURNING id, vehicle_number, vehicle_type, owner_name, insurance_expiry,
        puc_expiry, passing_expiry, road_tax_expiry, rto_emi_amount,
        rto_emi_due_date, odometer_reading, status, notes, created_by, created_at
    `, [Number(reading), id]);
    return result.rows[0];
  }
};

export const usageQueries = {
  getByVehicleId: async (vehicleId) => {
    const result = await db.query(`
      SELECT 
        id, vehicle_id, usage_date, purpose, location,
        CAST(trips_count AS INTEGER) as trips_count,
        CAST(distance AS DECIMAL(10,2)) as distance,
        CAST(diesel_consumed AS DECIMAL(8,2)) as diesel_consumed,
        remarks, created_by, created_at
      FROM vehicle_daily_usage 
      WHERE vehicle_id = $1 
      ORDER BY usage_date DESC
    `, [vehicleId]);
    return result.rows;
  },

  getByVehicleIdGroupedByDate: async (vehicleId) => {
    const result = await db.query(`
      SELECT 
        usage_date,
        SUM(trips_count) as total_trips,
        SUM(distance) as total_distance,
        SUM(diesel_consumed) as total_diesel,
        COUNT(*) as entries_count,
        json_agg(
          json_build_object(
            'id', id,
            'purpose', purpose,
            'location', location,
            'trips_count', trips_count,
            'distance', distance,
            'diesel_consumed', diesel_consumed,
            'remarks', remarks
          ) ORDER BY created_at DESC
        ) as usage_records
      FROM vehicle_daily_usage 
      WHERE vehicle_id = $1 
      GROUP BY usage_date
      ORDER BY usage_date DESC
    `, [vehicleId]);
    return result.rows;
  },

  getDistinctDatesByVehicleId: async (vehicleId) => {
    const result = await db.query(`
      SELECT DISTINCT usage_date::text as usage_date
      FROM vehicle_daily_usage 
      WHERE vehicle_id = $1 
      ORDER BY usage_date DESC
    `, [vehicleId]);
    return result.rows;
  },

  getDailyUsage: async (date) => {
    const result = await db.query(`
      SELECT 
        vdu.id, vdu.vehicle_id, vdu.usage_date, vdu.purpose, vdu.location,
        CAST(vdu.trips_count AS INTEGER) as trips_count,
        CAST(vdu.distance AS DECIMAL(10,2)) as distance,
        CAST(vdu.diesel_consumed AS DECIMAL(8,2)) as diesel_consumed,
        vdu.remarks, vdu.created_by, vdu.created_at,
        v.vehicle_number, v.vehicle_type
      FROM vehicle_daily_usage vdu
      JOIN vehicles v ON vdu.vehicle_id = v.id
      WHERE vdu.usage_date = $1
      ORDER BY vdu.created_at DESC
    `, [date]);
    return result.rows;
  },

  getByDateRange: async (vehicleId, startDate, endDate) => {
    const result = await db.query(`
      SELECT 
        id, vehicle_id, usage_date, purpose, location,
        CAST(trips_count AS INTEGER) as trips_count,
        CAST(distance AS DECIMAL(10,2)) as distance,
        CAST(diesel_consumed AS DECIMAL(8,2)) as diesel_consumed,
        remarks, created_by, created_at
      FROM vehicle_daily_usage 
      WHERE vehicle_id = $1 AND usage_date BETWEEN $2 AND $3
      ORDER BY usage_date DESC
    `, [vehicleId, startDate, endDate]);
    return result.rows;
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO vehicle_daily_usage (
        vehicle_id, usage_date, purpose, location, trips_count,
        distance, diesel_consumed, remarks, created_by
      ) VALUES ($1, COALESCE($2::date, ${IST_DATE_SQL}), $3, $4, $5, $6, $7, $8, $9)
      RETURNING id, vehicle_id, usage_date, purpose, location,
        trips_count, distance, diesel_consumed, remarks, created_by, created_at
    `, [
      data.vehicle_id,
      data.usage_date || null,
      data.purpose,
      data.location,
      Number(data.trips_count) || 0,
      Number(data.distance) || 0,
      Number(data.diesel_consumed) || 0,
      data.remarks,
      data.created_by
    ]);
    return result.rows[0];
  },

  update: async (id, data) => {
    const result = await db.query(`
      UPDATE vehicle_daily_usage SET
        purpose = COALESCE($1, purpose),
        location = COALESCE($2, location),
        trips_count = COALESCE($3, trips_count),
        distance = COALESCE($4, distance),
        diesel_consumed = COALESCE($5, diesel_consumed),
        usage_date = COALESCE($6, usage_date),
        remarks = COALESCE($7, remarks)
      WHERE id = $8
      RETURNING id, vehicle_id, usage_date, purpose, location,
        trips_count, distance, diesel_consumed, remarks, created_by, created_at
    `, [
      data.purpose,
      data.location,
      data.trips_count,
      data.distance,
      data.diesel_consumed,
      data.usage_date,
      data.remarks,
      id
    ]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM vehicle_daily_usage WHERE id = $1', [id]);
    return { deleted: true };
  },

  getVehicleStats: async (vehicleId) => {
    const result = await db.query(`
      WITH usage_stats AS (
        SELECT 
          COALESCE(SUM(trips_count), 0) as usage_trips,
          COALESCE(SUM(distance), 0) as usage_distance,
          COALESCE(SUM(diesel_consumed), 0) as usage_diesel,
          COUNT(*) as usage_days
        FROM vehicle_daily_usage
        WHERE vehicle_id = $1
      ),
      blast_stats AS (
        SELECT COALESCE(SUM(trips_count), 0) as blast_trips
        FROM blast_trips
        WHERE vehicle_id = $1
      ),
      diesel_stats AS (
        SELECT COALESCE(SUM(quantity), 0) as diesel_consumed
        FROM diesel_consumption
        WHERE vehicle_id = $1
      )
      SELECT 
        (SELECT usage_trips + blast_trips FROM usage_stats, blast_stats) as total_trips,
        (SELECT usage_distance FROM usage_stats) as total_distance,
        (SELECT usage_diesel + diesel_consumed FROM usage_stats, diesel_stats) as total_diesel,
        (SELECT usage_days FROM usage_stats) as usage_days
    `, [vehicleId]);
    const row = result.rows[0];
    return {
      total_trips: Number(row.total_trips) || 0,
      total_distance: Number(row.total_distance) || 0,
      total_diesel: Number(row.total_diesel) || 0,
      usage_days: Number(row.usage_days) || 0
    };
  }
};
