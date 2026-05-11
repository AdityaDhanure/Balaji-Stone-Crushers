import db from '../config/db.js';

const defaultSettings = [
  ['company_name', 'Balaji Stone Crushers', 'company', 'Company name'],
  ['company_address', 'Bhande Gaon, Khultabad, Maharashtra', 'company', 'Company address'],
  ['company_phone', '', 'company', 'Company contact number'],
  ['company_email', '', 'company', 'Company email'],
  ['company_website', '', 'company', 'Company website URL'],
  ['gst_number', '', 'company', 'GST Number'],
  ['company_pan', '', 'company', 'PAN Number'],
  ['company_state_code', '27', 'company', 'State code for GST'],
  ['default_currency', 'INR', 'company', 'Default currency'],
  ['company_bank_name', '', 'company', 'Bank name for invoice payment'],
  ['company_bank_account', '', 'company', 'Bank account number'],
  ['company_bank_ifsc', '', 'company', 'Bank IFSC code'],
  ['invoice_prefix', 'INV', 'invoice', 'Invoice number prefix'],
  ['invoice_footer', 'Thank you for your business!', 'invoice', 'Invoice footer text'],
  ['invoice_terms', 'Payment due within 30 days.', 'invoice', 'Invoice terms and conditions'],
  ['invoice_due_days', '30', 'invoice', 'Default payment due days'],
  ['invoice_tax_rate', '18', 'invoice', 'Default GST/tax rate percentage'],
  ['low_diesel_threshold', '500', 'alert', 'Low diesel stock alert threshold (liters)'],
  ['vehicle_document_alert_days', '30', 'alert', 'Days before document expiry to alert'],
  ['maintenance_alert_days', '7', 'alert', 'Days before scheduled maintenance to alert'],
];

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

  // Apply all category updates atomically — all succeed or all roll back
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    await client.query(`
      UPDATE app_settings SET category = 'company' WHERE setting_key IN (
        'company_name', 'company_address', 'company_phone', 'company_email', 'gst_number', 'default_currency'
      )
    `);

    await client.query(`
      UPDATE app_settings SET category = 'invoice' WHERE setting_key IN (
        'invoice_prefix', 'invoice_footer'
      )
    `);

    await client.query(`
      UPDATE app_settings SET category = 'alert' WHERE setting_key IN (
        'low_diesel_threshold', 'vehicle_document_alert_days'
      )
    `);

    await client.query(`
      UPDATE app_settings SET category = 'system' WHERE category IS NULL OR category = 'general'
    `);

    for (const [key, value, category, description] of defaultSettings) {
      await client.query(`
        INSERT INTO app_settings (setting_key, setting_value, category, description)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (setting_key) DO UPDATE SET
          category = CASE
            WHEN app_settings.category IS NULL OR app_settings.category IN ('general', 'system')
              THEN EXCLUDED.category
            ELSE app_settings.category
          END,
          description = COALESCE(app_settings.description, EXCLUDED.description)
      `, [key, value, category, description]);
    }

    await client.query('COMMIT');
    console.log('Updated existing settings and inserted missing defaults');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  console.log('Migration completed successfully!');
  process.exit(0);
}

migrateAppSettingsColumns().catch(err => {
  console.error('Error migrating app_settings table:', err);
  process.exit(1);
});
