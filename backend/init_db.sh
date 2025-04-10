#!/bin/bash

# Load environment variables
source .env

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "Error: DATABASE_URL is not set in .env file"
    exit 1
fi

# Extract database name from URL
DB_NAME=$(echo $DATABASE_URL | sed -E 's/^.*\/([^\/]+)$/\1/')

# Create database if it doesn't exist
psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
    psql -U postgres -c "CREATE DATABASE $DB_NAME"

# Apply schema
psql $DATABASE_URL -f schema.sql

echo "Database initialized successfully!" 