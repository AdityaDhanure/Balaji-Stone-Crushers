// Load environment variables from .env file
import { config } from 'dotenv';

// Load .env file from parent directory
config({ path: new URL('../../.env', import.meta.url) });

// Server port (default: 5000)
export const PORT = process.env.PORT || 5000;
// Environment mode (development/production)
export const NODE_ENV = process.env.NODE_ENV || 'development';
// PostgreSQL connection string
let DATABASE_URL = process.env.DATABASE_URL || '';
// Clean up the URL - remove sslmode and channel_binding params that cause issues
if (DATABASE_URL) {
  DATABASE_URL = DATABASE_URL.replace(/[?&]sslmode=[^&]*/i, '');
  DATABASE_URL = DATABASE_URL.replace(/[?&]channel_binding=[^&]*/i, '');
  DATABASE_URL = DATABASE_URL.replace(/[?&]$/, '');
}
export { DATABASE_URL };
// Secret key for JWT token signing
export const JWT_SECRET = process.env.JWT_SECRET || 'default_secret_key';
// Token expiration time (default: 7 days)
export const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';