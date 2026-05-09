// One-time migration: add designation column to users table
import '../src/config/env.js';  // ensures dotenv is loaded
import pool from '../config/db.js';

try {
  await pool.query(`
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS designation VARCHAR(100) DEFAULT NULL
  `);
  console.log('✅ migration complete: users.designation column added (or already existed)');
} catch (err) {
  console.error('❌ migration failed:', err.message);
} finally {
  await pool.end();
}
