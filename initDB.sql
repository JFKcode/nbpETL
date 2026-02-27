-- Stara tabela (tylko USD) - zachowana dla kompatybilności
CREATE TABLE IF NOT EXISTS nbp_usd_rates (
    id SERIAL PRIMARY KEY,
    exchange_date DATE UNIQUE,
    rate NUMERIC(10,4)
);

-- Nowa tabela - obsługa wielu walut
CREATE TABLE IF NOT EXISTS nbp_rates (
    id SERIAL PRIMARY KEY,
    currency_code VARCHAR(3) NOT NULL,
    currency_name VARCHAR(50),
    exchange_date DATE NOT NULL,
    rate NUMERIC(10,4) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(currency_code, exchange_date)
);

-- Indeks dla szybszego wyszukiwania
CREATE INDEX IF NOT EXISTS idx_currency_date ON nbp_rates(currency_code, exchange_date);