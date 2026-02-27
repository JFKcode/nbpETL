#!/bin/bash

# ===========================================
# ETL Pipeline - Automatyczny Ekstraktor Danych NBP
# ===========================================

echo "=========================================="
echo "  ETL Pipeline - Kurs USD z NBP"
echo "=========================================="

# Katalog ze skryptami
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# KROK 1: Extract - Pobieranie danych z API NBP
echo ""
echo "[1/2] Pobieranie kursu USD z API NBP..."
bash fetchNbp.sh

if [ $? -ne 0 ]; then
    echo "Błąd podczas pobierania danych!"
    exit 1
fi

# KROK 2: Load - Ładowanie do bazy PostgreSQL
echo ""
echo "[2/2] Ładowanie danych do PostgreSQL..."
bash loadToDb.sh

if [ $? -ne 0 ]; then
    echo "Błąd podczas ładowania do bazy!"
    exit 1
fi

echo ""
echo "=========================================="
echo "  ETL zakończony pomyślnie!"
echo "=========================================="
