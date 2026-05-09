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
      INSERT INTO app_settings (setting_key, setting_value, description) VALUES
        ('company_name', 'Balaji Stone Crushers', 'Company name'),
        ('company_address', 'Kadapa, Andhra Pradesh', 'Company address'),
        ('company_phone', '9876543210', 'Company contact number'),
        ('company_email', 'info@balajicrushers.com', 'Company email'),
        ('gst_number', '37AAACR1234P1Z5', 'GST Number'),
        ('default_currency', 'INR', 'Default currency'),
        ('invoice_prefix', 'INV', 'Invoice number prefix'),
        ('invoice_footer', 'Thank you for your business!', 'Invoice footer text'),
        ('low_diesel_threshold', '500', 'Low diesel stock alert threshold (liters)'),
        ('vehicle_document_alert_days', '30', 'Days before document expiry to alert')
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
