import db from '../config/db.js';

async function migrateRateColumn() {
  console.log('Running migration: normalize crushing_rates selling rate column...');

  try {
    const columnsResult = await db.query(`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_name = 'crushing_rates'
        AND column_name IN ('selling_rate_per_brass', 'rate_per_brass', 'rate_per_ton')
    `);
    const columns = new Set(columnsResult.rows.map(row => row.column_name));

    if (columns.has('selling_rate_per_brass')) {
      console.log('selling_rate_per_brass already exists. No legacy rate migration needed.');
    } else if (columns.has('rate_per_brass')) {
      console.log('Renaming legacy rate_per_brass to selling_rate_per_brass...');
      await db.query(`
        ALTER TABLE crushing_rates RENAME COLUMN rate_per_brass TO selling_rate_per_brass
      `);
      console.log('Column renamed successfully!');
    } else if (columns.has('rate_per_ton')) {
      console.log('Renaming legacy rate_per_ton to selling_rate_per_brass...');
      await db.query(`
        ALTER TABLE crushing_rates RENAME COLUMN rate_per_ton TO selling_rate_per_brass
      `);
      console.log('Column renamed successfully!');
    } else {
      console.log('Adding selling_rate_per_brass column...');
      await db.query(`
        ALTER TABLE crushing_rates ADD COLUMN selling_rate_per_brass DECIMAL(10, 2) DEFAULT 0
      `);
      console.log('Column added successfully!');
    }

    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrateRateColumn();
