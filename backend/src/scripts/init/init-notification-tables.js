import db from '../../config/db.js';

async function initNotificationTables() {
  console.log('Initializing notification tables...');

  await db.query(`
    CREATE TABLE IF NOT EXISTS notifications (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      title VARCHAR(200) NOT NULL,
      message TEXT NOT NULL,
      type VARCHAR(50) DEFAULT 'info',
      is_read BOOLEAN DEFAULT false,
      data JSONB,
      created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
    );
  `);
  console.log('Created notifications table');

await db.query(`
  CREATE TABLE IF NOT EXISTS app_settings (
  id SERIAL PRIMARY KEY,
  setting_key VARCHAR(100) UNIQUE NOT NULL,
  setting_value TEXT,
  category VARCHAR(50) DEFAULT 'general',
  description TEXT,
  updated_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
);
`);
  console.log('Created app_settings table');

  const settingsCount = await db.query('SELECT COUNT(*) FROM app_settings');
  if (parseInt(settingsCount.rows[0].count) === 0) {
    await db.query(`
      INSERT INTO app_settings (setting_key, setting_value, category, description) VALUES
        ('company_name', 'Balaji Stone Crushers', 'company', 'Company name'),
        ('company_address', 'Bhande Gaon, Khultabad, Maharashtra', 'company', 'Company address'),
        ('company_phone', '', 'company', 'Company contact number'),
        ('company_email', '', 'company', 'Company email'),
        ('company_website', '', 'company', 'Company website URL'),
        ('gst_number', '', 'company', 'GST Number'),
        ('company_pan', '', 'company', 'PAN Number'),
        ('company_state_code', '27', 'company', 'State code for GST'),
        ('default_currency', 'INR', 'company', 'Default currency'),
        ('company_bank_name', '', 'company', 'Bank name for invoice payment'),
        ('company_bank_account', '', 'company', 'Bank account number'),
        ('company_bank_ifsc', '', 'company', 'Bank IFSC code'),
        ('invoice_prefix', 'INV', 'invoice', 'Invoice number prefix'),
        ('invoice_footer', 'Thank you for your business!', 'invoice', 'Invoice footer text'),
        ('invoice_terms', 'Payment due within 30 days.', 'invoice', 'Invoice terms and conditions'),
        ('invoice_due_days', '30', 'invoice', 'Default payment due days'),
        ('invoice_tax_rate', '18', 'invoice', 'Default GST/tax rate percentage'),
        ('low_diesel_threshold', '500', 'alert', 'Low diesel stock alert threshold (liters)'),
        ('vehicle_document_alert_days', '30', 'alert', 'Days before document expiry to alert'),
        ('maintenance_alert_days', '7', 'alert', 'Days before scheduled maintenance to alert')
      ON CONFLICT (setting_key) DO NOTHING;
    `);
    console.log('Inserted default settings');
  }

  console.log('Notification tables initialized successfully!');
  process.exit(0);
}

initNotificationTables().catch(err => {
  console.error('Error initializing notification tables:', err);
  process.exit(1);
});
