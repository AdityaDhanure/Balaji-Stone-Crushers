import db from '../config/db.js';

async function migrateCoreColumns() {
  console.log('Running migration: core compatibility columns...');

  try {
    await db.query(`
      ALTER TABLE employees
      ADD COLUMN IF NOT EXISTS upi_id VARCHAR(50)
    `);
    console.log('employees.upi_id exists');

    await db.query(`
      ALTER TABLE employees
      ADD COLUMN IF NOT EXISTS paid_leave_balance INTEGER DEFAULT 15
    `);
    console.log('employees.paid_leave_balance exists');

    await db.query(`
      ALTER TABLE crushing_rates
      ADD COLUMN IF NOT EXISTS production_rate_per_brass DECIMAL(10, 2) DEFAULT 0
    `);
    console.log('crushing_rates.production_rate_per_brass exists');

    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration error:', error.message);
    process.exit(1);
  }
}

migrateCoreColumns();
