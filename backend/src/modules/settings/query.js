import db from '../../config/db.js';
import { IST_TIMESTAMP_SQL } from '../../utils/istDateTime.js';

export const SETTING_CATEGORIES = {
  COMPANY: 'company',
  INVOICE: 'invoice',
  ALERT: 'alert',
  SYSTEM: 'system',
};

export const DEFAULT_SETTINGS = [
  // ── Company ────────────────────────────────────────────────────────────────
  { key: 'company_name',        value: 'Balaji Stone Crushers',        category: SETTING_CATEGORIES.COMPANY, description: 'Company name' },
  { key: 'company_address',     value: 'Bhande Gaon, Khultabad, Maharashtra',       category: SETTING_CATEGORIES.COMPANY, description: 'Company address' },
  { key: 'company_phone',       value: '9097015050',                   category: SETTING_CATEGORIES.COMPANY, description: 'Company contact number' },
  { key: 'company_email',       value: 'info@balajicrushers.com',      category: SETTING_CATEGORIES.COMPANY, description: 'Company email' },
  { key: 'company_website',     value: '',                             category: SETTING_CATEGORIES.COMPANY, description: 'Company website URL' },
  { key: 'gst_number',          value: '37AAACR1234P1Z5',             category: SETTING_CATEGORIES.COMPANY, description: 'GST Number' },
  { key: 'company_pan',         value: 'ABCD1234F',                             category: SETTING_CATEGORIES.COMPANY, description: 'PAN Number' },
  { key: 'company_state_code',  value: '27',                          category: SETTING_CATEGORIES.COMPANY, description: 'State code for GST (e.g. 27 for Maharashtra)' },
  { key: 'default_currency',    value: 'INR',                         category: SETTING_CATEGORIES.COMPANY, description: 'Default currency' },
  // ── Bank Details ─────────────────────────────────────────────────────────────
  { key: 'company_bank_name',    value: '',                            category: SETTING_CATEGORIES.COMPANY, description: 'Bank name for invoice payment' },
  { key: 'company_bank_account', value: '',                            category: SETTING_CATEGORIES.COMPANY, description: 'Bank account number' },
  { key: 'company_bank_ifsc',    value: '',                            category: SETTING_CATEGORIES.COMPANY, description: 'Bank IFSC code' },
  // ── Invoice ─────────────────────────────────────────────────────────────────
  { key: 'invoice_prefix',       value: 'INV',                         category: SETTING_CATEGORIES.INVOICE, description: 'Invoice number prefix' },
  { key: 'invoice_footer',       value: 'Thank you for your business!',category: SETTING_CATEGORIES.INVOICE, description: 'Invoice footer text' },
  { key: 'invoice_terms',        value: 'Payment due within 30 days.', category: SETTING_CATEGORIES.INVOICE, description: 'Invoice terms & conditions' },
  { key: 'invoice_due_days',     value: '30',                          category: SETTING_CATEGORIES.INVOICE, description: 'Default payment due days' },
  { key: 'invoice_tax_rate',     value: '18',                          category: SETTING_CATEGORIES.INVOICE, description: 'Default GST/tax rate percentage' },
  // ── Alerts ───────────────────────────────────────────────────────────────────
  { key: 'low_diesel_threshold',        value: '500', category: SETTING_CATEGORIES.ALERT, description: 'Low diesel stock alert threshold (liters)' },
  { key: 'vehicle_document_alert_days', value: '30',  category: SETTING_CATEGORIES.ALERT, description: 'Days before vehicle document expiry to alert' },
  { key: 'maintenance_alert_days',      value: '7',   category: SETTING_CATEGORIES.ALERT, description: 'Days before scheduled maintenance to alert' },
];

export const settingsQueries = {
  getAll: async () => {
    const result = await db.query(`
      SELECT id, setting_key, setting_value::text, category, description, updated_at, updated_by
      FROM app_settings
      ORDER BY category, setting_key
    `);
    return result.rows;
  },

  getAllAsMap: async () => {
    const result = await db.query(`
      SELECT setting_key, setting_value::text as setting_value
      FROM app_settings
      ORDER BY setting_key
    `);
    const map = {};
    result.rows.forEach(row => {
      map[row.setting_key] = String(row.setting_value ?? '');
    });
    return map;
  },

  getByKey: async (key) => {
    const result = await db.query(`
      SELECT id, setting_key, setting_value::text, category, description, updated_at, updated_by
      FROM app_settings
      WHERE setting_key = $1
    `, [key]);
    return result.rows[0];
  },

  getByCategory: async (category) => {
    const result = await db.query(`
      SELECT id, setting_key, setting_value::text, category, description, updated_at, updated_by
      FROM app_settings
      WHERE category = $1
      ORDER BY setting_key
    `, [category]);
    return result.rows;
  },

  create: async ({ key, value, category = 'general', description = null, updatedBy = null }) => {
    const result = await db.query(`
      INSERT INTO app_settings (setting_key, setting_value, category, description, updated_by, updated_at)
      VALUES ($1, $2::text, $3, $4, $5, ${IST_TIMESTAMP_SQL})
      ON CONFLICT (setting_key) DO UPDATE SET
        setting_value = $2::text,
        category = COALESCE($3, app_settings.category),
        description = COALESCE($4, app_settings.description),
        updated_by = $5,
        updated_at = ${IST_TIMESTAMP_SQL}
      RETURNING id, setting_key, setting_value::text, category, description, updated_at, updated_by
    `, [key, String(value ?? ''), category, description, updatedBy]);
    return result.rows[0];
  },

  update: async (key, value, updatedBy = null) => {
    const result = await db.query(`
      UPDATE app_settings
      SET setting_value = $2::text, updated_by = $3, updated_at = ${IST_TIMESTAMP_SQL}
      WHERE setting_key = $1
      RETURNING id, setting_key, setting_value::text, category, description, updated_at, updated_by
    `, [key, String(value ?? ''), updatedBy]);
    return result.rows[0];
  },

  bulkUpdate: async (settings, updatedBy = null) => {
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      const results = [];
      for (const { key, value } of settings) {
        const result = await client.query(`
          UPDATE app_settings
          SET setting_value = $2::text, updated_by = $3, updated_at = ${IST_TIMESTAMP_SQL}
          WHERE setting_key = $1
          RETURNING id, setting_key, setting_value::text, category, description, updated_at, updated_by
        `, [key, String(value ?? ''), updatedBy]);
        if (result.rows[0]) {
          results.push(result.rows[0]);
        }
      }
      await client.query('COMMIT');
      return results;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  },

  bulkUpsert: async (settings, updatedBy = null) => {
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      const results = [];
      for (const { key, value, category, description } of settings) {
        const result = await client.query(`
          INSERT INTO app_settings (setting_key, setting_value, category, description, updated_by, updated_at)
          VALUES ($1, $2::text, $3, $4, $5, ${IST_TIMESTAMP_SQL})
          ON CONFLICT (setting_key) DO UPDATE SET
            setting_value = $2::text,
            category = COALESCE($3, app_settings.category),
            description = COALESCE($4, app_settings.description),
            updated_by = $5,
            updated_at = ${IST_TIMESTAMP_SQL}
          RETURNING id, setting_key, setting_value::text, category, description, updated_at, updated_by
        `, [key, String(value ?? ''), category || 'general', description, updatedBy]);
        results.push(result.rows[0]);
      }
      await client.query('COMMIT');
      return results;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  },

  delete: async (key) => {
    const result = await db.query(`
      DELETE FROM app_settings WHERE setting_key = $1 RETURNING id
    `, [key]);
    return result.rowCount > 0;
  },

  exists: async (key) => {
    const result = await db.query(`
      SELECT 1 FROM app_settings WHERE setting_key = $1
    `, [key]);
    return result.rowCount > 0;
  },

  getMissingKeys: async () => {
    const result = await db.query(`
      SELECT defaults.setting_key, s.setting_value, s.category, s.description
      FROM (SELECT unnest($1::text[]) as setting_key) as defaults
      LEFT JOIN app_settings s ON s.setting_key = defaults.setting_key
      WHERE s.setting_key IS NULL
    `, [DEFAULT_SETTINGS.map(s => s.key)]);
    return result.rows;
  },

  initializeDefaults: async () => {
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      for (const setting of DEFAULT_SETTINGS) {
        await client.query(`
          INSERT INTO app_settings (setting_key, setting_value, category, description, updated_at)
          VALUES ($1, $2::text, $3, $4, ${IST_TIMESTAMP_SQL})
          ON CONFLICT (setting_key) DO NOTHING
        `, [setting.key, String(setting.value), setting.category, setting.description]);
      }
      await client.query('COMMIT');
      return true;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  },

  resetToDefaults: async () => {
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      await client.query('DELETE FROM app_settings');
      for (const setting of DEFAULT_SETTINGS) {
        await client.query(`
          INSERT INTO app_settings (setting_key, setting_value, category, description, updated_at)
          VALUES ($1, $2::text, $3, $4, ${IST_TIMESTAMP_SQL})
        `, [setting.key, String(setting.value), setting.category, setting.description]);
      }
      await client.query('COMMIT');
      return true;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  },

  getSettingsWithDefaults: async () => {
    const result = await db.query(`
      SELECT setting_key, setting_value::text, category, description, updated_at, updated_by
      FROM app_settings
      UNION ALL
      SELECT setting_key, setting_value::text, category, description, NULL as updated_at, NULL as updated_by
      FROM (SELECT unnest($1::text[]) as setting_key, unnest($2::text[]) as setting_value,
            unnest($3::text[]) as category, unnest($4::text[]) as description) d
      WHERE NOT EXISTS (SELECT 1 FROM app_settings WHERE app_settings.setting_key = d.setting_key)
      ORDER BY category, setting_key
    `, [
      DEFAULT_SETTINGS.map(s => s.key),
      DEFAULT_SETTINGS.map(s => String(s.value)),
      DEFAULT_SETTINGS.map(s => s.category),
      DEFAULT_SETTINGS.map(s => s.description)
    ]);
    return result.rows;
  },
};
