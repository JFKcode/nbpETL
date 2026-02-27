#!/bin/bash

# ===========================================
# Ładowanie wielu walut do PostgreSQL
# ===========================================

# Dane połączenia z bazą PostgreSQL
DB_USER="postgres"
DB_PASSWORD="postgres123"
DB_NAME="mojabaza"
DB_HOST="localhost"

export PGPASSWORD=$DB_PASSWORD

CSV_FILE="$(pwd)/rates.csv"

# Sprawdź czy plik istnieje
if [ ! -f "$CSV_FILE" ]; then
    echo "Błąd: Plik $CSV_FILE nie istnieje."
    echo "Uruchom najpierw: bash fetchMultiCurrency.sh"
    exit 1
fi

echo "Ładowanie danych do PostgreSQL..."

# Użyj tymczasowej tabeli do upsert (INSERT ... ON CONFLICT)
psql -U $DB_USER -h $DB_HOST -d $DB_NAME <<EOF
-- Tworzymy tabelę tymczasową
CREATE TEMP TABLE temp_rates (
    currency_code VARCHAR(3),
    currency_name VARCHAR(50),
    exchange_date DATE,
    rate NUMERIC(10,4)
);

-- Ładujemy CSV do tabeli tymczasowej
\copy temp_rates FROM '$CSV_FILE' DELIMITER ',' CSV HEADER;

-- Wstawiamy dane z obsługą konfliktów (upsert)
INSERT INTO nbp_rates (currency_code, currency_name, exchange_date, rate)
SELECT currency_code, currency_name, exchange_date, rate FROM temp_rates
ON CONFLICT (currency_code, exchange_date) 
DO UPDATE SET rate = EXCLUDED.rate, currency_name = EXCLUDED.currency_name;

-- Zliczamy wstawione rekordy
SELECT 'Załadowano ' || COUNT(*) || ' rekordów' as status FROM temp_rates;
EOF

if [ $? -eq 0 ]; then
    echo "Sukces! Dane wgrane do bazy."
else
    echo "Błąd podczas ładowania danych."
    exit 1
fi
