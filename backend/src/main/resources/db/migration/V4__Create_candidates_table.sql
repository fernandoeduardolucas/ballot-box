CREATE TABLE IF NOT EXISTS candidates (
    id          UUID         PRIMARY KEY,
    election_id UUID         NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    party       VARCHAR(255),
    photo_url   TEXT,
    number      INT          NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_candidate_number_per_election UNIQUE (election_id, number)
);

CREATE INDEX IF NOT EXISTS idx_candidates_election_id ON candidates (election_id);
