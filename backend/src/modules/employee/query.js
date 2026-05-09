import db from '../../config/db.js';
import { IST_TIMESTAMP_SQL } from '../../utils/istDateTime.js';

export const departmentQueries = {
  // Get all departments with employee count
  getAll: async () => {
    const result = await db.query(`
      SELECT d.*, COUNT(e.id) as employee_count
      FROM departments d
      LEFT JOIN employees e ON d.id = e.department_id AND e.is_active = true
      GROUP BY d.id
      ORDER BY d.name ASC
    `);
    return result.rows;
  },

  // Create department
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO departments (name, description) VALUES ($1, $2) RETURNING *
    `, [data.name, data.description]);
    return result.rows[0];
  },

  // Update department
  update: async (id, data) => {
    const result = await db.query(`
      UPDATE departments SET name = COALESCE($1, name), description = COALESCE($2, description)
      WHERE id = $3 RETURNING *
    `, [data.name, data.description, id]);
    return result.rows[0];
  },

  // Delete department
  delete: async (id) => {
    await db.query('DELETE FROM departments WHERE id = $1', [id]);
    return { deleted: true };
  }
};

export const employeeQueries = {
  // Get all employees with optional filters
  getAll: async (filters = {}) => {
    let query = `
      SELECT e.*, 
             d.name as department_name,
             COALESCE(e.paid_leave_balance, 15) as paid_leave_balance,
             COALESCE(SUM(el.total_days), 0) as total_leaves
      FROM employees e
      LEFT JOIN departments d ON e.department_id = d.id
      LEFT JOIN employee_leaves el ON e.id = el.employee_id AND el.status = 'approved'
      WHERE 1=1
    `;
    
    const params = [];
    let paramIndex = 1;

    if (filters.isActive !== undefined) {
      query += ` AND e.is_active = $${paramIndex++}`;
      params.push(filters.isActive);
    }
    if (filters.departmentId) {
      query += ` AND e.department_id = $${paramIndex++}`;
      params.push(filters.departmentId);
    }
    if (filters.employeeType) {
      query += ` AND e.employee_type = $${paramIndex++}`;
      params.push(filters.employeeType);
    }

    query += ' GROUP BY e.id, d.name ORDER BY e.is_active DESC, e.first_name ASC';

    const result = await db.query(query, params);
    return result.rows;
  },

  // Get single employee by ID
  getById: async (id) => {
    const result = await db.query(`
      SELECT e.*, d.name as department_name,
             COALESCE(SUM(CASE WHEN el.status = 'approved' AND el.leave_type = 'earned' THEN el.total_days ELSE 0 END), 0) as leaves_taken
      FROM employees e
      LEFT JOIN departments d ON e.department_id = d.id
      LEFT JOIN employee_leaves el ON e.id = el.employee_id
      WHERE e.id = $1
      GROUP BY e.id, d.name
    `, [id]);
    return result.rows[0];
  },

  // Get only active employees
  getActive: async () => {
    const result = await db.query(`
      SELECT e.*, d.name as department_name
      FROM employees e
      LEFT JOIN departments d ON e.department_id = d.id
      WHERE e.is_active = true
      ORDER BY e.first_name ASC
    `);
    return result.rows;
  },

  // Create new employee
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO employees (
        employee_code, first_name, last_name, email, phone, alternate_phone,
        date_of_birth, date_of_joining, department_id, designation,
        employee_type, salary, aadhaar_number, pan_number,
        bank_account, bank_name, ifsc_code, upi_id, address, city, state,
        emergency_contact_name, emergency_contact_phone, emergency_contact_relation,
        is_active, paid_leave_balance, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27)
      RETURNING *
    `, [
      data.employee_code,
      data.first_name,
      data.last_name,
      data.email,
      data.phone,
      data.alternate_phone,
      data.date_of_birth,
      data.date_of_joining,
      data.department_id,
      data.designation,
      data.employee_type || 'permanent',
      data.salary || 0,
      data.aadhaar_number,
      data.pan_number,
      data.bank_account,
      data.bank_name,
      data.ifsc_code,
      data.upi_id,
      data.address,
      data.city,
      data.state,
      data.emergency_contact_name,
      data.emergency_contact_phone,
      data.emergency_contact_relation,
      data.is_active !== false,
      data.paid_leave_balance || 15,
      data.notes
    ]);
    return result.rows[0];
  },

  // Update employee (dynamic field mapping)
  update: async (id, data) => {
    const fields = [];
    const values = [];
    let paramIndex = 1;
    
    const fieldMap = {
      first_name: 'first_name',
      last_name: 'last_name',
      email: 'email',
      phone: 'phone',
      alternate_phone: 'alternate_phone',
      date_of_birth: 'date_of_birth',
      department_id: 'department_id',
      designation: 'designation',
      employee_type: 'employee_type',
      salary: 'salary',
      aadhaar_number: 'aadhaar_number',
      pan_number: 'pan_number',
      bank_account: 'bank_account',
      bank_name: 'bank_name',
      ifsc_code: 'ifsc_code',
      upi_id: 'upi_id',
      address: 'address',
      city: 'city',
      state: 'state',
      emergency_contact_name: 'emergency_contact_name',
      emergency_contact_phone: 'emergency_contact_phone',
      emergency_contact_relation: 'emergency_contact_relation',
      is_active: 'is_active',
      date_of_leaving: 'date_of_leaving',
      paid_leave_balance: 'paid_leave_balance',
      notes: 'notes',
    };
    
    for (const [key, dbField] of Object.entries(fieldMap)) {
      if (data[key] !== undefined && data[key] !== null) {
        fields.push(`${dbField} = $${paramIndex++}`);
        values.push(data[key]);
      }
    }
    
    if (fields.length === 0) {
      return { id, message: 'No fields to update' };
    }
    
    fields.push(`updated_at = ${IST_TIMESTAMP_SQL}`);
    values.push(id);
    
    const query = `UPDATE employees SET ${fields.join(', ')} WHERE id = $${paramIndex} RETURNING *`;
    const result = await db.query(query, values);
    return result.rows[0];
  },

  // Delete employee
  delete: async (id) => {
    await db.query('DELETE FROM employees WHERE id = $1', [id]);
    return { deleted: true };
  },

  // Generate next employee code (format: EMP-001)
  getNextCode: async () => {
    const result = await db.query(`
      SELECT COALESCE(MAX(CAST(SUBSTRING(employee_code FROM '[0-9]+$') AS INTEGER)), 0) + 1 as next_number
      FROM employees
      WHERE employee_code LIKE 'EMP-%'
    `);
    return `EMP-${String(result.rows[0].next_number).padStart(3, '0')}`;
  },

  // Get employee statistics for active employees
  getStats: async () => {
    const result = await db.query(`
      SELECT 
        COUNT(*) as total_employees,
        COUNT(CASE WHEN is_active = true THEN 1 END) as active_count,
        COUNT(CASE WHEN employee_type = 'permanent' THEN 1 END) as permanent_count,
        COUNT(CASE WHEN employee_type = 'contract' THEN 1 END) as contract_count,
        COUNT(CASE WHEN employee_type = 'daily' THEN 1 END) as daily_wagers,
        CAST(SUM(salary) AS DECIMAL(12,2)) as total_salary
      FROM employees
      WHERE is_active = true
    `);
    return result.rows[0];
  }
};

export const documentQueries = {
  // Get documents for employee
  getByEmployeeId: async (employeeId) => {
    const result = await db.query(`
      SELECT * FROM employee_documents WHERE employee_id = $1 ORDER BY expiry_date ASC NULLS LAST
    `, [employeeId]);
    return result.rows;
  },

  // Create employee document
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO employee_documents (
        employee_id, document_type, document_number, issue_date, expiry_date, file_path, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [
      data.employee_id,
      data.document_type,
      data.document_number,
      data.issue_date,
      data.expiry_date,
      data.file_path,
      data.notes
    ]);
    return result.rows[0];
  },

  // Delete document
  delete: async (id) => {
    await db.query('DELETE FROM employee_documents WHERE id = $1', [id]);
    return { deleted: true };
  }
};

export const leaveQueries = {
  // Get leaves for employee
  getByEmployeeId: async (employeeId) => {
    const result = await db.query(`
      SELECT el.*, u.username as approved_by_name
      FROM employee_leaves el
      LEFT JOIN users u ON el.approved_by = u.id
      WHERE el.employee_id = $1
      ORDER BY el.start_date DESC
    `, [employeeId]);
    return result.rows;
  },

  // Get pending leave requests
  getPending: async () => {
    const result = await db.query(`
      SELECT el.*, e.first_name, e.last_name, d.name as department_name
      FROM employee_leaves el
      JOIN employees e ON el.employee_id = e.id
      LEFT JOIN departments d ON e.department_id = d.id
      WHERE el.status = 'pending'
      ORDER BY el.created_at DESC
    `);
    return result.rows;
  },

  // Create leave request
  create: async (data) => {
    const result = await db.query(`
      INSERT INTO employee_leaves (
        employee_id, leave_type, start_date, end_date, total_days, reason, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [
      data.employee_id,
      data.leave_type,
      data.start_date,
      data.end_date,
      data.total_days || 1,
      data.reason,
      data.status || 'pending'
    ]);
    return result.rows[0];
  },

  // Approve/reject leave
  updateStatus: async (id, status, approvedBy) => {
    const result = await db.query(`
      UPDATE employee_leaves SET 
        status = $1, 
        approved_by = $2, 
        approved_at = ${IST_TIMESTAMP_SQL}
      WHERE id = $3
      RETURNING *
    `, [status, approvedBy, id]);
    return result.rows[0];
  },

  // Delete leave request
  delete: async (id) => {
    await db.query('DELETE FROM employee_leaves WHERE id = $1', [id]);
    return { deleted: true };
  }
};
