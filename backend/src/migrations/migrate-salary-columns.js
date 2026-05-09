import pg from 'pg';
const { Pool } = pg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://neondb_owner:npg_CSTxydf97hwV@ep-frosty-hat-a1b4bvqk-pooler.ap-southeast-1.aws.neon.tech/balaji-crushers?sslmode=require',
  ssl: { rejectUnauthorized: false }
});

async function runMigration() {
  try {
    console.log('Connecting to database...');
    
    // Add half_days column
    console.log('Adding half_days column...');
    await pool.query(`
      ALTER TABLE salary_slips 
      ADD COLUMN IF NOT EXISTS half_days INTEGER DEFAULT 0;
    `);
    console.log('half_days column added!');
    
    // Add sundays column
    console.log('Adding sundays column...');
    await pool.query(`
      ALTER TABLE salary_slips 
      ADD COLUMN IF NOT EXISTS sundays INTEGER DEFAULT 0;
    `);
    console.log('sundays column added!');
    
    // Update worked_days column type if needed
    console.log('Checking worked_days column type...');
    const result = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'salary_slips' AND column_name = 'worked_days';
    `);
    
    if (result.rows.length > 0) {
      console.log('Current worked_days type:', result.rows[0].data_type);
      if (result.rows[0].data_type !== 'numeric') {
        console.log('Altering worked_days to DECIMAL...');
        await pool.query(`
          ALTER TABLE salary_slips 
          ALTER COLUMN worked_days TYPE DECIMAL(5,1);
        `);
        console.log('worked_days type updated!');
      }
    }
    
    console.log('Migration completed successfully!');
    await pool.end();
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err.message);
    await pool.end();
    process.exit(1);
  }
}

runMigration();
