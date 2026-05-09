import db from '../config/db.js';

async function migrate() {
  console.log('Running migration to add production_rate_per_brass column...');
  
  try {
    await db.query(`
      ALTER TABLE crushing_rates 
      ADD COLUMN IF NOT EXISTS production_rate_per_brass DECIMAL(10, 2) DEFAULT 0
    `);
    console.log('Column production_rate_per_brass added successfully!');
  } catch (error) {
    console.error('Migration error:', error.message);
  }
  
  process.exit(0);
}

migrate();