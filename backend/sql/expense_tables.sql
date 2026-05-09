-- Expense Categories Table
CREATE TABLE IF NOT EXISTS expense_categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  icon VARCHAR(50),
  color VARCHAR(20),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
);

-- Expenses Table
CREATE TABLE IF NOT EXISTS expenses (
  id SERIAL PRIMARY KEY,
  expense_number VARCHAR(20) UNIQUE NOT NULL,
  category_id INTEGER REFERENCES expense_categories(id),
  expense_date DATE NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  payment_mode VARCHAR(20) DEFAULT 'cash',
  vendor_name VARCHAR(100),
  description TEXT,
  reference_number VARCHAR(50),
  receipt_path VARCHAR(255),
  is_recurring BOOLEAN DEFAULT false,
  recurring_frequency VARCHAR(20),
  status VARCHAR(20) DEFAULT 'approved',
  approved_by INTEGER,
  approved_at TIMESTAMP,
  created_by INTEGER,
  created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
  updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
  equipment_id INTEGER,
  vehicle_id INTEGER
);

-- Insert default categories if not exist
INSERT INTO expense_categories (name, description, icon, color) VALUES 
  ('Maintenance', 'Equipment and machinery repairs', 'build', '#FF9800'),
  ('Electricity', 'Electricity bills and electrical work', 'bolt', '#FFC107'),
  ('Fuel', 'Fuel and diesel expenses', 'local_gas_station', '#4CAF50'),
  ('Rent', 'Office or site rent', 'home', '#2196F3'),
  ('Salaries', 'Staff salary payments', 'payments', '#9C27B0'),
  ('Office Supplies', 'Stationery and office items', 'business_center', '#00BCD4'),
  ('Security', 'Security services', 'security', '#607D8B'),
  ('Miscellaneous', 'Other expenses', 'more_horiz', '#795548')
ON CONFLICT (name) DO NOTHING;
