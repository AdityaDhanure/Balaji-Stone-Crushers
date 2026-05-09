-- Run this SQL in your Neon SQL Editor to create the maintenance_record_parts table

CREATE TABLE IF NOT EXISTS maintenance_record_parts (
  id SERIAL PRIMARY KEY,
  record_id INTEGER REFERENCES maintenance_records(id) ON DELETE CASCADE,
  part_id INTEGER REFERENCES spare_parts(id),
  part_name VARCHAR(200),
  quantity_used INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_maintenance_record_parts_record_id 
ON maintenance_record_parts(record_id);