import db from '../../config/db.js';

async function initializeDieselTables() {
  try {
    console.log('Creating diesel tables...');

    await db.query(`
      CREATE TABLE IF NOT EXISTS diesel_purchases (
        id SERIAL PRIMARY KEY,
        pump_name VARCHAR(100) NOT NULL,
        quantity DECIMAL(10,2) NOT NULL,
        rate_per_liter DECIMAL(8,2) NOT NULL,
        total_amount DECIMAL(12,2) NOT NULL,
        payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid')),
        purchase_date DATE NOT NULL DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
        remarks TEXT,
        created_by INTEGER REFERENCES users(id),
        created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
      )
    `);
    console.log('✓ diesel_purchases table created');

    await db.query(`
      CREATE TABLE IF NOT EXISTS diesel_consumption (
        id SERIAL PRIMARY KEY,
        vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE SET NULL,
        quantity DECIMAL(10,2) NOT NULL,
        consumption_date DATE NOT NULL DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
        purpose VARCHAR(100),
        remarks TEXT,
        created_by INTEGER REFERENCES users(id),
        created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
      )
    `);
    console.log('✓ diesel_consumption table created');

    await db.query(`CREATE INDEX IF NOT EXISTS idx_diesel_purchases_date ON diesel_purchases(purchase_date)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_diesel_purchases_pump ON diesel_purchases(pump_name)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_diesel_consumption_vehicle ON diesel_consumption(vehicle_id)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_diesel_consumption_date ON diesel_consumption(consumption_date)`);
    console.log('✓ Indexes created');

    console.log('\n✅ All diesel tables initialized successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error creating tables:', error);
    process.exit(1);
  }
}

initializeDieselTables();
