import db from '../../config/db.js';

async function initAttendanceTables() {
  console.log('Initializing attendance tables...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS attendance (
      id SERIAL PRIMARY KEY,
      employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
      date DATE NOT NULL,
      check_in TIME,
      check_out TIME,
      status VARCHAR(50) DEFAULT 'present',
      overtime_hours DECIMAL(4, 2) DEFAULT 0,
      late_hours DECIMAL(4, 2) DEFAULT 0,
      notes TEXT,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      UNIQUE(employee_id, date)
    );
  `);
  console.log('Created attendance table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS shift_types (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      start_time TIME NOT NULL,
      end_time TIME NOT NULL,
      grace_minutes INTEGER DEFAULT 15,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created shift_types table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS employee_shifts (
      id SERIAL PRIMARY KEY,
      employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
      shift_type_id INTEGER REFERENCES shift_types(id),
      effective_from DATE NOT NULL,
      effective_to DATE,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created employee_shifts table');

  const shiftCount = await db.query('SELECT COUNT(*) FROM shift_types');
  if (parseInt(shiftCount.rows[0].count) === 0) {
    await db.query(`
      INSERT INTO shift_types (name, start_time, end_time, grace_minutes) VALUES
        ('Morning Shift', '08:00:00', '17:00:00', 15),
        ('Night Shift', '20:00:00', '05:00:00', 15),
        ('General Shift', '09:00:00', '18:00:00', 30)
      ON CONFLICT DO NOTHING;
    `);
    console.log('Inserted default shift types');
  }

  console.log('Attendance tables initialized successfully!');
  process.exit(0);
}

initAttendanceTables().catch(err => {
  console.error('Error initializing attendance tables:', err);
  process.exit(1);
});
