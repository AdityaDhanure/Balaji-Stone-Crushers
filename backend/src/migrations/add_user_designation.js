// One-time migration: add profile columns to users table
import pool from '../config/db.js';

try {
  await pool.query(`
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS name VARCHAR(100)
  `);
  console.log('✅ users.name column added (or already existed)');

  await pool.query(`
    UPDATE users
    SET name = username
    WHERE name IS NULL OR TRIM(name) = ''
  `);
  console.log('✅ users.name backfilled from username where missing');

  await pool.query(`
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS designation VARCHAR(100) DEFAULT NULL
  `);
  console.log('✅ users.designation column added (or already existed)');

  console.log('✅ migration complete: user profile columns ready');
} catch (err) {
  console.error('❌ migration failed:', err.message);
  process.exit(1);
} finally {
  await pool.end();
}
