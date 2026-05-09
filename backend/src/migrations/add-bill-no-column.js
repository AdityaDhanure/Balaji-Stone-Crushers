import db from '../config/db.js';

async function addBillNoColumn() {
  console.log('Running migration: add bill_no column to invoices...');

  // Add bill_no column (nullable text — user-supplied manual bill number)
  await db.query(`
    ALTER TABLE invoices
    ADD COLUMN IF NOT EXISTS bill_no VARCHAR(100) DEFAULT NULL;
  `);
  console.log('Added bill_no column to invoices table');

  // Create index for fast search
  await db.query(`
    CREATE INDEX IF NOT EXISTS idx_invoices_bill_no ON invoices (bill_no);
  `);
  console.log('Created index on bill_no');

  console.log('Migration completed successfully!');
  process.exit(0);
}

addBillNoColumn().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
