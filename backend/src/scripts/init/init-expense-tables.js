import db from '../../config/db.js';

async function initExpenseTables() {
  console.log('Initializing expense tables...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS expense_categories (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE,
      description TEXT,
      icon VARCHAR(50),
      color VARCHAR(20),
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created expense_categories table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS expenses (
      id SERIAL PRIMARY KEY,
      expense_number VARCHAR(50) UNIQUE,
      category_id INTEGER REFERENCES expense_categories(id),
      expense_date DATE NOT NULL,
      amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
      payment_mode VARCHAR(50) DEFAULT 'cash',
      vendor_name VARCHAR(200),
      description TEXT,
      reference_number VARCHAR(100),
      receipt_path VARCHAR(255),
      is_recurring BOOLEAN DEFAULT false,
      recurring_frequency VARCHAR(20),
      status VARCHAR(50) DEFAULT 'approved',
      approved_by INTEGER REFERENCES users(id),
      approved_at TIMESTAMP,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created expenses table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS expense_recurring (
      id SERIAL PRIMARY KEY,
      category_id INTEGER REFERENCES expense_categories(id),
      description VARCHAR(200) NOT NULL,
      amount DECIMAL(12, 2) NOT NULL,
      frequency VARCHAR(20) DEFAULT 'monthly',
      start_date DATE NOT NULL,
      end_date DATE,
      is_active BOOLEAN DEFAULT true,
      last_generated_date DATE,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created expense_recurring table');

  const catCount = await db.query('SELECT COUNT(*) FROM expense_categories');
  if (parseInt(catCount.rows[0].count) === 0) {
    await db.query(`
      INSERT INTO expense_categories (name, description, icon, color) VALUES
        ('Site Operations', 'Site-related expenses', 'construction', '#FF5722'),
        ('Electricity Bill', 'Electricity and power expenses', 'bolt', '#FFC107'),
        ('Fuel & Diesel', 'Fuel and diesel expenses', 'local_gas_station', '#795548'),
        ('Repairs & Maintenance', 'Equipment and vehicle repairs', 'build', '#9C27B0'),
        ('Office Supplies', 'Stationery and office items', 'business_center', '#2196F3'),
        ('Salary Advances', 'Employee salary advances', 'payments', '#4CAF50'),
        ('Insurance', 'Insurance premiums', 'security', '#607D8B'),
        ('Rent', 'Rental payments', 'home', '#E91E63'),
        ('Phone & Internet', 'Communication expenses', 'phone', '#00BCD4'),
        ('Royalty', 'Government royalty and mining levy payments', 'account_balance', '#9C27B0'),
        ('Miscellaneous', 'Other expenses', 'more_horiz', '#9E9E9E')
      ON CONFLICT (name) DO NOTHING;
    `);
    console.log('Inserted default expense categories');
  }

  console.log('Expense tables initialized successfully!');
  process.exit(0);
}

initExpenseTables().catch(err => {
  console.error('Error initializing expense tables:', err);
  process.exit(1);
});
