#!/bin/bash

# ===========================================
# Konfiguracja schedulera (cron) dla ETL NBP
# Uruchamia pipeline codziennie o 9:00 (pon-pt)
# ===========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ETL_SCRIPT="$SCRIPT_DIR/runETL_multi.sh"
CRON_ENTRY="0 9 * * 1-5 bash $ETL_SCRIPT >> $SCRIPT_DIR/logs/cron.log 2>&1"

# Sprawdź czy wpis już istnieje
if crontab -l 2>/dev/null | grep -qF "$ETL_SCRIPT"; then
    echo "Harmonogram już jest skonfigurowany:"
    crontab -l | grep "$ETL_SCRIPT"
    exit 0
fi

# Dodaj wpis do crontab
(crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -

if [ $? -eq 0 ]; then
    echo "✓ Harmonogram skonfigurowany!"
    echo "  Pipeline uruchamia się codziennie o 9:00 (poniedziałek-piątek)"
    echo "  Logi: $SCRIPT_DIR/logs/cron.log"
    echo ""
    echo "Aktualny crontab:"
    crontab -l | grep "$ETL_SCRIPT"
else
    echo "✗ Błąd podczas konfiguracji crona."
    exit 1
fi

echo ""
echo "Aby usunąć harmonogram: crontab -e"
