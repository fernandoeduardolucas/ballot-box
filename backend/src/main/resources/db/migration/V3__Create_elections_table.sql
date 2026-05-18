CREATE TABLE IF NOT EXISTS elections (
    id         UUID         PRIMARY KEY,
    title      VARCHAR(255) NOT NULL,
    start_date TIMESTAMPTZ  NOT NULL,
    end_date   TIMESTAMPTZ  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT chk_election_dates CHECK (end_date > start_date)
);

CREATE INDEX IF NOT EXISTS idx_elections_start_date ON elections (start_date);
CREATE INDEX IF NOT EXISTS idx_elections_end_date   ON elections (end_date);
