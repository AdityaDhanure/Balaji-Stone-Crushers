import db from '../../config/db.js';
import { todayIst } from '../../utils/istDateTime.js';

async function initSalaryTables() {
  console.log('Initializing salary tables...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS salary_periods (
      id SERIAL PRIMARY KEY,
      year INTEGER NOT NULL,
      month INTEGER NOT NULL,
      start_date DATE NOT NULL,
      end_date DATE NOT NULL,
      is_locked BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      UNIQUE(year, month)
    );
  `);
  console.log('Created salary_periods table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS salary_slips (
      id SERIAL PRIMARY KEY,
      employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
      period_id INTEGER REFERENCES salary_periods(id) ON DELETE CASCADE,
      basic_salary DECIMAL(10, 2) NOT NULL DEFAULT 0,
      hra DECIMAL(10, 2) DEFAULT 0,
      allowances DECIMAL(10, 2) DEFAULT 0,
      overtime_amount DECIMAL(10, 2) DEFAULT 0,
      bonus DECIMAL(10, 2) DEFAULT 0,
      total_earnings DECIMAL(10, 2) DEFAULT 0,
      pf_deduction DECIMAL(10, 2) DEFAULT 0,
      tds_deduction DECIMAL(10, 2) DEFAULT 0,
      other_deductions DECIMAL(10, 2) DEFAULT 0,
      total_deductions DECIMAL(10, 2) DEFAULT 0,
      net_salary DECIMAL(10, 2) DEFAULT 0,
      present_days INTEGER DEFAULT 0,
      absent_days INTEGER DEFAULT 0,
      leave_days INTEGER DEFAULT 0,
      half_days INTEGER DEFAULT 0,
      sundays INTEGER DEFAULT 0,
      worked_days DECIMAL(5,1) DEFAULT 0,
      total_days INTEGER DEFAULT 0,
      status VARCHAR(50) DEFAULT 'draft',
      payment_date DATE,
      payment_mode VARCHAR(50),
      transaction_id VARCHAR(100),
      notes TEXT,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      UNIQUE(employee_id, period_id)
    );
  `);
  console.log('Created salary_slips table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS salary_advances (
      id SERIAL PRIMARY KEY,
      employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
      amount DECIMAL(10, 2) NOT NULL,
      request_date DATE NOT NULL,
      reason TEXT,
      status VARCHAR(50) DEFAULT 'pending',
      approved_by INTEGER REFERENCES users(id),
      approved_at TIMESTAMP,
      repayment_start_date DATE,
      repayment_amount DECIMAL(10, 2) DEFAULT 0,
      total_repaid DECIMAL(10, 2) DEFAULT 0,
      remaining_amount DECIMAL(10, 2) DEFAULT 0,
      notes TEXT,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created salary_advances table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS salary_deductions (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      type VARCHAR(50) NOT NULL,
      calculation_type VARCHAR(50) DEFAULT 'percentage',
      value DECIMAL(10, 2) DEFAULT 0,
      is_active BOOLEAN DEFAULT true,
      description TEXT,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created salary_deductions table');

  const dedCount = await db.query('SELECT COUNT(*) FROM salary_deductions');
  if (parseInt(dedCount.rows[0].count) === 0) {
    await db.query(`
      INSERT INTO salary_deductions (name, type, calculation_type, value, description) VALUES
        ('Provident Fund (PF)', 'pf', 'percentage', 12, 'Employee PF contribution @ 12% of basic salary'),
        ('Professional Tax', 'tax', 'fixed', 200, 'Monthly professional tax deduction'),
        ('TDS', 'tds', 'percentage', 10, 'Tax deducted at source based on tax slab')
      ON CONFLICT DO NOTHING;
    `);
    console.log('Inserted default deductions');
  }

  const periodCount = await db.query('SELECT COUNT(*) FROM salary_periods');
  if (parseInt(periodCount.rows[0].count) === 0) {
    const [currentYear, currentMonth] = todayIst().split('-').map(Number);
    for (let i = 0; i < 3; i++) {
      const date = new Date(Date.UTC(currentYear, currentMonth - 1 - i, 1));
      const year = date.getUTCFullYear();
      const month = date.getUTCMonth() + 1;
      const startDate = new Date(Date.UTC(year, month - 1, 1));
      const endDate = new Date(Date.UTC(year, month, 0));
      await db.query(`
        INSERT INTO salary_periods (year, month, start_date, end_date)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (year, month) DO NOTHING
      `, [year, month, startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0]]);
    }
    console.log('Inserted current and previous salary periods');
  }

  console.log('Salary tables initialized successfully!');
  process.exit(0);
}

initSalaryTables().catch(err => {
  console.error('Error initializing salary tables:', err);
  process.exit(1);
});
