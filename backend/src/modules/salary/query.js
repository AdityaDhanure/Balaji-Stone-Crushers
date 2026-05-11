import db from '../../config/db.js';
import { IST_DATE_SQL, IST_TIMESTAMP_SQL } from '../../utils/istDateTime.js';

export const salaryQueries = {
  getAllPeriods: async () => {
    const result = await db.query(`
      SELECT id, year, month, start_date, end_date, is_locked, created_at
      FROM salary_periods
      ORDER BY year DESC, month DESC
    `);
    return result.rows;
  },

  getPeriodById: async (id) => {
    const result = await db.query(`
      SELECT id, year, month, start_date, end_date, is_locked, created_at
      FROM salary_periods WHERE id = $1
    `, [id]);
    return result.rows[0];
  },

  createPeriod: async (data) => {
    const { year, month, start_date, end_date } = data;
    const result = await db.query(`
      INSERT INTO salary_periods (year, month, start_date, end_date)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [year, month, start_date, end_date]);
    return result.rows[0];
  },

  getPeriodByYearMonth: async (year, month) => {
    const result = await db.query(`
      SELECT id, year, month, start_date, end_date, is_locked, created_at
      FROM salary_periods WHERE year = $1 AND month = $2
    `, [year, month]);
    return result.rows[0];
  },

  lockPeriod: async (id, isLocked = true) => {
    const lockValue = isLocked === true || isLocked === 'true';
    const result = await db.query(`
      UPDATE salary_periods SET is_locked = $2 WHERE id = $1 RETURNING *
    `, [id, lockValue]);
    return result.rows[0];
  },

  getAllEmployees: async (activeOnly = true) => {
    const whereClause = activeOnly ? 'WHERE e.is_active = true' : '';
    const result = await db.query(`
      SELECT e.id, e.employee_code, e.first_name, e.last_name, e.salary,
             e.department_id, e.employee_type, d.name as department_name
      FROM employees e
      LEFT JOIN departments d ON e.department_id = d.id
      ${whereClause}
      ORDER BY e.employee_code
    `);
    return result.rows;
  },

  getSalarySlipsByPeriod: async (periodId) => {
    const result = await db.query(`
      SELECT ss.*, e.employee_code, e.first_name, e.last_name,
             e.department_id, d.name as department_name
      FROM salary_slips ss
      JOIN employees e ON ss.employee_id = e.id
      LEFT JOIN departments d ON e.department_id = d.id
      WHERE ss.period_id = $1
      ORDER BY e.employee_code
    `, [periodId]);
    return result.rows;
  },

  getSalarySlipById: async (id) => {
    const result = await db.query(`
      SELECT ss.*, e.employee_code, e.first_name, e.last_name, e.salary as base_salary,
             e.department_id, d.name as department_name, e.bank_account, e.bank_name, e.ifsc_code,
             u.username as created_by_name
      FROM salary_slips ss
      JOIN employees e ON ss.employee_id = e.id
      LEFT JOIN departments d ON e.department_id = d.id
      LEFT JOIN users u ON ss.created_by = u.id
      WHERE ss.id = $1
    `, [id]);
    return result.rows[0];
  },

  getSalarySlipByEmployeeAndPeriod: async (employeeId, periodId) => {
    const result = await db.query(`
      SELECT * FROM salary_slips WHERE employee_id = $1 AND period_id = $2
    `, [employeeId, periodId]);
    return result.rows[0];
  },

  createSalarySlip: async (data) => {
    const {
      employee_id, period_id, basic_salary, hra, allowances, overtime_amount, bonus,
      total_earnings, pf_deduction, tds_deduction, other_deductions, total_deductions,
      net_salary, present_days, absent_days, leave_days, half_days, sundays, worked_days,
      total_days, status, created_by, extra_days
    } = data;

    const result = await db.query(`
      INSERT INTO salary_slips (
        employee_id, period_id, basic_salary, hra, allowances, overtime_amount, bonus,
        total_earnings, pf_deduction, tds_deduction, other_deductions, total_deductions,
        net_salary, present_days, absent_days, leave_days, half_days, sundays, worked_days,
        total_days, status, created_by, extra_days
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23)
      RETURNING *
    `, [
      employee_id, period_id, basic_salary, hra || 0, allowances || 0,
      overtime_amount || 0, bonus || 0, total_earnings || 0, pf_deduction || 0,
      tds_deduction || 0, other_deductions || 0, total_deductions || 0, net_salary || 0,
      present_days || 0, absent_days || 0, leave_days || 0, half_days || 0,
      sundays || 0, worked_days || 0, total_days || 0,
      status || 'draft', created_by, extra_days || 0
    ]);
    return result.rows[0];
  },

  // WARNING: This is a schema migration embedded in a query file.
  // It should only be called from an init/migration script, NOT on every API request.
  // Safe to run repeatedly (IF NOT EXISTS guard) but wasteful in production.
  // TODO: Remove this call from any service/controller that invokes it at runtime.
  ensureExtraDaysColumn: async () => {
    await db.query(`
      ALTER TABLE salary_slips
      ADD COLUMN IF NOT EXISTS extra_days NUMERIC(5,1) DEFAULT 0
    `);
  },

  updateSalarySlip: async (id, data) => {
    const {
      basic_salary, hra, allowances, overtime_amount, bonus,
      total_earnings, pf_deduction, tds_deduction, other_deductions, total_deductions,
      net_salary, present_days, absent_days, leave_days, worked_days, total_days,
      status, payment_date, payment_mode, transaction_id, notes
    } = data;

    const result = await db.query(`
      UPDATE salary_slips SET
        basic_salary = COALESCE($2, basic_salary),
        hra = COALESCE($3, hra),
        allowances = COALESCE($4, allowances),
        overtime_amount = COALESCE($5, overtime_amount),
        bonus = COALESCE($6, bonus),
        total_earnings = COALESCE($7, total_earnings),
        pf_deduction = COALESCE($8, pf_deduction),
        tds_deduction = COALESCE($9, tds_deduction),
        other_deductions = COALESCE($10, other_deductions),
        total_deductions = COALESCE($11, total_deductions),
        net_salary = COALESCE($12, net_salary),
        present_days = COALESCE($13, present_days),
        absent_days = COALESCE($14, absent_days),
        leave_days = COALESCE($15, leave_days),
        worked_days = COALESCE($16, worked_days),
        total_days = COALESCE($17, total_days),
        status = COALESCE($18, status),
        payment_date = $19,
        payment_mode = $20,
        transaction_id = $21,
        notes = $22,
        updated_at = ${IST_TIMESTAMP_SQL}
      WHERE id = $1
      RETURNING *
    `, [
      id, basic_salary, hra, allowances, overtime_amount, bonus, total_earnings,
      pf_deduction, tds_deduction, other_deductions, total_deductions, net_salary,
      present_days, absent_days, leave_days, worked_days, total_days, status,
      payment_date, payment_mode, transaction_id, notes
    ]);
    return result.rows[0];
  },

  deleteSalarySlip: async (id) => {
    const result = await db.query('DELETE FROM salary_slips WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  },

  getAttendanceSummary: async (employeeId, startDate, endDate) => {
    const result = await db.query(`
      SELECT 
        COUNT(*) FILTER (WHERE status = 'present' AND EXTRACT(DOW FROM date::date) <> 0) as present_days,
        COUNT(*) FILTER (WHERE status = 'absent' AND EXTRACT(DOW FROM date::date) <> 0) as absent_days,
        COUNT(*) FILTER (WHERE status = 'leave' AND EXTRACT(DOW FROM date::date) <> 0) as leave_days,
        COUNT(*) FILTER (WHERE status = 'half_day' AND EXTRACT(DOW FROM date::date) <> 0) as half_days,
        COALESCE(SUM(CAST(overtime_hours AS DECIMAL(10,2))), 0) as overtime_hours,
        COALESCE(SUM(
          CASE
            WHEN EXTRACT(DOW FROM date::date) = 0 AND status = 'present' THEN 1
            WHEN EXTRACT(DOW FROM date::date) = 0 AND status = 'half_day' THEN 0.5
            ELSE 0
          END
        ), 0) as sunday_days_worked,
        COUNT(*) as total_records
      FROM attendance
      WHERE employee_id = $1 AND date BETWEEN $2 AND $3
    `, [employeeId, startDate, endDate]);
    return result.rows[0];
  },

  checkAttendanceExists: async (employeeId, startDate, endDate) => {
    const result = await db.query(`
      SELECT COUNT(*) as count FROM attendance
      WHERE employee_id = $1 AND date BETWEEN $2 AND $3
    `, [employeeId, startDate, endDate]);
    return parseInt(result.rows[0].count) > 0;
  },

  getAdvances: async (employeeId = null) => {
    const whereClause = employeeId ? 'WHERE sa.employee_id = $1' : '';
    const params = employeeId ? [employeeId] : [];
    const result = await db.query(`
      SELECT sa.*, e.employee_code, e.first_name, e.last_name
      FROM salary_advances sa
      JOIN employees e ON sa.employee_id = e.id
      ${whereClause}
      ORDER BY sa.request_date DESC
    `, params);
    return result.rows;
  },

  createAdvance: async (data) => {
    const { employee_id, amount, request_date, reason, created_by } = data;
    const result = await db.query(`
      INSERT INTO salary_advances (employee_id, amount, request_date, reason, created_by, remaining_amount)
      VALUES ($1, $2, COALESCE($3::date, ${IST_DATE_SQL}), $4, $5, $2)
      RETURNING *
    `, [employee_id, amount, request_date || null, reason, created_by]);
    return result.rows[0];
  },

  updateAdvanceStatus: async (id, status, approvedBy) => {
    const result = await db.query(`
      UPDATE salary_advances SET
        status = $2,
        approved_by = $3,
        approved_at = ${IST_TIMESTAMP_SQL}
      WHERE id = $1
      RETURNING *
    `, [id, status, approvedBy]);
    return result.rows[0];
  },

  getDeductions: async (activeOnly = false) => {
    const whereClause = activeOnly ? 'WHERE is_active = true' : '';
    const result = await db.query(`
      SELECT * FROM salary_deductions ${whereClause} ORDER BY name
    `);
    return result.rows;
  },

  createDeduction: async (data) => {
    const { name, type, calculation_type, value, description } = data;
    const result = await db.query(`
      INSERT INTO salary_deductions (name, type, calculation_type, value, description)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [name, type, calculation_type || 'percentage', value || 0, description]);
    return result.rows[0];
  },

  updateDeduction: async (id, data) => {
    const { name, type, calculation_type, value, description, is_active } = data;
    
    // Build dynamic update query
    const updates = [];
    const params = [id];
    let paramIndex = 2;
    
    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      params.push(name);
    }
    if (type !== undefined) {
      updates.push(`type = $${paramIndex++}`);
      params.push(type);
    }
    if (calculation_type !== undefined) {
      updates.push(`calculation_type = $${paramIndex++}`);
      params.push(calculation_type);
    }
    if (value !== undefined) {
      updates.push(`value = $${paramIndex++}`);
      params.push(value);
    }
    if (description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      params.push(description);
    }
    if (is_active !== undefined) {
      updates.push(`is_active = $${paramIndex++}`);
      params.push(is_active);
    }
    
    if (updates.length === 0) {
      const result = await db.query('SELECT * FROM salary_deductions WHERE id = $1', [id]);
      return result.rows[0];
    }
    
    const query = `
      UPDATE salary_deductions SET ${updates.join(', ')}
      WHERE id = $1
      RETURNING *
    `;
    
    const result = await db.query(query, params);
    return result.rows[0];
  },

  deleteDeduction: async (id) => {
    const result = await db.query('DELETE FROM salary_deductions WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  },

  getPendingAdvancesByEmployee: async (employeeId) => {
    const result = await db.query(`
      SELECT * FROM salary_advances
      WHERE employee_id = $1 AND remaining_amount > 0 AND status = 'approved'
      ORDER BY request_date DESC
    `, [employeeId]);
    return result.rows;
  },

  getSalarySummary: async (periodId) => {
    const result = await db.query(`
      SELECT 
        COUNT(*) as total_employees,
        SUM(total_earnings) as total_earnings,
        SUM(total_deductions) as total_deductions,
        SUM(net_salary) as total_net_salary,
        COUNT(*) FILTER (WHERE status = 'paid') as paid_count,
        COUNT(*) FILTER (WHERE status = 'pending') as pending_count
      FROM salary_slips
      WHERE period_id = $1
    `, [periodId]);
    return result.rows[0];
  },

  getAllSlips: async (filters = {}) => {
    let query = `
      SELECT ss.*, e.employee_code, e.first_name, e.last_name,
             e.department_id, d.name as department_name, sp.year, sp.month
      FROM salary_slips ss
      JOIN employees e ON ss.employee_id = e.id
      LEFT JOIN departments d ON e.department_id = d.id
      JOIN salary_periods sp ON ss.period_id = sp.id
      WHERE 1=1
    `;
    const params = [];

    if (filters.employee_id) {
      params.push(filters.employee_id);
      query += ` AND ss.employee_id = $${params.length}`;
    }
    if (filters.period_id) {
      params.push(filters.period_id);
      query += ` AND ss.period_id = $${params.length}`;
    }
    if (filters.status) {
      params.push(filters.status);
      query += ` AND ss.status = $${params.length}`;
    }
    if (filters.department_id) {
      params.push(filters.department_id);
      query += ` AND e.department_id = $${params.length}`;
    }

    query += ' ORDER BY sp.year DESC, sp.month DESC, e.employee_code';

    const result = await db.query(query, params);
    return result.rows;
  },

  // ── Salary Earnings ──────────────────────────────────────────────────────

  // WARNING: This creates a table and seeds default data at query-call time.
  // It should only be called from an init/migration script, NOT on every API request.
  // Safe to run repeatedly (IF NOT EXISTS + COUNT guard) but wasteful in production.
  // TODO: Move this logic to a dedicated init-salary-tables.js script.
  initializeEarningsTable: async () => {
    await db.query(`
      CREATE TABLE IF NOT EXISTS salary_earnings (
        id             SERIAL PRIMARY KEY,
        name           VARCHAR(100)   NOT NULL,
        type           VARCHAR(50)    NOT NULL DEFAULT 'other',
        calculation_type VARCHAR(20)  NOT NULL DEFAULT 'percentage',
        value          DECIMAL(10,4)  NOT NULL DEFAULT 0,
        is_active      BOOLEAN        NOT NULL DEFAULT true,
        description    TEXT,
        created_at     TIMESTAMP      DEFAULT (${IST_TIMESTAMP_SQL})
      )
    `);
    // Seed defaults if table is empty
    const count = await db.query('SELECT COUNT(*) FROM salary_earnings');
    if (parseInt(count.rows[0].count) === 0) {
      await db.query(`
        INSERT INTO salary_earnings (name, type, calculation_type, value, description) VALUES
          ('House Rent Allowance (HRA)', 'hra',       'percentage', 10, 'HRA = 10% of basic salary'),
          ('House Allowance',           'allowance',  'percentage',  5, 'House allowance = 5% of basic salary')
      `);
    }
  },

  getEarnings: async (activeOnly = false) => {
    const where = activeOnly ? 'WHERE is_active = true' : '';
    const result = await db.query(
      `SELECT * FROM salary_earnings ${where} ORDER BY name`
    );
    return result.rows;
  },

  createEarning: async ({ name, type, calculation_type, value, description }) => {
    const result = await db.query(`
      INSERT INTO salary_earnings (name, type, calculation_type, value, description)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [name, type, calculation_type || 'percentage', value || 0, description]);
    return result.rows[0];
  },

  updateEarning: async (id, data) => {
    const { name, type, calculation_type, value, description, is_active } = data;
    const updates = [];
    const params = [id];
    let i = 2;
    if (name            !== undefined) { updates.push(`name = $${i++}`);              params.push(name); }
    if (type            !== undefined) { updates.push(`type = $${i++}`);              params.push(type); }
    if (calculation_type !== undefined){ updates.push(`calculation_type = $${i++}`);  params.push(calculation_type); }
    if (value           !== undefined) { updates.push(`value = $${i++}`);             params.push(value); }
    if (description     !== undefined) { updates.push(`description = $${i++}`);       params.push(description); }
    if (is_active       !== undefined) { updates.push(`is_active = $${i++}`);         params.push(is_active); }
    if (updates.length === 0) {
      const r = await db.query('SELECT * FROM salary_earnings WHERE id = $1', [id]);
      return r.rows[0];
    }
    const result = await db.query(
      `UPDATE salary_earnings SET ${updates.join(', ')} WHERE id = $1 RETURNING *`,
      params
    );
    return result.rows[0];
  },

  deleteEarning: async (id) => {
    const result = await db.query(
      'DELETE FROM salary_earnings WHERE id = $1 RETURNING *', [id]
    );
    return result.rows[0];
  },
};
