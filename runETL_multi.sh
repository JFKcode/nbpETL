#!/bin/bash

# ===========================================
# ETL Pipeline - Wiele Walut (USD, EUR, GBP, CHF)
# ===========================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     ETL Pipeline - Kursy Walut NBP (Multi-Currency)       ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Katalog ze skryptami
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# KROK 1: Extract - Pobieranie danych z API NBP
echo ""
echo "▶ [1/2] EXTRACT - Pobieranie kursów walut z API NBP..."
echo ""
bash fetchMultiCurrency.sh

if [ $? -ne 0 ]; then
    echo "✗ Błąd podczas pobierania danych!"
    exit 1
fi

# KROK 2: Load - Ładowanie do bazy PostgreSQL
echo ""
echo "▶ [2/2] LOAD - Ładowanie danych do PostgreSQL..."
echo ""
bash loadMultiCurrency.sh

if [ $? -ne 0 ]; then
    echo "✗ Błąd podczas ładowania do bazy!"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✓ ETL zakończony pomyślnie!                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Sprawdź dane: bash checkData.sh"
