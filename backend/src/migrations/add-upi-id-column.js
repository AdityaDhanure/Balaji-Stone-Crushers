import db from '../config/db.js';

async function addUpiIdColumn() {
  console.log('Adding upi_id column to employees table...');
  
  try {
    await db.query(`
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS upi_id VARCHAR(50);
    `);
    console.log('upi_id column added successfully!');
  } catch (err) {
    if (err.message.includes('already exists')) {
      console.log('upi_id column already exists');
    } else {
      console.error('Error:', err.message);
    }
  }
  
  process.exit(0);
}

addUpiIdColumn();