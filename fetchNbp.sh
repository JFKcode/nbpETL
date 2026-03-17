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

URL="http://api.nbp.pl/api/exchangerates/rates/a/usd/?format=json"
FILE_PATH="$SCRIPT_DIR/usd_rates.csv"
RESPONSE=""

# Retry z exponential backoff (3 próby)
for ATTEMPT in 1 2 3; do
    RESPONSE=$(curl -sf --max-time 10 "$URL" 2>/dev/null)
    if [ -n "$RESPONSE" ]; then
        break
    fi
    log "[USD] Próba $ATTEMPT/3 nieudana - czekam $((ATTEMPT * 5))s..."
    sleep $((ATTEMPT * 5))
done

if [ -z "$RESPONSE" ]; then
    log "[USD] BŁĄD: Nie udało się pobrać danych z API NBP po 3 próbach"
    exit 1
fi

DATE=$(echo "$RESPONSE" | jq -r '.rates[0].effectiveDate')
RATE=$(echo "$RESPONSE" | jq -r '.rates[0].mid')

if [ "$DATE" = "null" ] || [ "$RATE" = "null" ]; then
    log "[USD] BŁĄD: Nie udało się przetworzyć danych z API"
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "exchange_date,rate" > "$FILE_PATH"
fi

echo "$DATE,$RATE" >> "$FILE_PATH"
log "[USD] $DATE: $RATE PLN"
