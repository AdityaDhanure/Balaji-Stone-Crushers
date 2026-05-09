import db from '../../config/db.js';

async function initializeVehicleTables() {
  try {
    console.log('Creating vehicle tables...');

    // Create vehicles table
    await db.query(`
      CREATE TABLE IF NOT EXISTS vehicles (
        id SERIAL PRIMARY KEY,
        vehicle_number VARCHAR(50) NOT NULL UNIQUE,
        vehicle_type VARCHAR(30) NOT NULL,
        owner_name VARCHAR(100),
        insurance_expiry DATE,
        puc_expiry DATE,
        passing_expiry DATE,
        road_tax_expiry DATE,
        rto_emi_amount DECIMAL(10,2) DEFAULT 0,
        rto_emi_due_date DATE,
        odometer_reading DECIMAL(12,2) DEFAULT 0,
        status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance')),
        notes TEXT,
        created_by INTEGER REFERENCES users(id),
        created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
        updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
      )
    `);
    console.log('✓ vehicles table created');

    // Create vehicle_daily_usage table
    await db.query(`
      CREATE TABLE IF NOT EXISTS vehicle_daily_usage (
        id SERIAL PRIMARY KEY,
        vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
        usage_date DATE NOT NULL DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
        purpose VARCHAR(50) NOT NULL,
        location VARCHAR(100),
        trips_count INTEGER DEFAULT 0,
        distance DECIMAL(10,2) DEFAULT 0,
        diesel_consumed DECIMAL(8,2) DEFAULT 0,
        remarks TEXT,
        created_by INTEGER REFERENCES users(id),
        created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
      )
    `);
    console.log('✓ vehicle_daily_usage table created');

    // Create indexes
    await db.query(`CREATE INDEX IF NOT EXISTS idx_vehicles_type ON vehicles(vehicle_type)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_vehicle_usage_vehicle_id ON vehicle_daily_usage(vehicle_id)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_vehicle_usage_date ON vehicle_daily_usage(usage_date)`);
    console.log('✓ Indexes created');

    console.log('\n✅ All vehicle tables initialized successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error creating tables:', error);
    process.exit(1);
  }
}

initializeVehicleTables();
