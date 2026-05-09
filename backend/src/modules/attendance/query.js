import db from '../../config/db.js';

const attendanceDate = (col) => `(${col})::date`;
const istTimestamp = "CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'";

export const attendanceQueries = {
  // Get all attendance records with optional filters
  getAll: async (filters = {}) => {
    let query = `
      SELECT a.*, 
             e.first_name, e.last_name, e.employee_code,
             d.name as department_name,
             st.name as shift_name
      FROM attendance a
      JOIN employees e ON a.employee_id = e.id
      LEFT JOIN departments d ON e.department_id = d.id
      LEFT JOIN employee_shifts es ON e.id = es.employee_id AND ${attendanceDate('a.date')} >= ${attendanceDate('es.effective_from')} AND (es.effective_to IS NULL OR ${attendanceDate('a.date')} <= ${attendanceDate('es.effective_to')})
      LEFT JOIN shift_types st ON es.shift_type_id = st.id
      WHERE 1=1
    `;
    
    const params = [];
    let paramIndex = 1;

    if (filters.employeeId) {
      query += ` AND a.employee_id = $${paramIndex++}`;
      params.push(filters.employeeId);
    }
    if (filters.departmentId) {
      query += ` AND e.department_id = $${paramIndex++}`;
      params.push(filters.departmentId);
    }
    if (filters.date) {
      query += ` AND ${attendanceDate('a.date')} = $${paramIndex++}::date`;
      params.push(filters.date);
    }
    if (filters.startDate) {
      query += ` AND ${attendanceDate('a.date')} >= $${paramIndex++}::date`;
      params.push(filters.startDate);
    }
    if (filters.endDate) {
      query += ` AND ${attendanceDate('a.date')} <= $${paramIndex++}::date`;
      params.push(filters.endDate);
    }
    if (filters.status) {
      query += ` AND a.status = $${paramIndex++}`;
      params.push(filters.status);
    }

    query += ' ORDER BY a.date DESC, e.first_name ASC';

    if (filters.limit) {
      query += ` LIMIT $${paramIndex++}`;
      params.push(filters.limit);
    }

    const result = await db.query(query, params);
    return result.rows;
  },

  // Delete all attendance records for a specific date
  deleteAllByDate: async (date) => {
    const result = await db.query(
      `DELETE FROM attendance WHERE ${attendanceDate('date')} = $1::date RETURNING id`,
      [date]
    );
    return { deleted: result.rowCount, date };
  },

  // Get attendance records for specific employee within date range
  getByEmployee: async (employeeId, startDate, endDate) => {
    const result = await db.query(`
      SELECT * FROM attendance 
      WHERE employee_id = $1 AND ${attendanceDate('date')} >= $2::date AND ${attendanceDate('date')} <= $3::date
      ORDER BY date DESC
    `, [employeeId, startDate, endDate]);
    return result.rows;
  },

  // Get all attendance records for a specific date
  getByDate: async (date) => {
    const result = await db.query(`
      SELECT a.*, 
             e.first_name, e.last_name, e.employee_code,
             d.name as department_name
      FROM attendance a
      JOIN employees e ON a.employee_id = e.id
      LEFT JOIN departments d ON e.department_id = d.id
      WHERE ${attendanceDate('a.date')} = $1::date
      ORDER BY e.first_name ASC
    `, [date]);
    return result.rows;
  },

  // Create new attendance record (upsert - insert or update on conflict)
  create: async (data) => {
    // Check existing record to track leave balance changes
    const existing = await db.query(
      `SELECT status FROM attendance WHERE employee_id = $1 AND ${attendanceDate('date')} = $2::date`,
      [data.employee_id, data.date]
    );
    const oldStatus = existing.rows.length > 0 ? existing.rows[0].status : null;
    
    // Insert with ON CONFLICT to handle duplicate entries
    const result = await db.query(`
      INSERT INTO attendance (
        employee_id, date, check_in, check_out, status,
        overtime_hours, late_hours, notes, created_by, created_at, updated_at
      ) VALUES ($1, $2::date, $3, $4, $5, $6, $7, $8, $9, ${istTimestamp}, ${istTimestamp})
      ON CONFLICT (employee_id, date) DO UPDATE SET
        check_in = COALESCE(EXCLUDED.check_in, attendance.check_in),
        check_out = COALESCE(EXCLUDED.check_out, attendance.check_out),
        status = COALESCE(EXCLUDED.status, attendance.status),
        overtime_hours = COALESCE(EXCLUDED.overtime_hours, attendance.overtime_hours),
        late_hours = COALESCE(EXCLUDED.late_hours, attendance.late_hours),
        notes = COALESCE(EXCLUDED.notes, attendance.notes),
        updated_at = ${istTimestamp}
      RETURNING *
    `, [
      data.employee_id,
      data.date,
      data.check_in,
      data.check_out,
      data.status || 'present',
      data.overtime_hours || 0,
      data.late_hours || 0,
      data.notes,
      data.created_by
    ]);
    
    const newStatus = data.status || 'present';
    
    // Adjust paid leave balance when status changes to/from leave
    if (oldStatus === 'leave' && newStatus !== 'leave') {
      await db.query(`
        UPDATE employees 
        SET paid_leave_balance = paid_leave_balance + 1
        WHERE id = $1
      `, [data.employee_id]);
    } else if (oldStatus !== 'leave' && newStatus === 'leave') {
      await db.query(`
        UPDATE employees 
        SET paid_leave_balance = GREATEST(paid_leave_balance - 1, 0)
        WHERE id = $1
      `, [data.employee_id]);
      
      await db.query(`
        INSERT INTO employee_leaves (employee_id, leave_type, start_date, end_date, total_days, reason, status)
        VALUES ($1, 'Paid Leave', $2::date, $2::date, 1, $3, 'approved')
      `, [data.employee_id, data.date, data.notes || 'Marked from attendance']);
    }
    
    return result.rows[0];
  },

  // Bulk create multiple attendance records
  bulkCreate: async (records) => {
    console.log(`bulkCreate: Processing ${records.length} records`);
    const results = [];
    for (let i = 0; i < records.length; i++) {
      const record = records[i];
      console.log(`  Creating record ${i + 1}/${records.length}: employee_id=${record.employee_id}, date=${record.date}, status=${record.status}`);
      try {
        const result = await attendanceQueries.create(record);
        results.push(result);
      } catch (err) {
        console.error(`  Error creating record ${i + 1}:`, err.message);
        throw err;
      }
    }
    console.log(`bulkCreate: Complete, ${results.length} records saved`);
    return results;
  },

  // Update existing attendance record
  update: async (id, data) => {
    console.log('Update attendance - id:', id, 'data:', JSON.stringify(data));
    const current = await db.query('SELECT employee_id, status, date FROM attendance WHERE id = $1', [id]);
    if (current.rows.length === 0) return null;
    
    const oldStatus = current.rows[0].status;
    const employeeId = current.rows[0].employee_id;
    const attendanceDateValue = data.date || current.rows[0].date;
    
    const updates = [];
    const params = [];
    let paramIndex = 1;
    
    if (data.status != null && data.status !== '') {
      updates.push(`status = $${paramIndex++}`);
      params.push(data.status);
    }
    if (data.check_in != null) {
      updates.push(`check_in = $${paramIndex++}`);
      params.push(data.check_in);
    }
    if (data.check_out != null) {
      updates.push(`check_out = $${paramIndex++}`);
      params.push(data.check_out);
    }
    if (data.overtime_hours != null) {
      updates.push(`overtime_hours = $${paramIndex++}`);
      params.push(data.overtime_hours);
    }
    if (data.late_hours != null) {
      updates.push(`late_hours = $${paramIndex++}`);
      params.push(data.late_hours);
    }
    if (data.notes != null) {
      updates.push(`notes = $${paramIndex++}`);
      params.push(data.notes);
    }
    
    if (updates.length === 0) {
      return current.rows[0];
    }
    
    updates.push(`updated_at = ${istTimestamp}`);
    
    const result = await db.query(`
      UPDATE attendance SET
        ${updates.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING *
    `, [...params, id]);
    
    const newStatus = data.status || oldStatus;
    
    // Adjust leave balance on status change
    if (oldStatus === 'leave' && newStatus !== 'leave') {
      await db.query(`
        UPDATE employees 
        SET paid_leave_balance = paid_leave_balance + 1
        WHERE id = $1
      `, [employeeId]);
    } else if (oldStatus !== 'leave' && newStatus === 'leave') {
      await db.query(`
        UPDATE employees 
        SET paid_leave_balance = GREATEST(paid_leave_balance - 1, 0)
        WHERE id = $1
      `, [employeeId]);
      
      await db.query(`
        INSERT INTO employee_leaves (employee_id, leave_type, start_date, end_date, total_days, reason, status)
        VALUES ($1, 'Paid Leave', $2::date, $2::date, 1, $3, 'approved')
      `, [employeeId, attendanceDateValue, data.notes || 'Marked from attendance']);
    }
    
    return result.rows[0];
  },

  // Delete attendance record and restore leave balance if was on leave
  delete: async (id) => {
    const current = await db.query('SELECT employee_id, status, date FROM attendance WHERE id = $1', [id]);
    if (current.rows.length > 0) {
      if (current.rows[0].status === 'leave') {
        await db.query(`
          UPDATE employees 
          SET paid_leave_balance = paid_leave_balance + 1
          WHERE id = $1
        `, [current.rows[0].employee_id]);
        
        await db.query(`
          DELETE FROM employee_leaves 
          WHERE employee_id = $1 AND ${attendanceDate('start_date')} = $2::date AND status = 'approved'
        `, [current.rows[0].employee_id, current.rows[0].date]);
      }
    }
    await db.query('DELETE FROM attendance WHERE id = $1', [id]);
    return { deleted: true };
  },

  // Get daily attendance summary (counts by status)
  getDailySummary: async (date) => {
    const result = await db.query(`
      SELECT 
        COUNT(*) FILTER (WHERE a.status = 'present') as present_count,
        COUNT(*) FILTER (WHERE a.status = 'absent') as absent_count,
        COUNT(*) FILTER (WHERE a.status = 'half_day') as half_day_count,
        COUNT(*) FILTER (WHERE a.status = 'leave') as on_leave_count,
        COUNT(*) FILTER (WHERE a.status = 'holiday') as holiday_count,
        CAST(SUM(a.overtime_hours) AS DECIMAL(6,2)) as total_overtime
      FROM attendance a
      JOIN employees e ON a.employee_id = e.id
      WHERE ${attendanceDate('a.date')} = $1::date AND e.is_active = true
    `, [date]);
    return result.rows[0];
  },

  // Get monthly attendance summary for employee
  getMonthlySummary: async (employeeId, year, month) => {
    const result = await db.query(`
      SELECT 
        COUNT(*) FILTER (WHERE status = 'present') as present_days,
        COUNT(*) FILTER (WHERE status = 'absent') as absent_days,
        COUNT(*) FILTER (WHERE status = 'half_day') as half_days,
        CAST(SUM(overtime_hours) AS DECIMAL(6,2)) as total_overtime,
        CAST(SUM(late_hours) AS DECIMAL(6,2)) as total_late
      FROM attendance
      WHERE employee_id = $1 
        AND EXTRACT(YEAR FROM ${attendanceDate('date')}) = $2 
        AND EXTRACT(MONTH FROM ${attendanceDate('date')}) = $3
    `, [employeeId, year, month]);
    return result.rows[0];
  }
};

// Shift type queries
export const shiftQueries = {
  getAll: async () => {
    const result = await db.query(`
      SELECT * FROM shift_types WHERE is_active = true ORDER BY start_time ASC
    `);
    return result.rows;
  },

  create: async (data) => {
    const result = await db.query(`
      INSERT INTO shift_types (name, start_time, end_time, grace_minutes)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [data.name, data.start_time, data.end_time, data.grace_minutes || 15]);
    return result.rows[0];
  },

  assignToEmployee: async (employeeId, shiftTypeId, effectiveFrom) => {
    const result = await db.query(`
      INSERT INTO employee_shifts (employee_id, shift_type_id, effective_from)
      VALUES ($1, $2, $3::date)
      RETURNING *
    `, [employeeId, shiftTypeId, effectiveFrom]);
    return result.rows[0];
  }
};

// Leave balance queries
export const leaveQueries = {
  getPaidLeaveBalance: async (employeeId) => {
    console.log('Query: Getting leave balance for employeeId:', employeeId);
    
    const empResult = await db.query(`
      SELECT paid_leave_balance FROM employees WHERE id = $1
    `, [employeeId]);
    
    if (empResult.rows.length === 0) {
      return { total_leaves: 15, leaves_taken: 0, leaves_remaining: 15 };
    }
    
    let paidLeaveBalance = empResult.rows[0].paid_leave_balance;
    if (paidLeaveBalance === null || paidLeaveBalance === undefined) {
      paidLeaveBalance = 15;
    }
    
    const totalLeaves = 15;
    const leavesTaken = totalLeaves - paidLeaveBalance;
    const leavesRemaining = paidLeaveBalance;
    
    console.log('Employee paid_leave_balance:', paidLeaveBalance);
    console.log('Leaves remaining:', leavesRemaining);
    
    return {
      total_leaves: totalLeaves,
      leaves_taken: leavesTaken,
      leaves_remaining: leavesRemaining
    };
  }
};
