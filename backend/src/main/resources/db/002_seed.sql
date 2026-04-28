-- Dados de seed para execução local e demonstração.
insert into elections (id, title, starts_at, ends_at)
values (
  '11111111-1111-1111-1111-111111111111',
  'Eleição Académica 2026',
  '2026-01-01T00:00:00Z',
  '2026-12-31T23:59:59Z'
)
on conflict (id) do nothing;

insert into candidates (id, election_id, name, manifesto)
values
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Lista A', 'Transparência e acessibilidade'),
  ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'Lista B', 'Segurança e participação')
on conflict (id) do nothing;
