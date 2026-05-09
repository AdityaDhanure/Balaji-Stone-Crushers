import db from '../../config/db.js';
import { IST_DATE_SQL, IST_TIMESTAMP_SQL, addDaysToDateString, todayIst } from '../../utils/istDateTime.js';

export const equipmentQueries = {
  getAll: async () => {
    const result = await db.query(`
      SELECT e.*, 
             COUNT(mr.id) as total_maintenances,
             CAST(COALESCE(SUM(mr.cost), 0) AS DECIMAL(12,2)) as total_spent
      FROM equipment e
      LEFT JOIN maintenance_records mr ON e.id = mr.equipment_id
      GROUP BY e.id
      ORDER BY e.name ASC
    `);
    return result.rows;
  },

  getById: async (id) => {
    const result = await db.query(`
      SELECT * FROM equipment WHERE id = $1
    `, [id]);
    return result.rows[0];
  },

  getActive: async () => {
    const result = await db.query(`
      SELECT * FROM equipment WHERE is_active = true ORDER BY name ASC
    `);
    return result.rows;
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO equipment (name, equipment_type, equipment_phase, code, description, purchase_date, warranty_expiry)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [
      data.name,
      data.equipment_type || 'crusher',
      data.equipment_phase || 'primary',
      data.code,
      data.description,
      data.purchase_date,
      data.warranty_expiry
    ]);
    return result.rows[0];
  },

  update: async (id, data) => {
    const result = await db.query(`
      UPDATE equipment SET
        name = COALESCE($1, name),
        equipment_type = COALESCE($2, equipment_type),
        equipment_phase = COALESCE($3, equipment_phase),
        code = COALESCE($4, code),
        description = COALESCE($5, description),
        purchase_date = COALESCE($6, purchase_date),
        warranty_expiry = COALESCE($7, warranty_expiry),
        is_active = COALESCE($8, is_active)
      WHERE id = $9
      RETURNING *
    `, [
      data.name,
      data.equipment_type,
      data.equipment_phase,
      data.code,
      data.description,
      data.purchase_date,
      data.warranty_expiry,
      data.is_active,
      id
    ]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM equipment WHERE id = $1', [id]);
    return { deleted: true };
  },

  getNextCode: async (type) => {
    const prefix = `${type.toUpperCase().substring(0, 4)}-`;
    const result = await db.query(`
      SELECT COALESCE(MAX(CAST(SUBSTRING(code FROM '${prefix}([0-9]+)$') AS INTEGER)), 0) + 1 as next_number
      FROM equipment
      WHERE code LIKE $1
    `, [`${prefix}%`]);
    return `${prefix}${String(result.rows[0].next_number).padStart(3, '0')}`;
  }
};

export const maintenanceQueries = {
  getAll: async (filters = {}) => {
    let query = `
      SELECT mr.*, 
             e.name as equipment_name,
             e.equipment_type,
             v.vehicle_number,
             v.vehicle_type,
             u.username as created_by_name
      FROM maintenance_records mr
      LEFT JOIN equipment e ON mr.equipment_id = e.id
      LEFT JOIN vehicles v ON mr.vehicle_id = v.id
      LEFT JOIN users u ON mr.created_by = u.id
      WHERE 1=1
    `;
    
    const params = [];
    let paramIndex = 1;

    if (filters.type === 'equipment') {
      query += ` AND mr.equipment_id IS NOT NULL`;
    } else if (filters.type === 'vehicle') {
      query += ` AND mr.vehicle_id IS NOT NULL`;
    }
    if (filters.status) {
      query += ` AND mr.status = $${paramIndex++}`;
      params.push(filters.status);
    }
    if (filters.equipmentId) {
      query += ` AND mr.equipment_id = $${paramIndex++}`;
      params.push(filters.equipmentId);
    }
    if (filters.vehicleId) {
      query += ` AND mr.vehicle_id = $${paramIndex++}`;
      params.push(filters.vehicleId);
    }
    if (filters.startDate) {
      query += ` AND mr.maintenance_date >= $${paramIndex++}`;
      params.push(filters.startDate);
    }
    if (filters.endDate) {
      query += ` AND mr.maintenance_date <= $${paramIndex++}`;
      params.push(filters.endDate);
    }

    query += ' ORDER BY mr.maintenance_date DESC, mr.id DESC';

    const result = await db.query(query, params);
    return result.rows;
  },

  getById: async (id) => {
    const result = await db.query(`
      SELECT mr.*, 
             e.name as equipment_name,
             v.vehicle_number,
             u.username as created_by_name
      FROM maintenance_records mr
      LEFT JOIN equipment e ON mr.equipment_id = e.id
      LEFT JOIN vehicles v ON mr.vehicle_id = v.id
      LEFT JOIN users u ON mr.created_by = u.id
      WHERE mr.id = $1
    `, [id]);
    return result.rows[0];
  },

  getByEquipmentId: async (equipmentId) => {
    const result = await db.query(`
      SELECT * FROM maintenance_records 
      WHERE equipment_id = $1
      ORDER BY maintenance_date DESC
    `, [equipmentId]);
    return result.rows;
  },

  getByVehicleId: async (vehicleId) => {
    const result = await db.query(`
      SELECT * FROM maintenance_records 
      WHERE vehicle_id = $1
      ORDER BY maintenance_date DESC
    `, [vehicleId]);
    return result.rows;
  },

  getDueSoon: async (days = 7) => {
    const result = await db.query(`
      SELECT mr.*, 
             e.name as equipment_name,
             v.vehicle_number
      FROM maintenance_records mr
      LEFT JOIN equipment e ON mr.equipment_id = e.id
      LEFT JOIN vehicles v ON mr.vehicle_id = v.id
      WHERE mr.next_due_date IS NOT NULL 
        AND mr.next_due_date <= ${IST_DATE_SQL} + INTERVAL '${parseInt(days)} days'
        AND mr.status != 'completed'
      ORDER BY mr.next_due_date ASC
    `);
    return result.rows;
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO maintenance_records (
        equipment_id, vehicle_id, maintenance_type, description,
        maintenance_date, next_due_date, cost, vendor_name, vendor_phone,
        parts_replaced, status, created_by
      ) VALUES ($1, $2, $3, $4, COALESCE($5::date, ${IST_DATE_SQL}), $6, $7, $8, $9, $10, $11, $12)
      RETURNING *
    `, [
      data.equipment_id,
      data.vehicle_id,
      data.maintenance_type,
      data.description,
      data.maintenance_date || null,
      data.next_due_date,
      data.cost || 0,
      data.vendor_name,
      data.vendor_phone,
      data.parts_replaced,
      data.status || 'completed',
      data.created_by
    ]);
    return result.rows[0];
  },

  update: async (id, data) => {
    const result = await db.query(`
      UPDATE maintenance_records SET
        maintenance_type = COALESCE($1, maintenance_type),
        description = COALESCE($2, description),
        maintenance_date = COALESCE($3, maintenance_date),
        next_due_date = COALESCE($4, next_due_date),
        cost = COALESCE($5, cost),
        vendor_name = COALESCE($6, vendor_name),
        vendor_phone = COALESCE($7, vendor_phone),
        parts_replaced = COALESCE($8, parts_replaced),
        status = COALESCE($9, status),
        updated_at = ${IST_TIMESTAMP_SQL}
      WHERE id = $10
      RETURNING *
    `, [
      data.maintenance_type,
      data.description,
      data.maintenance_date,
      data.next_due_date,
      data.cost,
      data.vendor_name,
      data.vendor_phone,
      data.parts_replaced,
      data.status,
      id
    ]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM maintenance_records WHERE id = $1', [id]);
    return { deleted: true };
  },

  getStats: async () => {
    const result = await db.query(`
      SELECT 
        COUNT(*) as total_records,
        CAST(SUM(cost) AS DECIMAL(12,2)) as total_cost,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
        COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress_count,
        COUNT(CASE WHEN next_due_date IS NOT NULL AND next_due_date <= ${IST_DATE_SQL} + INTERVAL '7 days' THEN 1 END) as due_soon_count
      FROM maintenance_records
      WHERE maintenance_date >= DATE_TRUNC('month', ${IST_DATE_SQL})
    `);
    return result.rows[0];
  }
};

export const scheduleQueries = {
  getAll: async () => {
    const result = await db.query(`
      SELECT ms.*, e.name as equipment_name
      FROM maintenance_schedule ms
      LEFT JOIN equipment e ON ms.equipment_id = e.id
      ORDER BY ms.next_due ASC NULLS LAST
    `);
    return result.rows;
  },

  getDue: async () => {
    const result = await db.query(`
      SELECT ms.*, e.name as equipment_name
      FROM maintenance_schedule ms
      LEFT JOIN equipment e ON ms.equipment_id = e.id
      WHERE ms.is_active = true AND ms.next_due <= ${IST_DATE_SQL} + INTERVAL '7 days'
      ORDER BY ms.next_due ASC
    `);
    return result.rows;
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO maintenance_schedule (
        equipment_id, schedule_type, description, interval_days, last_performed, next_due
      ) VALUES ($1, $2, $3, $4, COALESCE($5::date, ${IST_DATE_SQL}), $6)
      RETURNING *
    `, [
      data.equipment_id,
      data.schedule_type,
      data.description,
      data.interval_days,
      data.last_performed || null,
      data.next_due
    ]);
    return result.rows[0];
  },

  markComplete: async (id) => {
    const schedule = await db.query('SELECT * FROM maintenance_schedule WHERE id = $1', [id]);
    const nextDue = addDaysToDateString(todayIst(), schedule.rows[0].interval_days);

    const result = await db.query(`
      UPDATE maintenance_schedule SET
        last_performed = ${IST_DATE_SQL},
        next_due = $1
      WHERE id = $2
      RETURNING *
    `, [nextDue, id]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM maintenance_schedule WHERE id = $1', [id]);
    return { deleted: true };
  }
};

export const vendorQueries = {
  getAll: async () => {
    const result = await db.query(`SELECT * FROM maintenance_vendors ORDER BY name ASC`);
    return result.rows;
  },

  getActive: async () => {
    const result = await db.query(`SELECT * FROM maintenance_vendors WHERE is_active = true ORDER BY name ASC`);
    return result.rows;
  },

  getById: async (id) => {
    const result = await db.query(`SELECT * FROM maintenance_vendors WHERE id = $1`, [id]);
    return result.rows[0];
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO maintenance_vendors (name, contact_person, phone, email, address, specialization)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [
      data.name,
      data.contact_person,
      data.phone,
      data.email,
      data.address,
      data.specialization
    ]);
    return result.rows[0];
  },

  update: async (id, data) => {
    const result = await db.query(`
      UPDATE maintenance_vendors SET
        name = COALESCE($1, name),
        contact_person = COALESCE($2, contact_person),
        phone = COALESCE($3, phone),
        email = COALESCE($4, email),
        address = COALESCE($5, address),
        specialization = COALESCE($6, specialization),
        is_active = COALESCE($7, is_active)
      WHERE id = $8
      RETURNING *
    `, [
      data.name,
      data.contact_person,
      data.phone,
      data.email,
      data.address,
      data.specialization,
      data.is_active,
      id
    ]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM maintenance_vendors WHERE id = $1', [id]);
    return { deleted: true };
  }
};

export const partsQueries = {
  getAll: async () => {
    const result = await db.query(`
      SELECT sp.*, 
             COUNT(pu.id) as usage_count,
             CAST(COALESCE(SUM(pu.quantity), 0) AS INTEGER) as total_used
      FROM spare_parts sp
      LEFT JOIN parts_used pu ON sp.id = pu.part_id
      GROUP BY sp.id
      ORDER BY sp.name ASC
    `);
    return result.rows;
  },

  getActive: async () => {
    const result = await db.query(`
      SELECT * FROM spare_parts 
      WHERE is_active = true AND current_stock > 0 
      ORDER BY name ASC
    `);
    return result.rows;
  },

  getById: async (id) => {
    const result = await db.query(`
      SELECT sp.*, 
             COUNT(pu.id) as usage_count,
             CAST(COALESCE(SUM(pu.quantity), 0) AS INTEGER) as total_used
      FROM spare_parts sp
      LEFT JOIN parts_used pu ON sp.id = pu.part_id
      WHERE sp.id = $1
      GROUP BY sp.id
    `, [id]);
    return result.rows[0];
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO spare_parts (
        part_number, name, description, category, unit, min_stock_level, current_stock, rate_per_unit
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `, [
      data.part_number,
      data.name,
      data.description,
      data.category,
      data.unit || 'pcs',
      data.min_stock_level || 0,
      data.current_stock || 0,
      data.rate_per_unit || 0
    ]);
    return result.rows[0];
  },

  update: async (id, data) => {
    const result = await db.query(`
      UPDATE spare_parts SET
        part_number = COALESCE($1, part_number),
        name = COALESCE($2, name),
        description = COALESCE($3, description),
        category = COALESCE($4, category),
        unit = COALESCE($5, unit),
        min_stock_level = COALESCE($6, min_stock_level),
        current_stock = COALESCE($7, current_stock),
        rate_per_unit = COALESCE($8, rate_per_unit),
        is_active = COALESCE($9, is_active)
      WHERE id = $10
      RETURNING *
    `, [
      data.part_number,
      data.name,
      data.description,
      data.category,
      data.unit,
      data.min_stock_level,
      data.current_stock,
      data.rate_per_unit,
      data.is_active,
      id
    ]);
    return result.rows[0];
  },

  delete: async (id) => {
    await db.query('DELETE FROM spare_parts WHERE id = $1', [id]);
    return { deleted: true };
  },

  getNextPartNumber: async () => {
    const result = await db.query(`
      SELECT COALESCE(MAX(CAST(SUBSTRING(part_number FROM '([0-9]+)$') AS INTEGER)), 0) + 1 as next_number
      FROM spare_parts
      WHERE part_number LIKE 'PART-%'
    `);
    return `PART-${String(result.rows[0].next_number).padStart(4, '0')}`;
  },

  getPredefinedParts: async () => {
    const result = await db.query(`
      SELECT * FROM spare_parts WHERE is_predefined = true ORDER BY category, name
    `);
    return result.rows;
  },

  recordUsage: async (data) => {
    const part = await db.query('SELECT rate_per_unit FROM spare_parts WHERE id = $1', [data.part_id]);
    const rate = parseFloat(part.rows[0]?.rate_per_unit || 0);
    const quantity = data.quantity || 1;
    const amount = rate * quantity;
    
    const result = await db.query(`
      INSERT INTO parts_used (maintenance_id, part_id, quantity, rate, amount)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [data.maintenance_id, data.part_id, quantity, rate, amount]);

    await db.query(`
      UPDATE spare_parts SET current_stock = current_stock - $1
      WHERE id = $2
    `, [quantity, data.part_id]);

    return result.rows[0];
  }
};

export const maintenancePartQueries = {
  addRecordParts: async (recordId, parts) => {
    const results = [];
    for (const part of parts) {
      const result = await db.query(`
        INSERT INTO maintenance_record_parts
          (record_id, part_id, part_name, quantity_used)
        VALUES ($1, $2, $3, $4)
        RETURNING *
      `, [recordId, part.part_id, part.part_name, part.quantity_used]);
      results.push(result.rows[0]);
    }
    return results;
  },

  getByRecordId: async (recordId) => {
    const result = await db.query(`
      SELECT mrp.*, sp.name as part_name,
             sp.current_stock, sp.unit
      FROM maintenance_record_parts mrp
      LEFT JOIN spare_parts sp ON mrp.part_id = sp.id
      WHERE mrp.record_id = $1
    `, [recordId]);
    return result.rows;
  },

  deductPartsStock: async (parts) => {
    for (const part of parts) {
      await db.query(`
        UPDATE spare_parts
        SET current_stock = current_stock - $1,
            total_used = COALESCE(total_used, 0) + $1
        WHERE id = $2
      `, [part.quantity_used, part.part_id]);
    }
  },

  restorePartsStock: async (recordId) => {
    const parts = await db.query(`
      SELECT * FROM maintenance_record_parts
      WHERE record_id = $1
    `, [recordId]);

    for (const part of parts.rows) {
      await db.query(`
        UPDATE spare_parts
        SET current_stock = current_stock + $1,
            total_used = GREATEST(COALESCE(total_used, 0) - $1, 0)
        WHERE id = $2
      `, [part.quantity_used, part.part_id]);
    }
  },

  getPartsByRecordId: async (recordId) => {
    const result = await db.query(`
      SELECT * FROM maintenance_record_parts
      WHERE record_id = $1
    `, [recordId]);
    return result.rows;
  }
};
