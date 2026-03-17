#!/bin/bash

# ===========================================
# ETL Pipeline - Wiele Walut (USD, EUR, GBP, CHF)
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

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     ETL Pipeline - Kursy Walut NBP (Multi-Currency)       ║"
echo "╚════════════════════════════════════════════════════════════╝"
log "=== START ETL Pipeline ==="

# KROK 1: Extract
log "▶ [1/2] EXTRACT - Pobieranie kursów walut z API NBP..."
bash fetchMultiCurrency.sh

if [ $? -ne 0 ]; then
    log "✗ BŁĄD podczas pobierania danych!"
    exit 1
fi

# KROK 2: Load
log "▶ [2/2] LOAD - Ładowanie danych do PostgreSQL..."
bash loadMultiCurrency.sh

if [ $? -ne 0 ]; then
    log "✗ BŁĄD podczas ładowania do bazy!"
    exit 1
fi

log "=== ETL zakończony pomyślnie ==="
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✓ ETL zakończony pomyślnie!                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Sprawdź dane: bash checkData.sh"
echo "Logi:        $LOG_FILE"
