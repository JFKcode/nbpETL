#!/bin/bash

# Ustawiamy adres API NBP i nazwę pliku docelowego
URL="http://api.nbp.pl/api/exchangerates/rates/a/usd/?format=json"
FILE_PATH="usd_rates.csv"

# Pobieramy JSON z internetu
RESPONSE=$(curl -s $URL)

# Sprawdzamy czy odpowiedź jest pusta
if [ -z "$RESPONSE" ]; then
    echo "Błąd: Nie udało się pobrać danych z API NBP"
    exit 1
fi

# Używamy narzędzia 'jq', aby wyciągnąć konkretne pola z JSONa
DATE=$(echo $RESPONSE | jq -r '.rates[0].effectiveDate')
RATE=$(echo $RESPONSE | jq -r '.rates[0].mid')

# Sprawdzamy czy dane zostały poprawnie wyciągnięte
if [ "$DATE" == "null" ] || [ "$RATE" == "null" ]; then
    echo "Błąd: Nie udało się przetworzyć danych z API"
    exit 1
fi

# Jeśli plik CSV nie istnieje, tworzymy go i dodajemy nagłówki
if [ ! -f $FILE_PATH ]; then
    echo "exchange_date,rate" > $FILE_PATH
fi

# Zapisujemy wyciągnięte dane do pliku CSV
echo "$DATE,$RATE" >> $FILE_PATH

echo "Sukces! Pobrano dane: $DATE - $RATE PLN"