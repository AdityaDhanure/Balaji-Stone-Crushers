import db from '../config/db.js';

async function initSalaryEarningsTable() {
  console.log('Running migration: salary_earnings table...');

  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS salary_earnings (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        type VARCHAR(50) NOT NULL DEFAULT 'other',
        calculation_type VARCHAR(20) NOT NULL DEFAULT 'percentage',
        value DECIMAL(10,4) NOT NULL DEFAULT 0,
        is_active BOOLEAN NOT NULL DEFAULT true,
        description TEXT,
        created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
      );
    `);
    console.log('salary_earnings table exists');

    const earningCount = await db.query('SELECT COUNT(*) FROM salary_earnings');
    if (parseInt(earningCount.rows[0].count) === 0) {
      await db.query(`
        INSERT INTO salary_earnings (name, type, calculation_type, value, description) VALUES
          ('House Rent Allowance (HRA)', 'hra', 'percentage', 10, 'HRA = 10% of basic salary'),
          ('House Allowance', 'allowance', 'percentage', 5, 'House allowance = 5% of basic salary')
        ON CONFLICT DO NOTHING;
      `);
      console.log('Inserted default earnings');
    } else {
      console.log('salary_earnings already has rows; skipping default seed');
    }

    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  }
}

initSalaryEarningsTable();
