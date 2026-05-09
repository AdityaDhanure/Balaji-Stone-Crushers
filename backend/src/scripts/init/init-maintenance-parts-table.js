import db from '../../config/db.js';

async function initMaintenancePartsTable() {
  console.log('Creating maintenance_record_parts table...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS maintenance_record_parts (
      id SERIAL PRIMARY KEY,
      record_id INTEGER REFERENCES maintenance_records(id) ON DELETE CASCADE,
      part_id INTEGER REFERENCES spare_parts(id),
      part_name VARCHAR(200),
      quantity_used INTEGER NOT NULL DEFAULT 1,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);

  console.log('Created maintenance_record_parts table');

  console.log('Maintenance parts table initialized successfully!');
  process.exit(0);
}

initMaintenancePartsTable().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
