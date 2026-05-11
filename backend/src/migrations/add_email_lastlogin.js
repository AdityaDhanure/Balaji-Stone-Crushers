// One-time migration: add email and last_login columns to users table
import pool from '../config/db.js';

try {
  await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(100) UNIQUE`);
  console.log('✅ email column added (or already existed)');

  await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP`);
  console.log('✅ last_login column added (or already existed)');

  console.log('Migration completed successfully!');
} catch (err) {
  console.error('❌ Migration failed:', err.message);
  process.exit(1);
} finally {
  await pool.end();
}
