#!/bin/bash

# Dane połączenia z bazą PostgreSQL (Docker)
DB_USER="postgres"
DB_PASSWORD="postgres123"
DB_NAME="mojabaza"
DB_HOST="localhost"

# Eksportujemy hasło, aby psql nie pytał o nie
export PGPASSWORD=$DB_PASSWORD

# Ścieżka do pliku CSV
CSV_FILE="$(pwd)/usd_rates.csv"

# Sprawdzamy czy plik CSV istnieje
if [ ! -f "$CSV_FILE" ]; then
    echo "Błąd: Plik $CSV_FILE nie istnieje. Uruchom najpierw fetchNbp.sh"
    exit 1
fi

# Komenda psql z flagą \copy do importu z pliku CSV
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "\copy nbp_usd_rates(exchange_date, rate) FROM '$CSV_FILE' DELIMITER ',' CSV HEADER;"

if [ $? -eq 0 ]; then
    echo "Sukces! Dane wgrane do bazy PostgreSQL."
else
    echo "Błąd podczas ładowania danych do bazy."
    exit 1
fi

echo "Dane wgrane do bazy!"