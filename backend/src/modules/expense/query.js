import db from '../../config/db.js';

// Reusable date-range WHERE clause (NULL-safe, same $1/$2 across all subqueries)
const expenseDate = (col) => `(${col})::date`;

const istTimestamp = "CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'";

const dateWhere = (col) =>
  `($1::date IS NULL OR ${expenseDate(col)} >= $1::date) AND ($2::date IS NULL OR ${expenseDate(col)} <= $2::date)`;

export const expenseQueries = {
  // ─── Categories ────────────────────────────────────────────────────────────

  getAllCategories: async (activeOnly = true) => {
    const where = activeOnly ? 'WHERE is_active = true' : '';
    const result = await db.query(
      `SELECT * FROM expense_categories ${where} ORDER BY name`
    );
    return result.rows;
  },

  createCategory: async (data) => {
    const result = await db.query(
      `INSERT INTO expense_categories (name, description, icon, color, created_at)
       VALUES ($1, $2, $3, $4, ${istTimestamp}) RETURNING *`,
      [data.name, data.description, data.icon, data.color]
    );
    return result.rows[0];
  },

  // ─── Manual Expenses ────────────────────────────────────────────────────────

  getAllExpenses: async (filters = {}) => {
    let query = `
      SELECT e.*,
        ec.name as category_name, ec.icon as category_icon, ec.color as category_color,
        u.username as created_by_name
      FROM expenses e
      LEFT JOIN expense_categories ec ON e.category_id = ec.id
      LEFT JOIN users u ON e.created_by = u.id
      WHERE 1=1
    `;
    const params = [];
    if (filters.category_id) { params.push(filters.category_id); query += ` AND e.category_id = $${params.length}`; }
    if (filters.start_date)  { params.push(filters.start_date);  query += ` AND ${expenseDate('e.expense_date')} >= $${params.length}::date`; }
    if (filters.end_date)    { params.push(filters.end_date);    query += ` AND ${expenseDate('e.expense_date')} <= $${params.length}::date`; }
    if (filters.status)      { params.push(filters.status);      query += ` AND e.status = $${params.length}`; }
    query += ' ORDER BY e.expense_date DESC, e.id DESC';
    if (filters.limit) { params.push(filters.limit); query += ` LIMIT $${params.length}`; }
    const result = await db.query(query, params);
    return result.rows;
  },

  getExpenseById: async (id) => {
    const result = await db.query(`
      SELECT e.*,
        ec.name as category_name, ec.icon as category_icon, ec.color as category_color,
        u.username as created_by_name, a.username as approved_by_name
      FROM expenses e
      LEFT JOIN expense_categories ec ON e.category_id = ec.id
      LEFT JOIN users u ON e.created_by = u.id
      LEFT JOIN users a ON e.approved_by = a.id
      WHERE e.id = $1
    `, [id]);
    return result.rows[0];
  },

  createExpense: async (data) => {
    const result = await db.query(`
      INSERT INTO expenses (
        expense_number, category_id, expense_date, amount, payment_mode,
        vendor_name, description, reference_number, status, created_by,
        created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, ${istTimestamp}, ${istTimestamp})
      RETURNING *
    `, [
      data.expense_number, data.category_id, data.expense_date,
      data.amount, data.payment_mode, data.vendor_name, data.description,
      data.reference_number, data.status || 'approved', data.created_by,
    ]);
    return result.rows[0];
  },

  updateExpense: async (id, data) => {
    const result = await db.query(`
      UPDATE expenses SET
        category_id      = COALESCE($2, category_id),
        expense_date     = COALESCE($3, expense_date),
        amount           = COALESCE($4, amount),
        payment_mode     = COALESCE($5, payment_mode),
        vendor_name      = $6,
        description      = $7,
        reference_number = $8,
        status           = COALESCE($9, status),
        updated_at       = ${istTimestamp}
      WHERE id = $1 RETURNING *
    `, [id, data.category_id, data.expense_date, data.amount, data.payment_mode,
        data.vendor_name, data.description, data.reference_number, data.status]);
    return result.rows[0];
  },

  deleteExpense: async (id) => {
    const result = await db.query('DELETE FROM expenses WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  },

  getNextExpenseNumber: async () => {
    const result = await db.query(`
      SELECT COALESCE(MAX(CAST(SUBSTRING(expense_number FROM 5) AS INTEGER)), 0) + 1 AS next_num
      FROM expenses WHERE expense_number LIKE 'EXP-%'
    `);
    return `EXP-${String(result.rows[0].next_num).padStart(4, '0')}`;
  },

  approveExpense: async (id, approvedBy) => {
    const result = await db.query(`
      UPDATE expenses
      SET status = 'approved', approved_by = $2, approved_at = ${istTimestamp}
      WHERE id = $1 RETURNING *
    `, [id, approvedBy]);
    return result.rows[0];
  },

  // ─── Unified Expense List (all 9 sources) ─────────────────────────────────

  getFullUnifiedExpenses: async (filters = {}) => {
    // $1 = start_date (nullable), $2 = end_date (nullable)
    const params = [filters.start_date || null, filters.end_date || null];

    const sources = {
      manual: `
        SELECT
          'manual'::text                                AS source,
          e.id,
          COALESCE(e.expense_number, 'EXP-' || LPAD(e.id::text, 4, '0')) AS reference,
          e.expense_date,
          e.amount::numeric,
          e.description,
          e.vendor_name,
          e.payment_mode,
          e.status,
          COALESCE(ec.name, 'General')                 AS category_name,
          COALESCE(ec.icon, 'payments')                AS category_icon,
          COALESCE(ec.color, '#2196F3')                AS category_color,
          NULL::text                                   AS sub_info
        FROM expenses e
        LEFT JOIN expense_categories ec ON e.category_id = ec.id
        WHERE ${dateWhere('e.expense_date')}`,

      diesel: `
        SELECT
          'diesel'::text                               AS source,
          dp.id,
          'DSL-' || dp.id::text                        AS reference,
          dp.purchase_date                             AS expense_date,
          dp.total_amount::numeric                     AS amount,
          dp.remarks                                   AS description,
          dp.pump_name                                 AS vendor_name,
          NULL::text                                   AS payment_mode,
          dp.payment_status                            AS status,
          'Diesel Purchase'                            AS category_name,
          'local_gas_station'                          AS category_icon,
          '#4CAF50'                                    AS category_color,
          json_build_object(
            'quantity', dp.quantity,
            'rate', dp.rate_per_liter,
            'pump', dp.pump_name
          )::text                                      AS sub_info
        FROM diesel_purchases dp
        WHERE ${dateWhere('dp.purchase_date')}`,

      blast: `
        SELECT
          'blast'::text                                AS source,
          be.id,
          'BLT-' || be.id::text                        AS reference,
          be.expense_date,
          be.amount::numeric,
          be.description,
          NULL::text                                   AS vendor_name,
          NULL::text                                   AS payment_mode,
          'paid'::text                                 AS status,
          be.expense_type                              AS category_name,
          'flash_on'                                   AS category_icon,
          '#F44336'                                    AS category_color,
          json_build_object('blast_id', be.blast_id)::text AS sub_info
        FROM blast_expenses be
        WHERE be.expense_type != 'royalty'
          AND ${dateWhere('be.expense_date')}`,

      royalty: `
        SELECT
          'royalty'::text                              AS source,
          be.id,
          'ROY-' || be.id::text                        AS reference,
          be.expense_date,
          be.amount::numeric,
          be.description,
          NULL::text                                   AS vendor_name,
          NULL::text                                   AS payment_mode,
          'paid'::text                                 AS status,
          'Royalty'                                    AS category_name,
          'account_balance'                            AS category_icon,
          '#9C27B0'                                    AS category_color,
          json_build_object('blast_id', be.blast_id)::text AS sub_info
        FROM blast_expenses be
        WHERE be.expense_type = 'royalty'
          AND ${dateWhere('be.expense_date')}`,

      maintenance: `
        SELECT
          'maintenance'::text                          AS source,
          mr.id,
          'MNT-' || mr.id::text                        AS reference,
          mr.maintenance_date                          AS expense_date,
          mr.cost::numeric                             AS amount,
          mr.description,
          mr.vendor_name,
          NULL::text                                   AS payment_mode,
          mr.status,
          CASE
            WHEN mr.equipment_id IS NOT NULL
              THEN COALESCE(eq.name, 'Equipment') || ' Maintenance'
            ELSE COALESCE(v.vehicle_number, 'Vehicle') || ' Maintenance'
          END                                          AS category_name,
          'build'                                      AS category_icon,
          '#FF9800'                                    AS category_color,
          json_build_object(
            'equipment_name',   eq.name,
            'vehicle_number',   v.vehicle_number,
            'maintenance_type', mr.maintenance_type
          )::text                                      AS sub_info
        FROM maintenance_records mr
        LEFT JOIN equipment eq ON mr.equipment_id = eq.id
        LEFT JOIN vehicles  v  ON mr.vehicle_id   = v.id
        WHERE ${dateWhere('mr.maintenance_date')}`,

      salary: `
        SELECT
          'salary'::text                               AS source,
          ss.id,
          'SAL-' || ss.id::text                        AS reference,
          COALESCE(ss.payment_date, sp.end_date)       AS expense_date,
          ss.net_salary::numeric                       AS amount,
          ('Salary ' || sp.month || '/' || sp.year)   AS description,
          (e.first_name || ' ' || e.last_name)         AS vendor_name,
          ss.payment_mode,
          ss.status,
          'Employee Salary'                            AS category_name,
          'people'                                     AS category_icon,
          '#3F51B5'                                    AS category_color,
          json_build_object(
            'employee_code', e.employee_code,
            'department',    d.name,
            'month',         sp.month,
            'year',          sp.year
          )::text                                      AS sub_info
        FROM salary_slips ss
        JOIN salary_periods sp ON ss.period_id   = sp.id
        JOIN employees       e  ON ss.employee_id = e.id
        LEFT JOIN departments d  ON e.department_id = d.id
        WHERE ss.status != 'draft'
          AND ${dateWhere('COALESCE(ss.payment_date, sp.end_date)')}`,

      advance: `
        SELECT
          'advance'::text                              AS source,
          sa.id,
          'ADV-' || sa.id::text                        AS reference,
          sa.request_date                              AS expense_date,
          sa.amount::numeric,
          sa.reason                                    AS description,
          (e.first_name || ' ' || e.last_name)         AS vendor_name,
          NULL::text                                   AS payment_mode,
          sa.status,
          'Salary Advance'                             AS category_name,
          'account_balance_wallet'                     AS category_icon,
          '#009688'                                    AS category_color,
          json_build_object(
            'employee_code',   e.employee_code,
            'remaining_amount', sa.remaining_amount
          )::text                                      AS sub_info
        FROM salary_advances sa
        JOIN employees e ON sa.employee_id = e.id
        WHERE sa.status = 'approved'
          AND ${dateWhere('sa.request_date')}`,

      production: `
        SELECT
          'production'::text                           AS source,
          dp.id,
          'PRD-' || dp.id::text                        AS reference,
          dp.production_date                           AS expense_date,
          COALESCE(prs.total_value, 0)::numeric        AS amount,
          COALESCE(dp.notes, 'Daily Production')       AS description,
          NULL::text                                   AS vendor_name,
          NULL::text                                   AS payment_mode,
          'recorded'::text                             AS status,
          COALESCE(p.name, 'Production')               AS category_name,
          'factory'                                    AS category_icon,
          '#607D8B'                                    AS category_color,
          json_build_object(
            'quantity_tons', dp.quantity_tons,
            'product_name',  p.name
          )::text                                      AS sub_info
        FROM daily_production dp
        JOIN products p ON dp.product_id = p.id
        LEFT JOIN production_rate_snapshots prs ON dp.id = prs.production_id
        WHERE ${dateWhere('dp.production_date')}`,
    };

    const type = filters.type && filters.type !== 'all' ? filters.type : null;
    let query;

    if (type && sources[type]) {
      query = `${sources[type]} ORDER BY expense_date DESC`;
    } else {
      const parts = Object.values(sources).join('\n  UNION ALL\n');
      query = `${parts}\n  ORDER BY expense_date DESC`;
    }

    if (filters.limit) {
      params.push(filters.limit);
      query += ` LIMIT $${params.length}`;
    }

    const result = await db.query(query, params);
    return result.rows;
  },

  // ─── Unified Summary (all 9 sources) ──────────────────────────────────────

  getFullExpenseSummary: async (filters = {}) => {
    const params = [filters.start_date || null, filters.end_date || null];

    const [manual, diesel, blast, royalty, maintenance, salaries, advances, production] =
      await Promise.all([
        db.query(
          `SELECT COALESCE(SUM(amount), 0)::numeric AS total
           FROM expenses
           WHERE status = 'approved' AND ${dateWhere('expense_date')}`,
          params
        ),
        db.query(
          `SELECT
             COALESCE(SUM(CASE WHEN payment_status = 'paid'    THEN total_amount ELSE 0 END), 0)::numeric AS paid,
             COALESCE(SUM(CASE WHEN payment_status = 'pending' THEN total_amount ELSE 0 END), 0)::numeric AS pending
           FROM diesel_purchases
           WHERE ${dateWhere('purchase_date')}`,
          params
        ),
        db.query(
          `SELECT COALESCE(SUM(amount), 0)::numeric AS total
           FROM blast_expenses
           WHERE expense_type != 'royalty' AND ${dateWhere('expense_date')}`,
          params
        ),
        db.query(
          `SELECT COALESCE(SUM(amount), 0)::numeric AS total
           FROM blast_expenses
           WHERE expense_type = 'royalty' AND ${dateWhere('expense_date')}`,
          params
        ),
        db.query(
          `SELECT COALESCE(SUM(cost), 0)::numeric AS total
           FROM maintenance_records
           WHERE ${dateWhere('maintenance_date')}`,
          params
        ),
        db.query(
          `SELECT
             COALESCE(SUM(CASE WHEN ss.status = 'paid' THEN ss.net_salary ELSE 0 END), 0)::numeric AS paid,
             COALESCE(SUM(CASE WHEN ss.status != 'paid' THEN ss.net_salary ELSE 0 END), 0)::numeric AS pending
           FROM salary_slips ss
           JOIN salary_periods sp ON ss.period_id = sp.id
           WHERE ss.status != 'draft'
             AND ${dateWhere('COALESCE(ss.payment_date, sp.end_date)')}`,
          params
        ),
        db.query(
          `SELECT COALESCE(SUM(amount), 0)::numeric AS total
           FROM salary_advances
           WHERE status = 'approved' AND ${dateWhere('request_date')}`,
          params
        ),
        db.query(
          `SELECT COALESCE(SUM(COALESCE(prs.total_value, 0)), 0)::numeric AS total
           FROM daily_production dp
           LEFT JOIN production_rate_snapshots prs ON dp.id = prs.production_id
           WHERE ${dateWhere('dp.production_date')}`,
          params
        ),
      ]);

    const m    = parseFloat(manual.rows[0]?.total   || 0);
    const dp   = parseFloat(diesel.rows[0]?.paid    || 0);
    const dpnd = parseFloat(diesel.rows[0]?.pending || 0);
    const b    = parseFloat(blast.rows[0]?.total    || 0);
    const r    = parseFloat(royalty.rows[0]?.total  || 0);
    const mnt  = parseFloat(maintenance.rows[0]?.total    || 0);
    const sp   = parseFloat(salaries.rows[0]?.paid    || 0);
    const spnd = parseFloat(salaries.rows[0]?.pending || 0);
    const adv  = parseFloat(advances.rows[0]?.total   || 0);
    const prod = parseFloat(production.rows[0]?.total || 0);

    return {
      manual:           m,
      diesel_paid:      dp,
      diesel_pending:   dpnd,
      blast:            b,
      royalty:          r,
      maintenance:      mnt,
      salaries_paid:    sp,
      salaries_pending: spnd,
      advances:         adv,
      production_cost:  prod,
      total: m + dp + dpnd + b + r + mnt + sp + spnd + adv + prod,
    };
  },
};
