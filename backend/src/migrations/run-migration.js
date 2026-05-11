import { spawn } from 'child_process';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const migrationsDir = dirname(fileURLToPath(import.meta.url));

const migrationFiles = [
  'add_email_lastlogin.js',
  'add_user_designation.js',
  'migrate-core-columns.js',
  'migrate-rate-column.js',
  'add-bill-no-column.js',
  'migrate-billing-column.js',
  'migrate-salary-columns.js',
  'init-salary-earnings-table.js',
  'migrate-app-settings-category.js',
  'add-production-snapshot.js',
  'migrate-existing-production.js',
];

function runMigration(file) {
  return new Promise((resolve, reject) => {
    const scriptPath = join(migrationsDir, file);
    console.log(`\n=== Running ${file} ===`);

    const child = spawn(process.execPath, [scriptPath], {
      cwd: join(migrationsDir, '..', '..'),
      stdio: 'inherit',
      env: process.env,
    });

    child.on('error', reject);
    child.on('exit', code => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`${file} failed with exit code ${code}`));
      }
    });
  });
}

async function runAllMigrations() {
  console.log('Running production migrations in dependency order...');

  try {
    for (const file of migrationFiles) {
      await runMigration(file);
    }

    console.log('\nAll migrations completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('\nMigration run failed:', error.message);
    process.exit(1);
  }
}

runAllMigrations();
