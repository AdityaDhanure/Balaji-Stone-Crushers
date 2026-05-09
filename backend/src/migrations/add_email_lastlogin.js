import '../src/config/env.js';
import pool from '../config/db.js';

try {
  await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(100) UNIQUE`);
  console.log('✅ email column added');

  await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP`);
  console.log('✅ last_login column added');

  // Confirm final columns
  const cols = await pool.query(
    `SELECT column_name FROM information_schema.columns
     WHERE table_name = 'users' ORDER BY ordinal_position`
  );
  console.log('\n📋 Final users columns:', cols.rows.map(r => r.column_name).join(', '));
} catch (err) {
  console.error('❌', err.message);
} finally {
  await pool.end();
}
