-- Create health_data table
CREATE TABLE IF NOT EXISTS health_data (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    pregnancy_month INTEGER,
    due_date TEXT,
    weight TEXT,
    height TEXT,
    systolic_bp TEXT,
    diastolic_bp TEXT,
    temperature TEXT,
    hemoglobin TEXT,
    glucose TEXT,
    symptoms TEXT,
    dietary_log TEXT,
    physical_activity TEXT,
    supplements TEXT,
    mood_rating FLOAT,
    has_anxiety BOOLEAN,
    anxiety_level FLOAT
);

-- Create health_alerts table
CREATE TABLE IF NOT EXISTS health_alerts (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    severity INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    is_read BOOLEAN DEFAULT false
);

-- Create reminders table
CREATE TABLE IF NOT EXISTS reminders (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    reminder_type INTEGER NOT NULL,
    date TEXT NOT NULL,
    time TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
); 