import db from '../../config/db.js';

async function initializeBlastTables() {
  try {
    console.log('Creating blast tables...');

    // Create blasts table
    await db.query(`
      CREATE TABLE IF NOT EXISTS blasts (
        id SERIAL PRIMARY KEY,
        blast_number INTEGER NOT NULL,
        blast_type VARCHAR(20) NOT NULL CHECK (blast_type IN ('bore', 'tractor')),
        blast_date DATE NOT NULL,
        feet DECIMAL(10,2) NOT NULL DEFAULT 0,
        rate DECIMAL(10,2) NOT NULL DEFAULT 190,
        total_expense DECIMAL(12,2) DEFAULT 0,
        total_trips INTEGER DEFAULT 0,
        status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed')),
        notes TEXT,
        created_by INTEGER REFERENCES users(id),
        created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
        updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
      )
    `);
    
    // Add total_trips column if not exists
    await db.query(`DO $$ BEGIN ALTER TABLE blasts ADD COLUMN IF NOT EXISTS total_trips INTEGER DEFAULT 0; EXCEPTION WHEN others THEN null; END $$;`);
    console.log('✓ blasts table created');

    // Create blast_trips table
    await db.query(`
      CREATE TABLE IF NOT EXISTS blast_trips (
        id SERIAL PRIMARY KEY,
        blast_id INTEGER NOT NULL REFERENCES blasts(id) ON DELETE CASCADE,
        vehicle_id INTEGER,
        vehicle_number VARCHAR(50),
        vehicle_type VARCHAR(30),
        trip_date DATE NOT NULL DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
        trips_count INTEGER NOT NULL DEFAULT 1,
        material_type VARCHAR(30) DEFAULT 'raw_rock',
        created_by INTEGER REFERENCES users(id),
        created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
      )
    `);
    console.log('✓ blast_trips table created');

    // Create blast_expenses table
    await db.query(`
      CREATE TABLE IF NOT EXISTS blast_expenses (
        id SERIAL PRIMARY KEY,
        blast_id INTEGER NOT NULL REFERENCES blasts(id) ON DELETE CASCADE,
        expense_type VARCHAR(50) NOT NULL,
        description TEXT,
        amount DECIMAL(12,2) NOT NULL,
        expense_date DATE NOT NULL DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
        created_by INTEGER REFERENCES users(id),
        created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
      )
    `);
    console.log('✓ blast_expenses table created');

    // Create indexes
    await db.query(`CREATE INDEX IF NOT EXISTS idx_blasts_date ON blasts(blast_date)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_blasts_status ON blasts(status)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_blast_trips_blast_id ON blast_trips(blast_id)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_blast_trips_date ON blast_trips(trip_date)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_blast_expenses_blast_id ON blast_expenses(blast_id)`);
    console.log('✓ Indexes created');

    console.log('\n✅ All blast tables initialized successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error creating tables:', error);
    process.exit(1);
  }
}

initializeBlastTables();
