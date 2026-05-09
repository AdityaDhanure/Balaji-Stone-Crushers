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

  const empCount = await db.query('SELECT COUNT(*) FROM employees');
  if (parseInt(empCount.rows[0].count) === 0) {
    const depts = await db.query('SELECT id, name FROM departments');
    const deptMap = {};
    depts.rows.forEach(d => { deptMap[d.name] = d.id; });

    await db.query(`
      INSERT INTO employees (employee_code, first_name, last_name, phone, department_id, designation, employee_type, salary, date_of_joining) VALUES
        ('EMP-001', 'Ramesh', 'Reddy', '9876543210', ${deptMap['Operations'] || 'NULL'}, 'Site Supervisor', 'permanent', 25000, '2020-01-15'),
        ('EMP-002', 'Krishna', 'Murthy', '9876543211', ${deptMap['Operations'] || 'NULL'}, 'Crusher Operator', 'permanent', 20000, '2020-03-01'),
        ('EMP-003', 'Anjaneyulu', 'Naidu', '9876543212', ${deptMap['Maintenance'] || 'NULL'}, 'Mechanic', 'permanent', 22000, '2020-02-10'),
        ('EMP-004', 'Venkat', 'Rao', '9876543213', ${deptMap['Transport'] || 'NULL'}, 'Driver', 'permanent', 18000, '2020-04-05'),
        ('EMP-005', 'Ravi', 'Kumar', '9876543214', ${deptMap['Administration'] || 'NULL'}, 'Manager', 'permanent', 40000, '2019-06-01')
      ON CONFLICT (employee_code) DO NOTHING;
    `);
    console.log('Inserted sample employees');
  }

  console.log('Employee tables initialized successfully!');
  process.exit(0);
}

initEmployeeTables().catch(err => {
  console.error('Error initializing employee tables:', err);
  process.exit(1);
});
