import db from '../../config/db.js';

async function initMaintenanceTables() {
  console.log('Initializing maintenance tables...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS equipment (
      id SERIAL PRIMARY KEY,
      name VARCHAR(200) NOT NULL,
      equipment_type VARCHAR(100) DEFAULT 'crusher',
      equipment_phase VARCHAR(50) DEFAULT 'primary',
      code VARCHAR(50) UNIQUE,
      description TEXT,
      purchase_date DATE,
      warranty_expiry DATE,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  
  await db.query(`ALTER TABLE equipment ADD COLUMN IF NOT EXISTS equipment_phase VARCHAR(50) DEFAULT 'primary';`);
  console.log('Created/Updated equipment table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS maintenance_records (
      id SERIAL PRIMARY KEY,
      equipment_id INTEGER REFERENCES equipment(id),
      vehicle_id INTEGER REFERENCES vehicles(id),
      maintenance_type VARCHAR(50) NOT NULL,
      description TEXT NOT NULL,
      maintenance_date DATE DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
      next_due_date DATE,
      cost DECIMAL(12, 2) DEFAULT 0,
      vendor_name VARCHAR(200),
      vendor_phone VARCHAR(20),
      parts_replaced TEXT,
      status VARCHAR(50) DEFAULT 'completed',
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created maintenance_records table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS maintenance_schedule (
      id SERIAL PRIMARY KEY,
      equipment_id INTEGER REFERENCES equipment(id),
      schedule_type VARCHAR(50) NOT NULL,
      description TEXT,
      interval_days INTEGER,
      last_performed DATE,
      next_due DATE,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created maintenance_schedule table');

  const equipmentCount = await db.query('SELECT COUNT(*) FROM equipment');
  if (parseInt(equipmentCount.rows[0].count) === 0) {
    await db.query(`
      INSERT INTO equipment (name, equipment_type, code, description) VALUES
        ('Primary Jaw Crusher', 'crusher', 'CRUSHER-001', 'Main jaw crusher for primary crushing'),
        ('Secondary Cone Crusher', 'crusher', 'CRUSHER-002', 'Cone crusher for secondary crushing'),
        ('VSI Crusher', 'crusher', 'CRUSHER-003', 'Vertical Shaft Impactor for sand making'),
        ('Vibrating Screen', 'screen', 'SCREEN-001', '3-deck vibrating screen'),
        ('Belt Conveyor System', 'conveyor', 'CONV-001', 'Main conveyor belt system'),
        ('Loading Hopper', 'hopper', 'HOPPER-001', 'Primary feeding hopper'),
        ('Diesel Generator', 'generator', 'GEN-001', '500 KVA backup generator')
      ON CONFLICT (code) DO NOTHING;
    `);
    console.log('Inserted sample equipment');
  }

  console.log('Maintenance tables initialized successfully!');
  process.exit(0);
}

initMaintenanceTables().catch(err => {
  console.error('Error initializing maintenance tables:', err);
  process.exit(1);
});
