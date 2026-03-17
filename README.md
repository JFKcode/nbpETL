# Automatyczny Ekstraktor Danych NBP

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)](https://grafana.com/)

## Opis projektu

Projekt przedstawia **pipeline ETL** (Extract, Transform, Load), który automatycznie pobiera kursy walut (USD, EUR, GBP, CHF) z publicznego API Narodowego Banku Polskiego, przetwarza dane i zapisuje je do bazy PostgreSQL. Dane są wizualizowane na interaktywnym dashboardzie Grafana.

### Funkcje
- Pobieranie kursów 4 walut z API NBP z retry i walidacją danych
- Zapis do relacyjnej bazy danych PostgreSQL (UPSERT — bez duplikatów)
- Interaktywny dashboard w Grafanie (auto-odświeżanie co 1h)
- Pełna konteneryzacja z Docker Compose (health checks)
- Konfiguracja schedulera (cron) — automatyczne uruchamianie pon-pt o 9:00
- Logowanie do plików z timestampem

## Architektura

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    API NBP      │────▶│    CSV File     │────▶│   PostgreSQL    │────▶│    Grafana      │
│    (JSON)       │     │     rates       │     │    Database     │     │   Dashboard     │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
      EXTRACT             TRANSFORM                  LOAD                  VISUALIZE
     (curl+jq)          (walidacja)             (psql \copy)          (http://localhost:3000)
```

## Struktura projektu

```
nbp-etl/
├── .env.template            # Szablon konfiguracji (skopiuj jako .env)
├── docker-compose.yml       # PostgreSQL 16 + Grafana 11.4.0
├── initDB.sql               # Schemat bazy danych + indeksy
├── grafana/
│   ├── provisioning/        # Auto-konfiguracja Grafany
│   │   ├── datasources/
│   │   └── dashboards/
│   └── dashboards/          # Dashboard JSON
├── fetchNbp.sh              # ETL Extract: tylko USD
├── fetchMultiCurrency.sh    # ETL Extract: USD, EUR, GBP, CHF
├── loadToDb.sh              # ETL Load: tylko USD
├── loadMultiCurrency.sh     # ETL Load: wiele walut
├── runETL.sh                # Pipeline: tylko USD
├── runETL_multi.sh          # Pipeline: wiele walut (zalecany)
├── checkData.sh             # Podgląd danych w bazie
├── setup_cron.sh            # Konfiguracja harmonogramu cron
└── logs/                    # Logi ETL (generowane automatycznie)
```

## Technologie

| Technologia | Wersja | Zastosowanie |
|-------------|--------|-------------|
| **Bash** | — | Skrypty automatyzacji ETL |
| **curl** | — | Pobieranie danych z API |
| **jq** | — | Parsowanie JSON |
| **PostgreSQL** | 16 | Baza danych |
| **Docker** | — | Konteneryzacja |
| **Grafana** | 11.4.0 | Wizualizacja danych |

## Instalacja i uruchomienie

### 1. Skonfiguruj zmienne środowiskowe

```bash
cp .env.template .env
# Edytuj .env i ustaw własne hasła
```

> **Ważne:** Plik `.env` zawiera hasła i **nie jest commitowany do repozytorium**.

### 2. Uruchom kontenery (PostgreSQL + Grafana)

```bash
docker-compose up -d
```

Docker Compose automatycznie czeka na gotowość PostgreSQL przed uruchomieniem Grafany (health check).

### 3. Uruchom ETL (wiele walut)

```bash
bash runETL_multi.sh
```

Logi zapisywane są do katalogu `logs/etl_YYYY-MM-DD.log`.

### 4. (Opcjonalnie) Skonfiguruj automatyczne uruchamianie

```bash
bash setup_cron.sh
```

Pipeline będzie uruchamiany automatycznie każdego dnia roboczego o 9:00.

### 5. Otwórz dashboard Grafana

**URL:** http://localhost:3000

**Login:** wartości z pliku `.env` (`GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD`)

### 6. Sprawdź dane w terminalu

```bash
bash checkData.sh
```

## Dashboard Grafana

Dashboard zawiera:
- **4 panele Stat** — aktualny kurs USD, EUR, GBP, CHF
- **Wykres liniowy** — historia kursów wszystkich walut (min/max/średnia w legendzie)
- **Tabela** — ostatnie 50 rekordów

Dashboard automatycznie odświeża się co 1 godzinę. Strefa czasowa: `Europe/Warsaw`.

## Użycie

| Komenda | Opis |
|---------|------|
| `bash runETL_multi.sh` | ETL dla 4 walut (zalecany) |
| `bash runETL.sh` | ETL tylko USD |
| `bash checkData.sh` | Podgląd danych w bazie |
| `bash setup_cron.sh` | Konfiguracja harmonogramu cron |

### Docker

```bash
docker-compose up -d      # Uruchom
docker-compose down       # Zatrzymaj
docker-compose logs -f    # Logi kontenerów
```

## Schemat bazy danych

```sql
-- Główna tabela dla wielu walut
CREATE TABLE nbp_rates (
    id SERIAL PRIMARY KEY,
    currency_code VARCHAR(3) NOT NULL,
    currency_name VARCHAR(50),
    exchange_date DATE NOT NULL,
    rate NUMERIC(10,4) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(currency_code, exchange_date)
);

-- Indeksy
CREATE INDEX idx_currency_date ON nbp_rates(currency_code, exchange_date);
CREATE INDEX idx_exchange_date  ON nbp_rates(exchange_date DESC);
```

## API NBP

**Endpoint:** `http://api.nbp.pl/api/exchangerates/rates/a/{waluta}/?format=json`

**Obsługiwane waluty:** USD, EUR, GBP, CHF

Skrypty automatycznie ponawiają próbę pobrania danych (3 próby z opóźnieniem 5/10/15s) w razie niedostępności API.

## Autor

Projekt stworzony jako demonstracja umiejętności ETL i wizualizacji danych.
