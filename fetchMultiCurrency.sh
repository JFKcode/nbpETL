#!/bin/bash

# ===========================================
# Pobieranie kursów wielu walut z API NBP
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

# Walidacja narzędzi
for tool in curl jq; do
    if ! command -v "$tool" &>/dev/null; then
        log "BŁĄD: Wymagane narzędzie '$tool' nie jest zainstalowane."
        exit 1
    fi
done

# Lista walut do pobrania
CURRENCIES=("usd" "eur" "gbp" "chf")

declare -A CURRENCY_NAMES
CURRENCY_NAMES["usd"]="dolar amerykański"
CURRENCY_NAMES["eur"]="euro"
CURRENCY_NAMES["gbp"]="funt szterling"
CURRENCY_NAMES["chf"]="frank szwajcarski"

FILE_PATH="$SCRIPT_DIR/rates.csv"

# Nadpisz plik CSV z nagłówkami (bieżący batch)
echo "currency_code,currency_name,exchange_date,rate" > "$FILE_PATH"

log "Pobieranie kursów walut z API NBP..."

SUCCESS_COUNT=0
ERROR_COUNT=0

for CURRENCY in "${CURRENCIES[@]}"; do
    URL="http://api.nbp.pl/api/exchangerates/rates/a/${CURRENCY}/?format=json"
    RESPONSE=""

    # Retry z exponential backoff (3 próby)
    for ATTEMPT in 1 2 3; do
        RESPONSE=$(curl -sf --max-time 10 "$URL" 2>/dev/null)
        if [ -n "$RESPONSE" ]; then
            break
        fi
        log "[$CURRENCY] Próba $ATTEMPT/3 nieudana - czekam $((ATTEMPT * 5))s..."
        sleep $((ATTEMPT * 5))
    done

    if [ -z "$RESPONSE" ]; then
        log "[$CURRENCY] BŁĄD: brak odpowiedzi z API po 3 próbach"
        ((ERROR_COUNT++))
        continue
    fi

    DATE=$(echo "$RESPONSE" | jq -r '.rates[0].effectiveDate')
    RATE=$(echo "$RESPONSE" | jq -r '.rates[0].mid')
    CODE=$(echo "$RESPONSE" | jq -r '.code')

    # Walidacja danych
    if [ "$DATE" = "null" ] || [ "$RATE" = "null" ] || [ -z "$DATE" ] || [ -z "$RATE" ]; then
        log "[$CURRENCY] BŁĄD: nieprawidłowa struktura odpowiedzi API"
        ((ERROR_COUNT++))
        continue
    fi

    # Walidacja: kurs musi być dodatnią liczbą
    if ! echo "$RATE" | grep -qE '^[0-9]+(\.[0-9]+)?$' || [ "$(echo "$RATE <= 0" | bc -l 2>/dev/null)" = "1" ]; then
        log "[$CURRENCY] BŁĄD: nieprawidłowa wartość kursu: $RATE"
        ((ERROR_COUNT++))
        continue
    fi

    CURRENCY_UPPER=$(echo "$CURRENCY" | tr '[:lower:]' '[:upper:]')
    echo "${CURRENCY_UPPER},${CURRENCY_NAMES[$CURRENCY]},$DATE,$RATE" >> "$FILE_PATH"

    log "[$CURRENCY_UPPER] $DATE: $RATE PLN"
    ((SUCCESS_COUNT++))
done

log "Pobrano: $SUCCESS_COUNT walut | Błędy: $ERROR_COUNT"

if [ "$SUCCESS_COUNT" -eq 0 ]; then
    log "BŁĄD KRYTYCZNY: Nie pobrano żadnych danych!"
    exit 1
fi
