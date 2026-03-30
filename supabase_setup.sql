-- supabase_setup.sql
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor → New Query).
-- Creates all tables, enums, RLS policies, and triggers for the Closer app.

-- ─── Enums ────────────────────────────────────────────────────────────────────

create type relationship_label as enum ('active', 'responsive', 'obligatory', 'cut_off');
create type change_triggered_by as enum ('system', 'manual');

-- ─── profiles ────────────────────────────────────────────────────────────────
-- Extends Supabase auth.users with a display name.

create table profiles (
  id          uuid primary key references auth.users on delete cascade,
  display_name text not null,
  created_at  timestamptz default now()
);

alter table profiles enable row level security;
create policy "Users can read and update their own profile"
  on profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ─── friends ─────────────────────────────────────────────────────────────────

create table friends (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references profiles on delete cascade,
  name       text not null,
  label      relationship_label not null default 'responsive',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table friends enable row level security;
create policy "Users can manage their own friends"
  on friends for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Auto-update updated_at on label changes
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger friends_updated_at
  before update on friends
  for each row execute procedure update_updated_at();

-- ─── interactions ────────────────────────────────────────────────────────────

create table interactions (
  id        uuid primary key default gen_random_uuid(),
  friend_id uuid not null references friends on delete cascade,
  user_id   uuid not null references profiles on delete cascade,
  score     smallint not null check (score >= -3 and score <= 3),
  note      text,
  created_at timestamptz default now()
);

alter table interactions enable row level security;
create policy "Users can manage their own interactions"
  on interactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index interactions_friend_id_created_at_idx
  on interactions (friend_id, created_at desc);

-- ─── label_changes ───────────────────────────────────────────────────────────

create table label_changes (
  id           uuid primary key default gen_random_uuid(),
  friend_id    uuid not null references friends on delete cascade,
  from_label   relationship_label not null,
  to_label     relationship_label not null,
  triggered_by change_triggered_by not null,
  reason       text,
  created_at   timestamptz default now()
);

alter table label_changes enable row level security;
create policy "Users can manage label changes for their own friends"
  on label_changes for all
  using (
    exists (
      select 1 from friends
      where friends.id = label_changes.friend_id
        and friends.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from friends
      where friends.id = label_changes.friend_id
        and friends.user_id = auth.uid()
    )
  );

create index label_changes_friend_id_idx on label_changes (friend_id, created_at desc);
