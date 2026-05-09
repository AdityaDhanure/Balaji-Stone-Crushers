-- Blast Management Tables

-- Main blasts table
CREATE TABLE IF NOT EXISTS blasts (
    id SERIAL PRIMARY KEY,
    blast_number INTEGER NOT NULL,
    blast_type VARCHAR(20) NOT NULL CHECK (blast_type IN ('bore', 'tractor')),
    blast_date DATE NOT NULL,
    feet DECIMAL(10,2) NOT NULL DEFAULT 0,
    rate DECIMAL(10,2) NOT NULL DEFAULT 190,
    royalty DECIMAL(12,2) DEFAULT 0,
    total_expense DECIMAL(12,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed')),
    notes TEXT,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
    updated_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
);

-- Daily trips to/from blast site
CREATE TABLE IF NOT EXISTS blast_trips (
    id SERIAL PRIMARY KEY,
    blast_id INTEGER NOT NULL REFERENCES blasts(id) ON DELETE CASCADE,
    vehicle_id INTEGER,
    vehicle_number VARCHAR(50),
    vehicle_type VARCHAR(30),
    trip_date DATE NOT NULL DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
    trips_count INTEGER NOT NULL DEFAULT 1,
    material_type VARCHAR(30) DEFAULT 'raw_rock',
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
);

-- Blast expenses (royalty, labour, material, etc.)
CREATE TABLE IF NOT EXISTS blast_expenses (
    id SERIAL PRIMARY KEY,
    blast_id INTEGER NOT NULL REFERENCES blasts(id) ON DELETE CASCADE,
    expense_type VARCHAR(50) NOT NULL,
    description TEXT,
    amount DECIMAL(12,2) NOT NULL,
    expense_date DATE NOT NULL DEFAULT ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date),
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
);

-- Common expense types
COMMENT ON COLUMN blast_expenses.expense_type IS 'royalty, labour, material, machinery, diesel, other';
