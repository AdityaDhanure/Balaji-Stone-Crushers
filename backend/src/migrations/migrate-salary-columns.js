// Migration: add half_days, sundays columns and fix worked_days type in salary_slips
import db from '../config/db.js';

async function runMigration() {
  try {
    console.log('Connecting to database...');

    // Add half_days column
    console.log('Adding half_days column...');
    await db.query(`
      ALTER TABLE salary_slips 
      ADD COLUMN IF NOT EXISTS half_days INTEGER DEFAULT 0;
    `);
    console.log('half_days column added!');

    // Add sundays column
    console.log('Adding sundays column...');
    await db.query(`
      ALTER TABLE salary_slips 
      ADD COLUMN IF NOT EXISTS sundays INTEGER DEFAULT 0;
    `);
    console.log('sundays column added!');

    // Update worked_days column type if needed
    console.log('Checking worked_days column type...');
    const result = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'salary_slips' AND column_name = 'worked_days';
    `);

    if (result.rows.length > 0 && result.rows[0].data_type !== 'numeric') {
      console.log('Altering worked_days to DECIMAL...');
      await db.query(`
        ALTER TABLE salary_slips 
        ALTER COLUMN worked_days TYPE DECIMAL(5,1);
      `);
      console.log('worked_days type updated!');
    } else {
      console.log('worked_days type is already correct, skipping.');
    }

    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  }
}

runMigration();
