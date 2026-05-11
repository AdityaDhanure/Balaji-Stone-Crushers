import db from '../../config/db.js';

async function initEmployeeTables() {
  console.log('Initializing employee tables...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS departments (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE,
      description TEXT,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created departments table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS employees (
      id SERIAL PRIMARY KEY,
      employee_code VARCHAR(50) UNIQUE,
      first_name VARCHAR(100) NOT NULL,
      last_name VARCHAR(100),
      email VARCHAR(100),
      phone VARCHAR(20),
      alternate_phone VARCHAR(20),
      date_of_birth DATE,
      date_of_joining DATE NOT NULL,
      date_of_leaving DATE,
      department_id INTEGER REFERENCES departments(id),
      designation VARCHAR(100),
      employee_type VARCHAR(50) DEFAULT 'permanent',
      salary DECIMAL(10, 2) DEFAULT 0,
      aadhaar_number VARCHAR(20),
      pan_number VARCHAR(20),
      bank_account VARCHAR(50),
      bank_name VARCHAR(100),
      ifsc_code VARCHAR(20),
      upi_id VARCHAR(50),
      address TEXT,
      city VARCHAR(100),
      state VARCHAR(100),
      emergency_contact_name VARCHAR(100),
      emergency_contact_phone VARCHAR(20),
      emergency_contact_relation VARCHAR(50),
      is_active BOOLEAN DEFAULT true,
      paid_leave_balance INTEGER DEFAULT 15,
      profile_image VARCHAR(255),
      notes TEXT,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created employees table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS employee_documents (
      id SERIAL PRIMARY KEY,
      employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
      document_type VARCHAR(50) NOT NULL,
      document_number VARCHAR(100),
      issue_date DATE,
      expiry_date DATE,
      file_path VARCHAR(255),
      notes TEXT,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created employee_documents table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS employee_leaves (
      id SERIAL PRIMARY KEY,
      employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
      leave_type VARCHAR(50) NOT NULL,
      start_date DATE NOT NULL,
      end_date DATE NOT NULL,
      total_days INTEGER DEFAULT 1,
      reason TEXT,
      status VARCHAR(50) DEFAULT 'pending',
      approved_by INTEGER REFERENCES users(id),
      approved_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created employee_leaves table');

  const deptCount = await db.query('SELECT COUNT(*) FROM departments');
  if (parseInt(deptCount.rows[0].count) === 0) {
    await db.query(`
      INSERT INTO departments (name, description) VALUES
        ('Operations', 'Day-to-day crushing operations'),
        ('Maintenance', 'Equipment maintenance and repairs'),
        ('Transport', 'Vehicle and transportation'),
        ('Administration', 'Admin and management'),
        ('Accounts', 'Finance and accounting')
      ON CONFLICT (name) DO NOTHING;
    `);
    console.log('Inserted default departments');
  }

  // No demo employees inserted — real employees will be onboarded by the business after go-live.

  console.log('Employee tables initialized successfully!');
  process.exit(0);
}

initEmployeeTables().catch(err => {
  console.error('Error initializing employee tables:', err);
  process.exit(1);
});
