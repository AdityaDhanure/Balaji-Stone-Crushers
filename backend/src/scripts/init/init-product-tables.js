import db from '../../config/db.js';

async function initProductTables() {
  console.log('Initializing product tables...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS product_categories (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE,
      description TEXT,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created product_categories table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS products (
      id SERIAL PRIMARY KEY,
      product_code VARCHAR(50) UNIQUE,
      name VARCHAR(100) NOT NULL,
      category_id INTEGER REFERENCES product_categories(id),
      size_mm INTEGER,
      description TEXT,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created products table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS crushing_rates (
      id SERIAL PRIMARY KEY,
      product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
      selling_rate_per_brass DECIMAL(10, 2) NOT NULL,
      production_rate_per_brass DECIMAL(10, 2) DEFAULT 0,
      effective_from DATE DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
      effective_to DATE,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created crushing_rates table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS daily_production (
      id SERIAL PRIMARY KEY,
      production_date DATE NOT NULL,
      product_id INTEGER REFERENCES products(id),
      quantity_tons DECIMAL(10, 2) NOT NULL,
      royalty_amount DECIMAL(10, 2) DEFAULT 0,
      transportation_cost DECIMAL(10, 2) DEFAULT 0,
      notes TEXT,
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
      updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created daily_production table');

  await db.query(`
    CREATE TABLE IF NOT EXISTS production_rate_snapshots (
      id SERIAL PRIMARY KEY,
      production_id INTEGER REFERENCES daily_production(id) ON DELETE CASCADE,
      production_rate_per_brass DECIMAL(10, 2) NOT NULL,
      total_value DECIMAL(10, 2) NOT NULL,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created production_rate_snapshots table');

  const categoryCount = await db.query('SELECT COUNT(*) FROM product_categories');
  if (parseInt(categoryCount.rows[0].count) === 0) {
    await db.query(`
      INSERT INTO product_categories (name, description) VALUES
        ('Aggregates', 'Crushed stone aggregates'),
        ('Dust', 'Stone dust and powder'),
        ('Granular Sub Base (GSB)', 'Road construction material'),
        ('Railway Ballast', 'Railway track base material')
      ON CONFLICT (name) DO NOTHING;
    `);
    console.log('Inserted default product categories');
  }

  const productCount = await db.query('SELECT COUNT(*) FROM products');
  if (parseInt(productCount.rows[0].count) === 0) {
    const categories = await db.query('SELECT id, name FROM product_categories');
    const categoryMap = {};
    categories.rows.forEach(c => { categoryMap[c.name] = c.id; });

    await db.query(`
      INSERT INTO products (product_code, name, category_id, size_mm, description) VALUES
        ('AGG-40', '40mm Aggregates', ${categoryMap['Aggregates'] || 'NULL'}, 40, '40mm crushed stone aggregates'),
        ('AGG-20', '20mm Aggregates', ${categoryMap['Aggregates'] || 'NULL'}, 20, '20mm crushed stone aggregates'),
        ('AGG-10', '10mm Aggregates', ${categoryMap['Aggregates'] || 'NULL'}, 10, '10mm crushed stone aggregates'),
        ('AGG-6', '6mm Aggregates', ${categoryMap['Aggregates'] || 'NULL'}, 6, '6mm crushed stone aggregates'),
        ('DUST-S', 'Stone Dust', ${categoryMap['Dust'] || 'NULL'}, 0, 'Fine stone dust'),
        ('GSB-40', 'GSB Material', ${categoryMap['Granular Sub Base (GSB)'] || 'NULL'}, 40, 'Granular Sub Base for road construction')
      ON CONFLICT (product_code) DO NOTHING;
    `);
    console.log('Inserted default products');
  }

  // No default rates inserted — selling and production rates must be configured
  // by the business through the app after go-live.

  console.log('Product tables initialized successfully!');
  process.exit(0);
}

initProductTables().catch(err => {
  console.error('Error initializing product tables:', err);
  process.exit(1);
});
