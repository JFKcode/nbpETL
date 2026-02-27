#!/bin/bash

# ===========================================
# Pobieranie kursów wielu walut z API NBP
# ===========================================

# Lista walut do pobrania
CURRENCIES=("usd" "eur" "gbp" "chf")

# Nazwy walut
declare -A CURRENCY_NAMES
CURRENCY_NAMES["usd"]="dolar amerykański"
CURRENCY_NAMES["eur"]="euro"
CURRENCY_NAMES["gbp"]="funt szterling"
CURRENCY_NAMES["chf"]="frank szwajcarski"

# Plik wyjściowy
FILE_PATH="rates.csv"

# Jeśli plik nie istnieje, tworzymy nagłówki
if [ ! -f $FILE_PATH ]; then
    echo "currency_code,currency_name,exchange_date,rate" > $FILE_PATH
fi

echo "Pobieranie kursów walut z API NBP..."
echo "======================================"

SUCCESS_COUNT=0
ERROR_COUNT=0

for CURRENCY in "${CURRENCIES[@]}"; do
    URL="http://api.nbp.pl/api/exchangerates/rates/a/${CURRENCY}/?format=json"
    
    # Pobierz dane z API
    RESPONSE=$(curl -s $URL)
    
    # Sprawdź czy odpowiedź nie jest pusta
    if [ -z "$RESPONSE" ]; then
        echo "[$CURRENCY] Błąd: brak odpowiedzi z API"
        ((ERROR_COUNT++))
        continue
    fi
    
    # Wyciągnij dane z JSON
    DATE=$(echo $RESPONSE | jq -r '.rates[0].effectiveDate')
    RATE=$(echo $RESPONSE | jq -r '.rates[0].mid')
    CODE=$(echo $RESPONSE | jq -r '.code')
    
    # Sprawdź poprawność danych
    if [ "$DATE" == "null" ] || [ "$RATE" == "null" ]; then
        echo "[$CURRENCY] Błąd: nieprawidłowe dane"
        ((ERROR_COUNT++))
        continue
    fi
    
    # Zapisz do CSV
    CURRENCY_UPPER=$(echo $CURRENCY | tr '[:lower:]' '[:upper:]')
    echo "${CURRENCY_UPPER},${CURRENCY_NAMES[$CURRENCY]},$DATE,$RATE" >> $FILE_PATH
    
    echo "[$CURRENCY_UPPER] $DATE: $RATE PLN"
    ((SUCCESS_COUNT++))
done

echo "======================================"
echo "Pobrano: $SUCCESS_COUNT walut | Błędy: $ERROR_COUNT"
