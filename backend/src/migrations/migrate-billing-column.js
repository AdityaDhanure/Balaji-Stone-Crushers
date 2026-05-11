// Migration: rename rate_per_unit → selling_rate_per_unit, set default unit to 'brass'
// This migration is idempotent — safe to run multiple times.
import db from '../config/db.js';

async function migrateBillingColumn() {
  console.log('Running billing column migration...');

  try {
    // Check if the old column name still exists before attempting rename
    const checkOld = await db.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'invoice_items' AND column_name = 'rate_per_unit'
    `);

    if (checkOld.rows.length > 0) {
      await db.query(`
        ALTER TABLE invoice_items 
        RENAME COLUMN rate_per_unit TO selling_rate_per_unit;
      `);
      console.log('Renamed rate_per_unit to selling_rate_per_unit');
    } else {
      console.log('rate_per_unit column not found — already renamed or migration already applied, skipping rename.');
    }

    // Set default unit to 'brass' (idempotent)
    await db.query(`
      ALTER TABLE invoice_items 
      ALTER COLUMN unit SET DEFAULT 'brass';
    `);
    console.log('Updated default unit to brass');

    // Backfill existing rows that still have 'tons' as unit
    const updated = await db.query(`
      UPDATE invoice_items 
      SET unit = 'brass' 
      WHERE unit = 'tons';
    `);
    console.log(`Updated ${updated.rowCount} existing rows from unit 'tons' to 'brass'`);

    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  }
}

migrateBillingColumn();