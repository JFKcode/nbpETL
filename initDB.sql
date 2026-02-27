CREATE TABLE IF NOT EXISTS nbp_usd_rates (
    id SERIAL PRIMARY KEY,
    exchange_date DATE UNIQUE,
    rate NUMERIC(10,4)
);