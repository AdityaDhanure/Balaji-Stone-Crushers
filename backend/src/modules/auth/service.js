import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../../config/db.js';
import { JWT_SECRET, JWT_EXPIRES_IN } from '../../config/env.js';
import { findUserByUsername, updateLastLogin } from './query.js';

export const loginService = async (username, password) => {

  // 1. Find user
  const result = await pool.query(findUserByUsername, [username]);

  if (result.rows.length === 0) {
    const error = new Error('Invalid username or password');
    error.statusCode = 401;
    throw error;
  }

  const user = result.rows[0];

  // 2. Check password
  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    const error = new Error('Invalid username or password');
    error.statusCode = 401;
    throw error;
  }

  // 3. Update last_login — uses username (guaranteed correct from findUserByUsername lookup)
  const loginUpdate = await pool.query(updateLastLogin, [user.username]);
  if (loginUpdate.rows.length > 0) {
    console.log(`✅ last_login updated for "${user.username}": ${loginUpdate.rows[0].last_login}`);
  } else {
    console.warn(`⚠️  last_login update matched 0 rows for "${user.username}"`);
  }

  // 4. Generate token
  const token = jwt.sign(
    {
      id: user.id,
      username: user.username,
      role: user.role,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );

  return {
    token,
    user: {
      id: user.id,
      name: user.name,
      username: user.username,
      role: user.role,
    },
  };
};

export const createDefaultAdmin = async () => {
  // Check if admin already has hashed password
  const result = await pool.query(findUserByUsername, ['admin']);

  if (result.rows.length > 0 && result.rows[0].password === 'TEMP_WILL_BE_HASHED') {
    const hashed = await bcrypt.hash('admin123', 10);
    await pool.query(
      'UPDATE users SET password = $1 WHERE username = $2',
      [hashed, 'admin']
    );
    console.log('✅ Default admin password set successfully');
  }
};
