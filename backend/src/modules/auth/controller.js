import pool from '../../config/db.js';
import bcrypt from 'bcryptjs';
import { loginService } from './service.js';
import { IST_TIMESTAMP_SQL } from '../../utils/istDateTime.js';

export const login = async (req, res, next) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Username and password are required',
      });
    }

    const data = await loginService(username, password);
    res.status(200).json({ success: true, message: 'Login successful', data });
  } catch (err) {
    next(err);
  }
};

// Returns the full user profile from DB (not just the JWT payload)
export const getMe = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, username, name, email, phone, department, designation, role, last_login, created_at
       FROM users WHERE id = $1`,
      [req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.status(200).json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ── updateProfile ─────────────────────────────────────────────────────────────
// User identity = req.user.id (JWT decoded by protect middleware). [v2]
// Username is NEVER read from the request body — it is read-only.
// Only `name` is required; email/phone/department/designation are optional.
export const updateProfile = async (req, res) => {
  try {
    const { name, email, phone, department, designation } = req.body;

    if (!name || !String(name).trim()) {
      return res.status(400).json({ success: false, message: 'Full name is required' });
    }

    // Convert empty strings → null so COALESCE preserves the existing DB value.
    const toNull = (v) => (v === '' || v == null) ? null : String(v).trim();

    const result = await pool.query(
      `UPDATE users
       SET name        = $1,
           email       = COALESCE($2, email),
           phone       = COALESCE($3, phone),
           department  = COALESCE($4, department),
           designation = COALESCE($5, designation),
           updated_at  = ${IST_TIMESTAMP_SQL}
       WHERE id = $6
       RETURNING id, username, name, email, phone, department, designation, role`,
      [
        String(name).trim(),
        toNull(email),
        toNull(phone),
        toNull(department),
        toNull(designation),
        req.user.id,   // ← from JWT via protect middleware, NOT from req.body
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.status(200).json({ success: true, data: { user: result.rows[0] } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const result = await pool.query('SELECT password FROM users WHERE id = $1', [req.user.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    const isMatch = await bcrypt.compare(currentPassword, result.rows[0].password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Current password is incorrect' });
    }
    const hashed = await bcrypt.hash(newPassword, 10);
    await pool.query(`UPDATE users SET password = $1, updated_at = ${IST_TIMESTAMP_SQL} WHERE id = $2`, [hashed, req.user.id]);
    res.status(200).json({ success: true, message: 'Password changed successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const logout = async (req, res) => {
  res.status(200).json({ success: true, message: 'Logged out successfully' });
};
