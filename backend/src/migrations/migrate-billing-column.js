import db from '../config/db.js';

async function migrateBillingColumn() {
  console.log('Running billing column migration...');

  await db.query(`
    ALTER TABLE invoice_items 
    RENAME COLUMN rate_per_unit TO selling_rate_per_unit;
  `);
  console.log('Renamed rate_per_unit to selling_rate_per_unit');

  await db.query(`
    ALTER TABLE invoice_items 
    ALTER COLUMN unit SET DEFAULT 'brass';
  `);
  console.log('Updated default unit to brass');

  await db.query(`
    UPDATE invoice_items 
    SET unit = 'brass' 
    WHERE unit = 'tons';
  `);
  console.log('Updated existing units from tons to brass');

  console.log('Migration completed successfully!');
  process.exit(0);
}

migrateBillingColumn().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});