import db from '../config/db.js';

async function addProductionRateSnapshot() {
  console.log('Adding production rate snapshot table...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS production_rate_snapshots (
      id SERIAL PRIMARY KEY,
      production_id INTEGER REFERENCES daily_production(id) ON DELETE CASCADE,
      production_rate_per_brass DECIMAL(10, 2) NOT NULL,
      total_value DECIMAL(10, 2) NOT NULL,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created production_rate_snapshots table');

  console.log('Migration completed successfully!');
  process.exit(0);
}

addProductionRateSnapshot().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
