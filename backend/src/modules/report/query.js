import db from '../../config/db.js';

// ─── Shared date helpers ───────────────────────────────────────────────────────

const reportDate = (col) => `(${col})::date`;

const reportMonth = (col) => `EXTRACT(MONTH FROM ${reportDate(col)})::int`;

const dateWhere = (col, $s = 1, $e = 2) =>
  `($${$s}::date IS NULL OR ${reportDate(col)} >= $${$s}::date) AND ($${$e}::date IS NULL OR ${reportDate(col)} <= $${$e}::date)`;

const yearWhere = (col, $y = 1) =>
  `EXTRACT(YEAR FROM ${reportDate(col)}) = $${$y}`;

export const reportQueries = {

  // ─── 1. Overview (KPIs + resource status) ───────────────────────────────────
  // Returns high-level totals only — no per-record details

  getOverviewSummary: async (startDate, endDate) => {
    const params = [startDate || null, endDate || null];

    const [sales, expenses, resources] = await Promise.all([

      // Sales KPIs
      db.query(`
        SELECT
          COALESCE(SUM(total_amount), 0)::numeric  AS total_sales,
          COALESCE(SUM(amount_paid), 0)::numeric   AS collected,
          COUNT(*)::int                            AS invoice_count
        FROM invoices
        WHERE ${dateWhere('invoice_date')} AND status != 'cancelled'
      `, params),

      // Unified expense total from all 9 sources
      db.query(`
        SELECT COALESCE(SUM(amount), 0)::numeric AS total_expenses
        FROM (
          SELECT amount FROM expenses
            WHERE ${dateWhere('expense_date')}
          UNION ALL
          SELECT total_amount FROM diesel_purchases
            WHERE ${dateWhere('purchase_date')}
          UNION ALL
          SELECT amount FROM blast_expenses
            WHERE ${dateWhere('expense_date')}
          UNION ALL
          SELECT ss.net_salary AS amount FROM salary_slips ss
            JOIN salary_periods sp ON ss.period_id = sp.id
            WHERE ${dateWhere('COALESCE(ss.payment_date, sp.end_date)')}
          UNION ALL
          SELECT amount FROM salary_advances
            WHERE ${dateWhere('request_date')} AND status IN ('approved','paid')
          UNION ALL
          SELECT cost AS amount FROM maintenance_records
            WHERE ${dateWhere('maintenance_date')}
          UNION ALL
          SELECT COALESCE(prs.total_value, 0)::numeric AS amount
            FROM daily_production dp
            LEFT JOIN production_rate_snapshots prs ON dp.id = prs.production_id
            WHERE ${dateWhere('dp.production_date')}
        ) all_exp
      `, params),

      // Resource status (always current, not date-filtered)
      db.query(`
        SELECT
          (SELECT COUNT(*) FROM vehicles WHERE status = 'active')::int              AS active_vehicles,
          (SELECT COUNT(*) FROM employees WHERE is_active = true)::int              AS active_employees,
          (SELECT COALESCE(SUM(quantity), 0) FROM diesel_purchases)::numeric        AS diesel_stock_litres,
          (SELECT COUNT(*) FROM maintenance_records WHERE status = 'in_progress')::int AS equipment_maintenance
      `),
    ]);

    const totalSales     = parseFloat(sales.rows[0].total_sales)     || 0;
    const collected      = parseFloat(sales.rows[0].collected)        || 0;
    const totalExpenses  = parseFloat(expenses.rows[0].total_expenses) || 0;

    return {
      totalSales,
      collected,
      pendingPayments: totalSales - collected,
      invoiceCount:    sales.rows[0].invoice_count || 0,
      totalExpenses,
      netProfit: totalSales - totalExpenses,
      resources: {
        activeVehicles:       resources.rows[0].active_vehicles       || 0,
        activeEmployees:      resources.rows[0].active_employees       || 0,
        dieselStockLitres:    parseFloat(resources.rows[0].diesel_stock_litres) || 0,
        equipmentMaintenance: resources.rows[0].equipment_maintenance  || 0,
      },
    };
  },

  // ─── 2. Sales report (invoice list) ─────────────────────────────────────────

  getSalesReport: async (startDate, endDate) => {
    const result = await db.query(`
      SELECT
        i.id, i.invoice_number, i.invoice_date,
        i.total_amount::numeric, i.amount_paid::numeric,
        (i.total_amount - i.amount_paid)::numeric AS balance,
        i.status,
        c.name   AS customer_name,
        c.phone  AS customer_phone
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      WHERE ${dateWhere('i.invoice_date')} AND i.status != 'cancelled'
      ORDER BY i.invoice_date DESC
    `, [startDate || null, endDate || null]);
    return result.rows;
  },

  // ─── 3. Expense summary (all 9 sources) ─────────────────────────────────────

  getExpenseSummary: async (startDate, endDate) => {
    const p = [startDate || null, endDate || null];
    const result = await db.query(`
      SELECT
        COALESCE(SUM(CASE WHEN src = 'manual'      THEN amount END), 0)::numeric AS manual,
        COALESCE(SUM(CASE WHEN src = 'diesel'  AND paid THEN amount END), 0)::numeric AS diesel_paid,
        COALESCE(SUM(CASE WHEN src = 'diesel'  AND NOT paid THEN amount END), 0)::numeric AS diesel_pending,
        COALESCE(SUM(CASE WHEN src = 'blast'       THEN amount END), 0)::numeric AS blast,
        COALESCE(SUM(CASE WHEN src = 'royalty'     THEN amount END), 0)::numeric AS royalty,
        COALESCE(SUM(CASE WHEN src = 'maintenance' THEN amount END), 0)::numeric AS maintenance,
        COALESCE(SUM(CASE WHEN src = 'salary'  AND paid THEN amount END), 0)::numeric AS salaries_paid,
        COALESCE(SUM(CASE WHEN src = 'salary'  AND NOT paid THEN amount END), 0)::numeric AS salaries_pending,
        COALESCE(SUM(CASE WHEN src = 'advance'     THEN amount END), 0)::numeric AS advances,
        COALESCE(SUM(CASE WHEN src = 'production'  THEN amount END), 0)::numeric AS production_cost,
        COALESCE(SUM(amount), 0)::numeric AS total
      FROM (
        SELECT 'manual'::text AS src, amount, true AS paid
          FROM expenses WHERE ${dateWhere('expense_date')}
        UNION ALL
        SELECT 'diesel', total_amount, (payment_status != 'pending')
          FROM diesel_purchases WHERE ${dateWhere('purchase_date')}
        UNION ALL
        SELECT 'blast', amount, true
          FROM blast_expenses WHERE expense_type != 'royalty' AND ${dateWhere('expense_date')}
        UNION ALL
        SELECT 'royalty', amount, true
          FROM blast_expenses WHERE expense_type = 'royalty' AND ${dateWhere('expense_date')}
        UNION ALL
        SELECT 'maintenance', cost, true
          FROM maintenance_records WHERE ${dateWhere('maintenance_date')}
        UNION ALL
        SELECT 'salary', ss.net_salary, (ss.status = 'paid')
          FROM salary_slips ss
          JOIN salary_periods sp ON ss.period_id = sp.id
          WHERE ${dateWhere('COALESCE(ss.payment_date, sp.end_date)')}
        UNION ALL
        SELECT 'advance', amount, true
          FROM salary_advances WHERE ${dateWhere('request_date')} AND status IN ('approved','paid')
        UNION ALL
        SELECT 'production', COALESCE(prs.total_value, 0), true
          FROM daily_production dp
          LEFT JOIN production_rate_snapshots prs ON dp.id = prs.production_id
          WHERE ${dateWhere('dp.production_date')}
      ) t
    `, p);
    return result.rows[0];
  },

  // ─── 4. Profit/Loss (revenue vs costs for the period) ───────────────────────

  getProfitLoss: async (startDate, endDate) => {
    const p = [startDate || null, endDate || null];

    const [salesRes, expenseRes] = await Promise.all([
      db.query(`
        SELECT
          COALESCE(SUM(total_amount), 0)::numeric AS total_sales,
          COALESCE(SUM(amount_paid), 0)::numeric  AS collected
        FROM invoices
        WHERE ${dateWhere('invoice_date')} AND status != 'cancelled'
      `, p),

      db.query(`
        SELECT src, SUM(amount)::numeric AS total
        FROM (
          SELECT 'Manual Expenses'  AS src, amount FROM expenses WHERE ${dateWhere('expense_date')}
          UNION ALL
          SELECT 'Diesel',              total_amount FROM diesel_purchases WHERE ${dateWhere('purchase_date')}
          UNION ALL
          SELECT 'Blast / Drilling',    amount FROM blast_expenses WHERE expense_type != 'royalty' AND ${dateWhere('expense_date')}
          UNION ALL
          SELECT 'Royalty',             amount FROM blast_expenses WHERE expense_type = 'royalty' AND ${dateWhere('expense_date')}
          UNION ALL
          SELECT 'Maintenance',         cost       FROM maintenance_records WHERE ${dateWhere('maintenance_date')}
          UNION ALL
          SELECT 'Salaries',            ss.net_salary
            FROM salary_slips ss JOIN salary_periods sp ON ss.period_id = sp.id
            WHERE ${dateWhere('COALESCE(ss.payment_date, sp.end_date)')}
          UNION ALL
          SELECT 'Salary Advances',     amount FROM salary_advances WHERE ${dateWhere('request_date')} AND status IN ('approved','paid')
          UNION ALL
          SELECT 'Production Cost', COALESCE(prs.total_value, 0)
            FROM daily_production dp
            LEFT JOIN production_rate_snapshots prs ON dp.id = prs.production_id
            WHERE ${dateWhere('dp.production_date')}
        ) t
        GROUP BY src
        ORDER BY total DESC
      `, p),
    ]);

    const totalSales    = parseFloat(salesRes.rows[0].total_sales) || 0;
    const collected     = parseFloat(salesRes.rows[0].collected)   || 0;
    const costItems     = expenseRes.rows.map(r => ({ label: r.src, amount: parseFloat(r.total) || 0 }));
    const totalExpenses = costItems.reduce((s, r) => s + r.amount, 0);
    const netProfit     = totalSales - totalExpenses;

    return {
      totalSales,
      collected,
      pendingRevenue: totalSales - collected,
      totalExpenses,
      netProfit,
      profitMargin: totalSales > 0 ? ((netProfit / totalSales) * 100) : 0,
      costBreakdown: costItems,
    };
  },

  // ─── 5. Yearly trend (sales + expenses per month) ───────────────────────────

  getYearlyTrend: async (year) => {
    const result = await db.query(`
      WITH months AS (SELECT generate_series(1, 12) AS month),
      sales_data AS (
        SELECT ${reportMonth('invoice_date')} AS month,
               COALESCE(SUM(total_amount), 0)::numeric AS total_sales
        FROM invoices
        WHERE ${yearWhere('invoice_date')} AND status != 'cancelled'
        GROUP BY 1
      ),
      expense_data AS (
        SELECT month, SUM(amount)::numeric AS total_expenses
        FROM (
          SELECT ${reportMonth('expense_date')} AS month, amount FROM expenses             WHERE ${yearWhere('expense_date')}
          UNION ALL
          SELECT ${reportMonth('purchase_date')},  total_amount     FROM diesel_purchases     WHERE ${yearWhere('purchase_date')}
          UNION ALL
          SELECT ${reportMonth('expense_date')},   amount           FROM blast_expenses       WHERE ${yearWhere('expense_date')}
          UNION ALL
          SELECT ${reportMonth('maintenance_date')}, cost           FROM maintenance_records  WHERE ${yearWhere('maintenance_date')}
          UNION ALL
          SELECT sp.month, ss.net_salary FROM salary_slips ss JOIN salary_periods sp ON ss.period_id = sp.id WHERE sp.year = $1
          UNION ALL
          SELECT ${reportMonth('request_date')},   amount           FROM salary_advances      WHERE ${yearWhere('request_date')} AND status IN ('approved','paid')
          UNION ALL
          SELECT ${reportMonth('dp.production_date')},
                 COALESCE(prs.total_value, 0)
            FROM daily_production dp
            LEFT JOIN production_rate_snapshots prs ON dp.id = prs.production_id
            WHERE ${yearWhere('dp.production_date')}
        ) e WHERE month IS NOT NULL
        GROUP BY 1
      )
      SELECT
        m.month,
        COALESCE(sd.total_sales, 0)::numeric     AS total_sales,
        COALESCE(ed.total_expenses, 0)::numeric  AS total_expenses,
        (COALESCE(sd.total_sales, 0) - COALESCE(ed.total_expenses, 0))::numeric AS net_profit
      FROM months m
      LEFT JOIN sales_data sd    ON m.month = sd.month
      LEFT JOIN expense_data ed  ON m.month = ed.month
      ORDER BY m.month
    `, [year]);
    return result.rows;
  },
};
