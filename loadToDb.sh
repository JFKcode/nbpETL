#!/bin/bash

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

DB_USER="${POSTGRES_USER:-postgres}"
DB_NAME="${POSTGRES_DB:-mojabaza}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

export PGPASSWORD="${POSTGRES_PASSWORD}"

CSV_FILE="$SCRIPT_DIR/usd_rates.csv"

if [ ! -f "$CSV_FILE" ]; then
    log "BŁĄD: Plik $CSV_FILE nie istnieje. Uruchom najpierw fetchNbp.sh"
    exit 1
fi

psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" \
    -c "\copy nbp_usd_rates(exchange_date, rate) FROM '$CSV_FILE' DELIMITER ',' CSV HEADER;"

if [ $? -eq 0 ]; then
    log "Sukces! Dane wgrane do bazy PostgreSQL."
    rm -f "$CSV_FILE"
else
    log "BŁĄD podczas ładowania danych do bazy."
    exit 1
fi
