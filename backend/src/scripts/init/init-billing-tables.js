import db from '../../config/db.js';

async function initBillingTables() {
  console.log('Initializing billing tables...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS invoices (
      id SERIAL PRIMARY KEY,
      invoice_number VARCHAR(50) UNIQUE NOT NULL,
      bill_no VARCHAR(100) DEFAULT NULL,
      customer_id INTEGER REFERENCES customers(id),
      invoice_date DATE DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
      due_date DATE,
      subtotal DECIMAL(12, 2) DEFAULT 0,
      tax_amount DECIMAL(12, 2) DEFAULT 0,
      discount_amount DECIMAL(12, 2) DEFAULT 0,
      total_amount DECIMAL(12, 2) DEFAULT 0,
      amount_paid DECIMAL(12, 2) DEFAULT 0,
      status VARCHAR(50) DEFAULT 'draft',
      notes TEXT,
      terms TEXT,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created invoices table');

  await db.query(`
    CREATE INDEX IF NOT EXISTS idx_invoices_bill_no ON invoices (bill_no);
  `);
  console.log('Created invoice bill number index');

  await db.query(`
    CREATE TABLE IF NOT EXISTS invoice_items (
      id SERIAL PRIMARY KEY,
      invoice_id INTEGER REFERENCES invoices(id) ON DELETE CASCADE,
      product_id INTEGER REFERENCES products(id),
      description TEXT,
      quantity DECIMAL(10, 2) NOT NULL,
      unit VARCHAR(20) DEFAULT 'brass',
      selling_rate_per_unit DECIMAL(10, 2) NOT NULL,
      amount DECIMAL(12, 2) NOT NULL,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created invoice_items table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS invoice_payments (
      id SERIAL PRIMARY KEY,
      invoice_id INTEGER REFERENCES invoices(id) ON DELETE CASCADE,
      amount DECIMAL(12, 2) NOT NULL,
      payment_mode VARCHAR(50),
      reference_number VARCHAR(100),
      payment_date DATE DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
      notes TEXT,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created invoice_payments table');

  console.log('Billing tables initialized successfully!');
  process.exit(0);
}

initBillingTables().catch(err => {
  console.error('Error initializing billing tables:', err);
  process.exit(1);
});
