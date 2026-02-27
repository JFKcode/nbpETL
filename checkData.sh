#!/bin/bash

# Skrypt do sprawdzenia danych w bazie PostgreSQL

DB_USER="postgres"
DB_PASSWORD="postgres123"
DB_NAME="mojabaza"
DB_HOST="localhost"

export PGPASSWORD=$DB_PASSWORD

echo "╔════════════════════════════════════════════════════════════╗"
echo "║           DANE W BAZIE POSTGRESQL                         ║"
echo "╚════════════════════════════════════════════════════════════╝"

echo ""
echo "═══ Tabela: nbp_usd_rates (tylko USD) ═══"
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "SELECT * FROM nbp_usd_rates ORDER BY exchange_date DESC LIMIT 5;"

echo ""
echo "═══ Tabela: nbp_rates (wszystkie waluty) ═══"
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "SELECT currency_code, currency_name, exchange_date, rate FROM nbp_rates ORDER BY exchange_date DESC, currency_code LIMIT 20;" 2>/dev/null || echo "(tabela jeszcze nie istnieje)"

echo ""
echo "═══ Podsumowanie dla każdej waluty ═══"
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "
SELECT 
    currency_code as waluta,
    COUNT(*) as dni,
    MIN(rate) as min_kurs,
    MAX(rate) as max_kurs,
    ROUND(AVG(rate), 4) as sredni_kurs
FROM nbp_rates 
GROUP BY currency_code 
ORDER BY currency_code;
" 2>/dev/null || echo "(brak danych)"

echo ""
echo "═══ Łączna liczba rekordów ═══"
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "SELECT 'nbp_usd_rates' as tabela, COUNT(*) as rekordy FROM nbp_usd_rates UNION ALL SELECT 'nbp_rates', COUNT(*) FROM nbp_rates;" 2>/dev/null
