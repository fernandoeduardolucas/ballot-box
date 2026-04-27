create table if not exists elections (
  id uuid primary key,
  title varchar(200) not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null
);
create table if not exists candidates (
  id uuid primary key,
  election_id uuid references elections(id),
  name varchar(120) not null,
  manifesto text not null
);
create table if not exists voters (
  id varchar(64) primary key,
  full_name varchar(180) not null
);
create table if not exists votes (
  election_id uuid references elections(id),
  candidate_id uuid references candidates(id),
  voter_hash varchar(128) not null,
  created_at timestamptz not null,
  primary key (election_id, voter_hash)
);
create table if not exists audit_log (
  id bigserial primary key,
  actor varchar(120) not null,
  action varchar(80) not null,
  payload jsonb not null default '{}',
  created_at timestamptz not null default now()
);
