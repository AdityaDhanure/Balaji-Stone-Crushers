import db from '../config/db.js';

async function migrateRateColumn() {
  console.log('Running migration: rename rate_per_ton to rate_per_brass...');

  try {
    const checkOldColumn = await db.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'crushing_rates' AND column_name = 'rate_per_ton'
    `);

    if (checkOldColumn.rows.length > 0) {
      console.log('Renaming rate_per_ton to rate_per_brass...');
      await db.query(`
        ALTER TABLE crushing_rates RENAME COLUMN rate_per_ton TO rate_per_brass
      `);
      console.log('Column renamed successfully!');
    } else {
      const checkNewColumn = await db.query(`
        SELECT column_name FROM information_schema.columns 
        WHERE table_name = 'crushing_rates' AND column_name = 'rate_per_brass'
      `);
      
      if (checkNewColumn.rows.length > 0) {
        console.log('Column rate_per_brass already exists.');
      } else {
        console.log('Adding rate_per_brass column...');
        await db.query(`
          ALTER TABLE crushing_rates ADD COLUMN rate_per_brass DECIMAL(10, 2)
        `);
        console.log('Column added successfully!');
      }
    }

    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrateRateColumn();
