#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Załaduj zmienne środowiskowe z .env
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

DB_USER="${POSTGRES_USER:-postgres}"
DB_NAME="${POSTGRES_DB:-mojabaza}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

export PGPASSWORD="${POSTGRES_PASSWORD}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║           DANE W BAZIE POSTGRESQL                         ║"
echo "╚════════════════════════════════════════════════════════════╝"

echo ""
echo "═══ Tabela: nbp_rates (wszystkie waluty) ═══"
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" \
    -c "SELECT currency_code, currency_name, exchange_date, rate FROM nbp_rates ORDER BY exchange_date DESC, currency_code LIMIT 20;"

echo ""
echo "═══ Podsumowanie dla każdej waluty ═══"
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -c "
SELECT
    currency_code as waluta,
    COUNT(*) as dni,
    MIN(rate) as min_kurs,
    MAX(rate) as max_kurs,
    ROUND(AVG(rate), 4) as sredni_kurs
FROM nbp_rates
GROUP BY currency_code
ORDER BY currency_code;"

echo ""
echo "═══ Łączna liczba rekordów ═══"
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" \
    -c "SELECT COUNT(*) as rekordy FROM nbp_rates;"
