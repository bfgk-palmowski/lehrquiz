-- LehrQuiz Supabase Setup
-- Einmal im Supabase SQL Editor ausführen

-- Sessions Tabelle
create table if not exists lehrquiz_sessions (
  id uuid default gen_random_uuid() primary key,
  code text unique not null,
  quiz_data jsonb not null,
  phase text not null default 'lobby',
  question_index integer not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Players Tabelle
create table if not exists lehrquiz_players (
  id uuid default gen_random_uuid() primary key,
  session_code text not null references lehrquiz_sessions(code) on delete cascade,
  name text not null,
  score integer not null default 0,
  created_at timestamptz default now(),
  unique(session_code, name)
);

-- Answers Tabelle
create table if not exists lehrquiz_answers (
  id uuid default gen_random_uuid() primary key,
  session_code text not null references lehrquiz_sessions(code) on delete cascade,
  question_index integer not null,
  player_name text not null,
  answer_index integer not null,
  points_earned integer not null default 0,
  created_at timestamptz default now(),
  unique(session_code, question_index, player_name)
);

-- Realtime aktivieren
alter publication supabase_realtime add table lehrquiz_sessions;
alter publication supabase_realtime add table lehrquiz_players;
alter publication supabase_realtime add table lehrquiz_answers;

-- RLS Policies (public access für Demo)
alter table lehrquiz_sessions enable row level security;
alter table lehrquiz_players enable row level security;
alter table lehrquiz_answers enable row level security;

create policy "Public read sessions" on lehrquiz_sessions for select using (true);
create policy "Public insert sessions" on lehrquiz_sessions for insert with check (true);
create policy "Public update sessions" on lehrquiz_sessions for update using (true);
create policy "Public delete sessions" on lehrquiz_sessions for delete using (true);

create policy "Public read players" on lehrquiz_players for select using (true);
create policy "Public insert players" on lehrquiz_players for insert with check (true);
create policy "Public update players" on lehrquiz_players for update using (true);

create policy "Public read answers" on lehrquiz_answers for select using (true);
create policy "Public insert answers" on lehrquiz_answers for insert with check (true);

-- Auto-cleanup alter Sessions (älter als 24h)
create or replace function cleanup_old_sessions()
returns void language plpgsql as $$
begin
  delete from lehrquiz_sessions where created_at < now() - interval '24 hours';
end;
$$;
