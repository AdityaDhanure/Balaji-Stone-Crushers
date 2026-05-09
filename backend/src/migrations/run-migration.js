import db from '../config/db.js';

async function migrate() {
  console.log('Running migration...');
  
  try {
    // Add upi_id column to employees
    const checkUpi = await db.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'employees' AND column_name = 'upi_id'
    `);
    
    if (checkUpi.rows.length === 0) {
      await db.query(`ALTER TABLE employees ADD COLUMN upi_id VARCHAR(50)`);
      console.log('Added upi_id column to employees');
    } else {
      console.log('upi_id column already exists in employees');
    }

    // Add paid_leave_balance column to employees
    const checkLeaveBalance = await db.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'employees' AND column_name = 'paid_leave_balance'
    `);
    
    if (checkLeaveBalance.rows.length === 0) {
      await db.query(`ALTER TABLE employees ADD COLUMN paid_leave_balance INTEGER DEFAULT 15`);
      console.log('Added paid_leave_balance column to employees');
    } else {
      console.log('paid_leave_balance column already exists in employees');
    }

    // Check if column exists
    const check = await db.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'crushing_rates' AND column_name = 'production_rate_per_brass'
    `);
    
    if (check.rows.length === 0) {
      await db.query(`ALTER TABLE crushing_rates ADD COLUMN production_rate_per_brass DECIMAL(10, 2) DEFAULT 0`);
      console.log('Added production_rate_per_brass column');
    } else {
      console.log('Column production_rate_per_brass already exists');
    }

    // Check if rate_per_brass exists and rename it
    const checkOld = await db.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'crushing_rates' AND column_name = 'rate_per_brass'
    `);
    
    if (checkOld.rows.length > 0) {
      await db.query(`ALTER TABLE crushing_rates RENAME COLUMN rate_per_brass TO selling_rate_per_brass`);
      console.log('Renamed rate_per_brass to selling_rate_per_brass');
    } else {
      // Check if selling_rate_per_brass already exists
      const checkNew = await db.query(`
        SELECT column_name FROM information_schema.columns 
        WHERE table_name = 'crushing_rates' AND column_name = 'selling_rate_per_brass'
      `);
      if (checkNew.rows.length === 0) {
        await db.query(`ALTER TABLE crushing_rates ADD COLUMN selling_rate_per_brass DECIMAL(10, 2) NOT NULL DEFAULT 0`);
        console.log('Added selling_rate_per_brass column');
      } else {
        console.log('selling_rate_per_brass already exists');
      }
    }

    console.log('Migration completed successfully!');
  } catch (error) {
    console.error('Migration error:', error.message);
  }
  
  process.exit(0);
}

migrate();