CREATE TABLE IF NOT EXISTS election_participations (
  voter_id VARCHAR(64) REFERENCES voters(id),
  election_id UUID REFERENCES elections(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_voter_election UNIQUE (voter_id, election_id)
);
