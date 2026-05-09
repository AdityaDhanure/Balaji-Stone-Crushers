import db from '../config/db.js';

async function migrateExistingData() {
  console.log('Migrating existing production data to snapshots...');

  const result = await db.query(`
    INSERT INTO production_rate_snapshots (production_id, production_rate_per_brass, total_value)
    SELECT 
      dp.id,
      COALESCE(cr.production_rate_per_brass, 0),
      COALESCE(dp.quantity_tons * cr.production_rate_per_brass, 0) + COALESCE(dp.royalty_amount, 0) + COALESCE(dp.transportation_cost, 0)
    FROM daily_production dp
    LEFT JOIN LATERAL (
      SELECT production_rate_per_brass FROM crushing_rates 
      WHERE product_id = dp.product_id AND effective_from <= dp.production_date
      ORDER BY effective_from DESC LIMIT 1
    ) cr ON true
    WHERE NOT EXISTS (
      SELECT 1 FROM production_rate_snapshots s WHERE s.production_id = dp.id
    )
    RETURNING id
  `);

  console.log(`Migrated ${result.rowCount} existing production entries`);

  console.log('Migration completed successfully!');
  process.exit(0);
}

migrateExistingData().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});