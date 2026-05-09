-- Migration: Add equipment_id and vehicle_id columns to expenses table
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS equipment_id INTEGER;
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS vehicle_id INTEGER;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_expenses_equipment_id ON expenses(equipment_id);
CREATE INDEX IF NOT EXISTS idx_expenses_vehicle_id ON expenses(vehicle_id);