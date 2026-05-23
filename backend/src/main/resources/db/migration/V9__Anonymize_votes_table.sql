ALTER TABLE votes DROP CONSTRAINT uq_vote_per_voter_per_election;
ALTER TABLE votes DROP COLUMN voter_id;
