import db from '../config/db.js';

async function migrateAppSettingsColumns() {
  console.log('Migrating app_settings table...');

  const addCategoryColumn = await db.query(`
    SELECT column_name FROM information_schema.columns
    WHERE table_name = 'app_settings' AND column_name = 'category'
  `);

  if (addCategoryColumn.rows.length === 0) {
    await db.query(`
      ALTER TABLE app_settings ADD COLUMN category VARCHAR(50) DEFAULT 'general'
    `);
    console.log('Added category column');
  } else {
    console.log('Category column already exists');
  }

  const addUpdatedByColumn = await db.query(`
    SELECT column_name FROM information_schema.columns
    WHERE table_name = 'app_settings' AND column_name = 'updated_by'
  `);

  if (addUpdatedByColumn.rows.length === 0) {
    await db.query(`
      ALTER TABLE app_settings ADD COLUMN updated_by INTEGER REFERENCES users(id) ON DELETE SET NULL
    `);
    console.log('Added updated_by column');
  } else {
    console.log('Updated_by column already exists');
  }

  await db.query(`
    UPDATE app_settings SET category = 'company' WHERE setting_key IN (
      'company_name', 'company_address', 'company_phone', 'company_email', 'gst_number', 'default_currency'
    )
  `);

  await db.query(`
    UPDATE app_settings SET category = 'invoice' WHERE setting_key IN (
      'invoice_prefix', 'invoice_footer'
    )
  `);

  await db.query(`
    UPDATE app_settings SET category = 'alert' WHERE setting_key IN (
      'low_diesel_threshold', 'vehicle_document_alert_days'
    )
  `);

  await db.query(`
    UPDATE app_settings SET category = 'system' WHERE category IS NULL OR category = 'general'
  `);

  console.log('Updated existing settings with category values');

  console.log('Migration completed successfully!');
  process.exit(0);
}

migrateAppSettingsColumns().catch(err => {
  console.error('Error migrating app_settings table:', err);
  process.exit(1);
});