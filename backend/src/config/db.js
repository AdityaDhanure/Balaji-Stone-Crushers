import { Pool } from 'pg';
import { DATABASE_URL } from './env.js';

// Parse the connection string to handle special characters in password
let poolConfig = {};

if (DATABASE_URL) {
  // Use the URL constructor to properly parse the connection string
  try {
    const url = new URL(DATABASE_URL);
    
    poolConfig = {
      host: url.hostname,
      port: parseInt(url.port || '5432'),
      database: url.pathname.slice(1), // Remove leading slash
      user: url.username,
      password: url.password, // This properly handles special characters
      ssl: { rejectUnauthorized: false },
    };
  } catch (err) {
    console.error('Failed to parse DATABASE_URL:', err.message);
    // Fallback to connectionString approach
    poolConfig = {
      connectionString: DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    };
  }
}

export const pool = new Pool(poolConfig);

// Verify database connectivity
export const checkDatabaseConnection = async () => {
  try {
    const client = await pool.connect();
    client.release();
    return true;
  } catch (err) {
    console.error('Database connection error:', err.message);
    return false;
  }
};

export default pool;
