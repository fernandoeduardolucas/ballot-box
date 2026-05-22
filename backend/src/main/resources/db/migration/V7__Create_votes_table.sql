CREATE TABLE IF NOT EXISTS votes (
    id           UUID        PRIMARY KEY,
    voter_id     UUID        NOT NULL REFERENCES voters(id) ON DELETE RESTRICT,
    election_id  UUID        NOT NULL REFERENCES elections(id) ON DELETE RESTRICT,
    candidate_id UUID        NOT NULL REFERENCES candidates(id) ON DELETE RESTRICT,
    voted_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_vote_per_voter_per_election UNIQUE (voter_id, election_id)
);

CREATE INDEX IF NOT EXISTS idx_votes_election_id ON votes (election_id);
