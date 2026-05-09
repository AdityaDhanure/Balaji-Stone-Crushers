import db from '../../config/db.js';
import bcrypt from 'bcryptjs';

async function initUsersTable() {
  console.log('Initializing users table...');

  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE,
        password VARCHAR(255) NOT NULL,
        phone VARCHAR(20),
        department VARCHAR(100),
        role VARCHAR(50) DEFAULT 'manager',
        is_active BOOLEAN DEFAULT true,
        last_login TIMESTAMP,
        created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
        updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
      );
    `);
    console.log('✅ Created users table');

    // Check if admin exists
    const result = await db.query('SELECT * FROM users WHERE username = $1', ['admin']);
    
    if (result.rows.length === 0) {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      await db.query(`
        INSERT INTO users (username, email, password, phone, department, role)
        VALUES ('admin', 'admin@balaji.com', $1, '9876543210', 'Administration', 'admin')
      `, [hashedPassword]);
      console.log('✅ Created default admin user (username: admin, password: admin123)');
    } else if (result.rows[0].password === 'TEMP_WILL_BE_HASHED') {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      await db.query('UPDATE users SET password = $1 WHERE username = $2', [hashedPassword, 'admin']);
      console.log('✅ Updated admin password');
    }

    console.log('✅ Users table initialized successfully');
  } catch (error) {
    console.error('❌ Error initializing users table:', error.message);
    throw error;
  }
}

initUsersTable();
