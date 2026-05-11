import db from '../../config/db.js';

async function initReportViews() {
  console.log('Creating report views and functions...');

  await db.query(`
    CREATE OR REPLACE VIEW monthly_sales_summary AS
    SELECT 
      DATE_TRUNC('month', i.invoice_date) as month,
      COUNT(DISTINCT i.id) as total_invoices,
      COUNT(DISTINCT i.customer_id) as unique_customers,
      SUM(i.total_amount) as total_sales,
      SUM(i.amount_paid) as total_collected,
      SUM(i.total_amount - i.amount_paid) as total_pending
    FROM invoices i
    WHERE i.status != 'cancelled'
    GROUP BY DATE_TRUNC('month', i.invoice_date)
    ORDER BY month DESC;
  `);
  console.log('Created monthly_sales_summary view');

  await db.query(`
    CREATE OR REPLACE VIEW monthly_expense_summary AS
    SELECT 
      DATE_TRUNC('month', expense_date) as month,
      ec.name as category,
      ec.color as category_color,
      COUNT(*) as expense_count,
      SUM(amount) as total_amount
    FROM expenses e
    JOIN expense_categories ec ON e.category_id = ec.id
    WHERE e.status = 'approved'
    GROUP BY DATE_TRUNC('month', expense_date), ec.name, ec.color
    ORDER BY month DESC, total_amount DESC;
  `);
  console.log('Created monthly_expense_summary view');

  await db.query(`
    CREATE OR REPLACE VIEW daily_production_summary AS
    SELECT 
      dp.production_date as date,
      p.name as product_name,
      p.category_id,
      pc.name as category_name,
      dp.quantity_tons as total_tons,
      COALESCE(cr.selling_rate_per_brass, 0) as rate,
      dp.quantity_tons * COALESCE(cr.selling_rate_per_brass, 0) as total_value
    FROM daily_production dp
    JOIN products p ON dp.product_id = p.id
    JOIN product_categories pc ON p.category_id = pc.id
    LEFT JOIN LATERAL (
      SELECT selling_rate_per_brass FROM crushing_rates
      WHERE product_id = dp.product_id
      ORDER BY effective_from DESC LIMIT 1
    ) cr ON true
    ORDER BY dp.production_date DESC;
  `);
  console.log('Created daily_production_summary view');

  await db.query(`
    CREATE OR REPLACE VIEW employee_attendance_summary AS
    SELECT 
      DATE_TRUNC('month', date) as month,
      COUNT(*) as total_records,
      COUNT(*) FILTER (WHERE status = 'present') as present_count,
      COUNT(*) FILTER (WHERE status = 'absent') as absent_count,
      COUNT(*) FILTER (WHERE status = 'leave') as leave_count,
      COUNT(*) FILTER (WHERE status = 'half_day') as half_day_count,
      SUM(COALESCE(overtime_hours, 0)) as total_overtime
    FROM attendance
    GROUP BY DATE_TRUNC('month', date)
    ORDER BY month DESC;
  `);
  console.log('Created employee_attendance_summary view');

  console.log('Report views initialized successfully!');
  process.exit(0);
}

initReportViews().catch(err => {
  console.error('Error initializing report views:', err);
  process.exit(1);
});
