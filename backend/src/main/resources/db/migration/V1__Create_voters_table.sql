CREATE TABLE IF NOT EXISTS voters (
    id            UUID         PRIMARY KEY,
    civil_id      VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL
);
