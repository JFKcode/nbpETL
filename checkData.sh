#!/bin/bash

# Skrypt do sprawdzenia danych w bazie PostgreSQL

DB_USER="postgres"
DB_PASSWORD="postgres123"
DB_NAME="mojabaza"
DB_HOST="localhost"

export PGPASSWORD=$DB_PASSWORD

echo "=== Ostatnie 10 rekordów z tabeli nbp_usd_rates ==="
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "SELECT * FROM nbp_usd_rates ORDER BY exchange_date DESC LIMIT 10;"

echo ""
echo "=== Liczba wszystkich rekordów ==="
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "SELECT COUNT(*) as total_records FROM nbp_usd_rates;"
