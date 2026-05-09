import db from '../../config/db.js';

async function initCustomerTables() {
  console.log('Initializing customer tables...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS customers (
      id SERIAL PRIMARY KEY,
      customer_code VARCHAR(50) UNIQUE,
      name VARCHAR(200) NOT NULL,
      customer_type VARCHAR(50) DEFAULT 'individual',
      email VARCHAR(100),
      phone VARCHAR(20),
      alternate_phone VARCHAR(20),
      gst_number VARCHAR(20),
      pan_number VARCHAR(20),
      billing_address TEXT,
      shipping_address TEXT,
      city VARCHAR(100),
      district VARCHAR(100),
      state VARCHAR(100),
      pincode VARCHAR(10),
      credit_limit DECIMAL(12, 2) DEFAULT 0,
      current_balance DECIMAL(12, 2) DEFAULT 0,
      is_active BOOLEAN DEFAULT true,
      notes TEXT,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created customers table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS customer_contacts (
      id SERIAL PRIMARY KEY,
      customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
      contact_name VARCHAR(100) NOT NULL,
      designation VARCHAR(100),
      phone VARCHAR(20),
      email VARCHAR(100),
      is_primary BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created customer_contacts table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS customer_wallets (
      id SERIAL PRIMARY KEY,
      customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
      transaction_type VARCHAR(20) NOT NULL,
      amount DECIMAL(12, 2) NOT NULL,
      payment_mode VARCHAR(50),
      reference_number VARCHAR(100),
      transaction_date DATE DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
      description TEXT,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created customer_wallets table');

  const customerCount = await db.query('SELECT COUNT(*) FROM customers');
  if (parseInt(customerCount.rows[0].count) === 0) {
    await db.query(`
      INSERT INTO customers (customer_code, name, customer_type, phone, city, state) VALUES
        ('CUST-001', 'Ravi Kumar', 'individual', '9876543210', 'Tirupati', 'Andhra Pradesh'),
        ('CUST-002', 'Sri Venkateswara Construction', 'company', '9876543211', 'Chennai', 'Tamil Nadu'),
        ('CUST-003', 'National Highways Authority', 'government', '9876543212', 'New Delhi', 'Delhi'),
        ('CUST-004', 'Anil Reddy', 'individual', '9876543213', 'Bangalore', 'Karnataka'),
        ('CUST-005', 'AP Road Corporation', 'government', '9876543214', 'Vijayawada', 'Andhra Pradesh')
      ON CONFLICT (customer_code) DO NOTHING;
    `);
    console.log('Inserted sample customers');
  }

  console.log('Customer tables initialized successfully!');
  process.exit(0);
}

initCustomerTables().catch(err => {
  console.error('Error initializing customer tables:', err);
  process.exit(1);
});
