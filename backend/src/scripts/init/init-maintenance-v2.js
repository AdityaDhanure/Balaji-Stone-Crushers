import db from '../../config/db.js';

async function initNewTables() {
  console.log('Adding new maintenance tables...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS maintenance_vendors (
      id SERIAL PRIMARY KEY,
      name VARCHAR(200) NOT NULL,
      contact_person VARCHAR(200),
      phone VARCHAR(20),
      email VARCHAR(100),
      address TEXT,
      specialization VARCHAR(200),
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created maintenance_vendors table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS spare_parts (
      id SERIAL PRIMARY KEY,
      part_number VARCHAR(100) UNIQUE NOT NULL,
      name VARCHAR(200) NOT NULL,
      description TEXT,
      category VARCHAR(100),
      unit VARCHAR(20) DEFAULT 'pcs',
      min_stock_level INTEGER DEFAULT 0,
      current_stock INTEGER DEFAULT 0,
      rate_per_unit DECIMAL(10, 2) DEFAULT 0,
      is_active BOOLEAN DEFAULT true,
      is_predefined BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  
  await db.query(`ALTER TABLE spare_parts ADD COLUMN IF NOT EXISTS is_predefined BOOLEAN DEFAULT false;`);
  console.log('Created/Updated spare_parts table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS parts_used (
      id SERIAL PRIMARY KEY,
      maintenance_id INTEGER REFERENCES maintenance_records(id),
      part_id INTEGER REFERENCES spare_parts(id),
      quantity INTEGER NOT NULL,
      rate DECIMAL(10, 2) NOT NULL,
      amount DECIMAL(12, 2) NOT NULL,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created parts_used table');

  // No demo vendors inserted — real vendors will be added by the business after go-live.

  const partCount = await db.query('SELECT COUNT(*) FROM spare_parts WHERE is_predefined = true');
  if (parseInt(partCount.rows[0].count) === 0) {
    await db.query(`
      INSERT INTO spare_parts (part_number, name, description, category, unit, min_stock_level, current_stock, rate_per_unit, is_predefined) VALUES
      -- Transmission & Power Drive
      ('PART-0001', 'V-Belt Set (Jaw Crusher)', 'Full set of V-belts for Jaw Crusher', 'transmission', 'set', 2, 2, 3500, true),
      ('PART-0002', 'V-Belt Set (Cone Crusher)', 'Full set of V-belts for Cone Crusher', 'transmission', 'set', 2, 2, 4200, true),
      ('PART-0003', 'V-Belt Set (SHI Crusher)', 'Full set of V-belts for SHI Crusher', 'transmission', 'set', 2, 2, 4800, true),
      ('PART-0004', 'Motor 10HP', 'Spare motor 10HP for conveyors', 'transmission', 'pc', 1, 1, 15000, true),
      ('PART-0005', 'Motor 20HP', 'Spare motor 20HP for conveyors', 'transmission', 'pc', 1, 1, 28000, true),
      ('PART-0006', 'Motor Pulley', 'Motor side pulley for belt drive', 'transmission', 'pc', 1, 1, 2500, true),
      ('PART-0007', 'Machine Pulley', 'Machine side pulley for belt drive', 'transmission', 'pc', 1, 1, 3000, true),
      ('PART-0008', 'Dumbroo Bush Set', 'Rubber bushes for dumbroon coupling', 'transmission', 'set', 4, 4, 1200, true),
      ('PART-0009', 'Dumbroo Pins', 'Pins for dumbroon coupling', 'transmission', 'pc', 4, 4, 800, true),
      ('PART-0010', 'Gearbox Spare', 'Spare gearbox for main conveyor', 'transmission', 'pc', 1, 1, 45000, true),
      -- Conveyor System Components
      ('PART-0011', 'Conveyor Belt Roll', 'Full roll (100m) of conveyor belt 600mm', 'conveyor', 'roll', 1, 1, 25000, true),
      ('PART-0012', 'Conveyor Belt Roll 800mm', 'Full roll (100m) of conveyor belt 800mm', 'conveyor', 'roll', 1, 1, 32000, true),
      ('PART-0013', 'Carrying Roller', 'Roller for carrying belt support', 'conveyor', 'pc', 20, 20, 450, true),
      ('PART-0014', 'Return Roller', 'Roller for return belt support', 'conveyor', 'pc', 10, 10, 380, true),
      ('PART-0015', 'Impact Roller', 'Roller for hopper loading point', 'conveyor', 'pc', 5, 5, 550, true),
      ('PART-0016', 'Belt Fasteners', 'Box of belt clips/fasteners', 'conveyor', 'box', 10, 10, 600, true),
      -- Machine Wear Parts
      ('PART-0017', 'Screen Mesh 10mm', 'Screen mesh for 10mm output', 'wear', 'pc', 6, 6, 4500, true),
      ('PART-0018', 'Screen Mesh 20mm', 'Screen mesh for 20mm output', 'wear', 'pc', 6, 6, 4200, true),
      ('PART-0019', 'Screen Mesh 40mm', 'Screen mesh for 40mm output', 'wear', 'pc', 4, 4, 3800, true),
      ('PART-0020', 'Jaw Plate Set', 'Fixed and Moving jaw plate set', 'wear', 'set', 1, 1, 18000, true),
      ('PART-0021', 'Blow Bar Set (SHI)', 'Full set of blow bars for SHI crusher', 'wear', 'set', 1, 1, 25000, true),
      ('PART-0022', 'High Tensile Bolt M16', 'M16 high tensile bolts', 'wear', 'pc', 100, 100, 45, true),
      ('PART-0023', 'High Tensile Bolt M20', 'M20 high tensile bolts', 'wear', 'pc', 80, 80, 65, true),
      ('PART-0024', 'High Tensile Bolt M24', 'M24 high tensile bolts', 'wear', 'pc', 50, 50, 90, true),
      -- Maintenance & Electrical
      ('PART-0025', 'Bearing Set (Screen)', 'Bearing set for vibrating screen', 'electrical', 'set', 2, 2, 8500, true),
      ('PART-0026', 'Bearing Set (Crusher)', 'Bearing set for main crusher', 'electrical', 'set', 1, 1, 12000, true),
      ('PART-0027', 'Grease EP-2', 'EP-2 grade grease barrel', 'electrical', 'barrel', 3, 3, 4500, true),
      ('PART-0028', 'Gear Oil EP-90', 'EP-90 gear oil barrel', 'electrical', 'barrel', 2, 2, 3800, true),
      ('PART-0029', 'Gear Oil EP-140', 'EP-140 gear oil barrel', 'electrical', 'barrel', 2, 2, 4200, true),
      ('PART-0030', 'Contactor 10HP', 'Electrical contactor for 10HP motor', 'electrical', 'pc', 2, 2, 1800, true),
      ('PART-0031', 'Contactor 20HP', 'Electrical contactor for 20HP motor', 'electrical', 'pc', 2, 2, 2200, true),
      ('PART-0032', 'Contactor 30HP', 'Electrical contactor for 30HP motor', 'electrical', 'pc', 2, 2, 2800, true)
      ON CONFLICT DO NOTHING;
    `);
    console.log('Inserted predefined parts');
  }

  console.log('New tables initialized successfully!');
  process.exit(0);
}

initNewTables().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
