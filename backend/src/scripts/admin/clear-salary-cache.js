import { createClient } from 'redis';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

async function clearSalaryCache() {
  let client;
  try {
    client = createClient({ url: REDIS_URL });
    await client.connect();
    console.log('Connected to Redis');

    // Get all salary keys
    const keys = await client.keys('salary:*');
    console.log(`Found ${keys.length} salary cache keys:`, keys);

    if (keys.length > 0) {
      await client.del(keys);
      console.log('Salary cache cleared successfully!');
    } else {
      console.log('No salary cache keys found');
    }

    await client.quit();
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    if (client) await client.quit();
    process.exit(1);
  }
}

clearSalaryCache();
