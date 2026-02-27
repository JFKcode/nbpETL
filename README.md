# Automatyczny Ekstraktor Danych NBP

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)](https://grafana.com/)

## Opis projektu

Projekt przedstawia **pipeline ETL** (Extract, Transform, Load), który automatycznie pobiera kursy walut (USD, EUR, GBP, CHF) z publicznego API Narodowego Banku Polskiego, przetwarza dane i zapisuje je do bazy PostgreSQL. Dane są wizualizowane na interaktywnym dashboardzie Grafana.

### Funkcje
- Pobieranie kursów 4 walut z API NBP
- Zapis do relacyjnej bazy danych PostgreSQL
- Interaktywny dashboard w Grafanie
- Konteneryzacja z Docker Compose

## Architektura

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    API NBP      │────▶│    CSV File     │────▶│   PostgreSQL    │────▶│    Grafana      │
│    (JSON)       │     │     rates       │     │    Database     │     │   Dashboard     │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
      EXTRACT             TRANSFORM                  LOAD                  VISUALIZE
     (curl+jq)            (zapis)               (psql \copy)            (http://localhost:3000)
```

## Struktura projektu

```
nbp-etl/
├── docker-compose.yml       # PostgreSQL + Grafana
├── initDB.sql               # Schemat bazy danych
├── grafana/
│   ├── provisioning/        # Auto-konfiguracja Grafany
│   │   ├── datasources/
│   │   └── dashboards/
│   └── dashboards/          # Dashboard JSON
├── fetchNbp.sh              # ETL: tylko USD
├── fetchMultiCurrency.sh    # ETL: USD, EUR, GBP, CHF
├── loadToDb.sh              # Load: tylko USD
├── loadMultiCurrency.sh     # Load: wiele walut
├── runETL.sh                # Pipeline: tylko USD
├── runETL_multi.sh          # Pipeline: wiele walut
└── checkData.sh             # Podgląd danych
```

## Technologie

| Technologia | Zastosowanie |
|-------------|-------------|
| **Bash** | Skrypty automatyzacji ETL |
| **curl** | Pobieranie danych z API |
| **jq** | Parsowanie JSON |
| **PostgreSQL 16** | Baza danych |
| **Docker** | Konteneryzacja |
| **Grafana** | Wizualizacja danych |

## Instalacja i uruchomienie

### 1. Uruchom kontenery (PostgreSQL + Grafana)

```bash
docker-compose up -d
```

### 2. Uruchom ETL (wiele walut)

```bash
bash runETL_multi.sh
```

### 3. Otwórz dashboard Grafana

**URL:** http://localhost:3000

**Login:** `admin` / `admin123`

### 4. Sprawdź dane w terminalu

```bash
bash checkData.sh
```

## Dashboard Grafana

Dashboard zawiera:
- **4 panele Stat** — aktualny kurs USD, EUR, GBP, CHF
- **Wykres liniowy** — historia kursów wszystkich walut
- **Tabela** — ostatnie 50 rekordów

## Użycie

| Komenda | Opis |
|---------|------|
| `bash runETL_multi.sh` | ETL dla 4 walut |
| `bash runETL.sh` | ETL tylko USD |
| `bash checkData.sh` | Podgląd danych w bazie |

### Docker

```bash
docker-compose up -d      # Uruchom
docker-compose down       # Zatrzymaj
docker-compose logs -f    # Logi
```

## Schemat bazy danych

```sql
-- Tabela dla wielu walut
CREATE TABLE nbp_rates (
    id SERIAL PRIMARY KEY,
    currency_code VARCHAR(3) NOT NULL,
    currency_name VARCHAR(50),
    exchange_date DATE NOT NULL,
    rate NUMERIC(10,4) NOT NULL,
    UNIQUE(currency_code, exchange_date)
);
```

## API NBP

**Endpoint:** `http://api.nbp.pl/api/exchangerates/rates/a/{waluta}/?format=json`

**Obsługiwane waluty:** USD, EUR, GBP, CHF

## Autor

Projekt stworzony jako demonstracja umiejętności ETL i wizualizacji danych.
