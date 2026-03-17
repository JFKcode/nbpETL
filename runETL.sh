#!/bin/bash

# ===========================================
# ETL Pipeline - Automatyczny Ekstraktor Danych NBP (USD)
# ===========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Załaduj zmienne środowiskowe z .env
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

# Konfiguracja logowania
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/etl_$(date +%Y-%m-%d).log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

echo "=========================================="
echo "  ETL Pipeline - Kurs USD z NBP"
echo "=========================================="
log "=== START ETL Pipeline (USD) ==="

# KROK 1: Extract
log "[1/2] Pobieranie kursu USD z API NBP..."
bash fetchNbp.sh

if [ $? -ne 0 ]; then
    log "BŁĄD podczas pobierania danych!"
    exit 1
fi

# KROK 2: Load
log "[2/2] Ładowanie danych do PostgreSQL..."
bash loadToDb.sh

if [ $? -ne 0 ]; then
    log "BŁĄD podczas ładowania do bazy!"
    exit 1
fi

log "=== ETL (USD) zakończony pomyślnie ==="
echo ""
echo "=========================================="
echo "  ETL zakończony pomyślnie!"
echo "=========================================="
