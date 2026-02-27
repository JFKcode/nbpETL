# Automatyczny Ekstraktor Danych NBP

## Opis projektu

Projekt przedstawia **miniaturowy pipeline ETL** (Extract, Transform, Load), który automatycznie pobiera aktualny kurs dolara amerykańskiego (USD) z publicznego API Narodowego Banku Polskiego, przetwarza dane i zapisuje je do relacyjnej bazy danych PostgreSQL.

### Cel projektu
- Demonstracja umiejętności budowania procesów ETL
- Praktyczne wykorzystanie API REST
- Integracja z bazą danych PostgreSQL
- Konteneryzacja z użyciem Docker

## Architektura

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    API NBP      │────▶│    CSV File     │────▶│   PostgreSQL    │
│    (JSON)       │     │   usd_rates     │     │    Database     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
      EXTRACT             TRANSFORM                  LOAD
     (curl+jq)            (zapis)               (psql \copy)
```

### Przepływ danych

1. **Extract** — Skrypt `fetchNbp.sh` pobiera dane JSON z API NBP za pomocą `curl`
2. **Transform** — Narzędzie `jq` parsuje JSON i wyciąga tylko potrzebne pola (data, kurs)
3. **Load** — Skrypt `loadToDb.sh` ładuje dane z CSV do tabeli PostgreSQL

## Struktura projektu

```
nbp-etl/
├── docker-compose.yml   # Konfiguracja kontenera PostgreSQL
├── initDB.sql           # Schemat bazy danych (DDL)
├── fetchNbp.sh          # [E] Pobieranie danych z API NBP
├── loadToDb.sh          # [L] Ładowanie danych do PostgreSQL
├── runETL.sh            # Orkiestrator całego pipeline'u
├── checkData.sh         # Weryfikacja danych w bazie
├── usd_rates.csv        # Plik pośredni z danymi (generowany)
└── README.md            # Dokumentacja projektu
```

## 🛠️ Technologie

| Technologia | Zastosowanie |
|-------------|-------------|
| **Bash** | Skrypty automatyzacji ETL |
| **curl** | Pobieranie danych z API (HTTP client) |
| **jq** | Parsowanie i transformacja JSON |
| **PostgreSQL 16** | Relacyjna baza danych |
| **Docker** | Konteneryzacja bazy danych |
| **API NBP** | Źródło danych (kursy walut) |

## Wymagania

- **Docker Desktop** — [Pobierz](https://www.docker.com/products/docker-desktop/)
- **WSL** (Windows) lub terminal Linux/macOS
- Zainstalowane w systemie: `curl`, `jq`, `psql` (postgresql-client)

## Instalacja i uruchomienie

### 1. Uruchom bazę danych PostgreSQL

```bash
docker-compose up -d
```

### 2. Uruchom pipeline ETL

```bash
bash runETL.sh
```

### 3. Sprawdź dane w bazie

```bash
bash checkData.sh
```

**Przykładowy output:**
```
=== Ostatnie 10 rekordów z tabeli nbp_usd_rates ===
 id | exchange_date |  rate  
----+---------------+--------
  1 | 2026-02-27    | 3.5804

```

## Użycie

| Komenda | Opis |
|---------|------|
| `bash runETL.sh` | Uruchom pełny pipeline ETL |
| `bash fetchNbp.sh` | Tylko pobierz dane z API |
| `bash loadToDb.sh` | Tylko załaduj CSV do bazy |
| `bash checkData.sh` | Wyświetl dane z bazy |

### Zarządzanie Dockerem

```bash
docker-compose up -d      # Uruchom kontener
docker-compose down       # Zatrzymaj kontener
docker-compose down -v    # Zatrzymaj i usuń dane
docker-compose logs -f    # Zobacz logi
```

## Schemat bazy danych

```sql
CREATE TABLE nbp_usd_rates (
    id SERIAL PRIMARY KEY,
    exchange_date DATE UNIQUE,
    rate NUMERIC(10,4)
);
```

| Kolumna | Typ | Opis |
|---------|-----|------|
| `id` | SERIAL | Klucz główny (auto-increment) |
| `exchange_date` | DATE | Data kursu (unikalna) |
| `rate` | NUMERIC(10,4) | Kurs średni USD/PLN |


## 🔮 Możliwe rozszerzenia

- [ ] Automatyczne uruchamianie przez CRON
- [ ] Obsługa wielu walut (EUR, GBP, CHF)
- [ ] Wizualizacja danych (wykresy)
- [ ] Powiadomienia o zmianach kursu
- [ ] Dashboard w Grafanie
