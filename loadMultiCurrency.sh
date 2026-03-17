#!/bin/bash

# ===========================================
# Ładowanie wielu walut do PostgreSQL
# ===========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Załaduj zmienne środowiskowe z .env
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

# Konfiguracja logowania
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/etl_$(date +%Y-%m-%d).log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Dane połączenia z bazą PostgreSQL
DB_USER="${POSTGRES_USER:-postgres}"
DB_NAME="${POSTGRES_DB:-mojabaza}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

export PGPASSWORD="${POSTGRES_PASSWORD}"

CSV_FILE="$SCRIPT_DIR/rates.csv"

if [ ! -f "$CSV_FILE" ]; then
    log "BŁĄD: Plik $CSV_FILE nie istnieje. Uruchom najpierw: bash fetchMultiCurrency.sh"
    exit 1
fi

log "Ładowanie danych do PostgreSQL..."

psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" <<EOF
CREATE TEMP TABLE temp_rates (
    currency_code VARCHAR(3),
    currency_name VARCHAR(50),
    exchange_date DATE,
    rate NUMERIC(10,4)
);

\copy temp_rates FROM '$CSV_FILE' DELIMITER ',' CSV HEADER;

INSERT INTO nbp_rates (currency_code, currency_name, exchange_date, rate)
SELECT currency_code, currency_name, exchange_date, rate FROM temp_rates
ON CONFLICT (currency_code, exchange_date)
DO UPDATE SET rate = EXCLUDED.rate, currency_name = EXCLUDED.currency_name;

SELECT 'Załadowano ' || COUNT(*) || ' rekordów' as status FROM temp_rates;
EOF

if [ $? -eq 0 ]; then
    log "Sukces! Dane wgrane do bazy."
    # Usuń plik CSV po załadowaniu - następny fetch stworzy go od nowa
    rm -f "$CSV_FILE"
else
    log "BŁĄD podczas ładowania danych."
    exit 1
fi
