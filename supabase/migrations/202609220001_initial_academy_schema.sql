-- AcademiQ tenant foundation. Apply with: supabase db push
create extension if not exists "pgcrypto";

create type public.membership_role as enum ('owner', 'admin', 'coach', 'staff', 'guardian');
create type public.player_status as enum ('active', 'inactive', 'trial');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.academies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  timezone text not null default 'UTC',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.academy_memberships (
  academy_id uuid not null references public.academies(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.membership_role not null,
  created_at timestamptz not null default now(),
  primary key (academy_id, user_id)
);
create table public.teams (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies(id) on delete cascade,
  name text not null,
  age_group text,
  season text,
  created_at timestamptz not null default now(),
  unique (academy_id, name, season)
);
create table public.players (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies(id) on delete cascade,
  first_name text not null, last_name text not null, date_of_birth date not null,
  status public.player_status not null default 'active',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.team_players (
  team_id uuid not null references public.teams(id) on delete cascade,
  player_id uuid not null references public.players(id) on delete cascade,
  joined_at date not null default current_date,
  primary key (team_id, player_id)
);
create table public.guardians (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies(id) on delete cascade,
  full_name text not null, email text, phone text, created_at timestamptz not null default now()
);
create table public.player_guardians (
  player_id uuid not null references public.players(id) on delete cascade,
  guardian_id uuid not null references public.guardians(id) on delete cascade,
  is_primary boolean not null default false,
  primary key (player_id, guardian_id)
);
create table public.training_sessions (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies(id) on delete cascade,
  team_id uuid references public.teams(id) on delete set null,
  title text not null, starts_at timestamptz not null, ends_at timestamptz not null,
  location text, created_at timestamptz not null default now(), check (ends_at > starts_at)
);
create table public.attendance (
  session_id uuid not null references public.training_sessions(id) on delete cascade,
  player_id uuid not null references public.players(id) on delete cascade,
  present boolean, noted_at timestamptz not null default now(),
  primary key (session_id, player_id)
);

create index on public.academy_memberships (user_id, academy_id);
create index on public.teams (academy_id);
create index on public.players (academy_id);
create index on public.guardians (academy_id);
create index on public.training_sessions (academy_id, starts_at);

create or replace function public.is_academy_member(target_academy uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.academy_memberships where academy_id = target_academy and user_id = auth.uid())
$$;
create or replace function public.has_academy_role(target_academy uuid, allowed public.membership_role[])
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.academy_memberships where academy_id = target_academy and user_id = auth.uid() and role = any(allowed))
$$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin insert into public.profiles (id, full_name) values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', '')); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- Default-deny RLS. The service role performs provisioning and invitation workflows.
alter table public.profiles enable row level security;
alter table public.academies enable row level security;
alter table public.academy_memberships enable row level security;
alter table public.teams enable row level security;
alter table public.players enable row level security;
alter table public.team_players enable row level security;
alter table public.guardians enable row level security;
alter table public.player_guardians enable row level security;
alter table public.training_sessions enable row level security;
alter table public.attendance enable row level security;

create policy "profiles: self read" on public.profiles for select using (id = auth.uid());
create policy "profiles: self update" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy "academies: members read" on public.academies for select using (public.is_academy_member(id));
create policy "memberships: own read" on public.academy_memberships for select using (user_id = auth.uid());

create policy "teams: member read" on public.teams for select using (public.is_academy_member(academy_id));
create policy "teams: staff write" on public.teams for all using (public.has_academy_role(academy_id, array['owner','admin','coach','staff']::public.membership_role[])) with check (public.has_academy_role(academy_id, array['owner','admin','coach','staff']::public.membership_role[]));
create policy "players: member read" on public.players for select using (public.is_academy_member(academy_id));
create policy "players: staff write" on public.players for all using (public.has_academy_role(academy_id, array['owner','admin','coach','staff']::public.membership_role[])) with check (public.has_academy_role(academy_id, array['owner','admin','coach','staff']::public.membership_role[]));
create policy "guardians: staff access" on public.guardians for all using (public.has_academy_role(academy_id, array['owner','admin','coach','staff']::public.membership_role[])) with check (public.has_academy_role(academy_id, array['owner','admin','coach','staff']::public.membership_role[]));
create policy "sessions: member read" on public.training_sessions for select using (public.is_academy_member(academy_id));
create policy "sessions: staff write" on public.training_sessions for all using (public.has_academy_role(academy_id, array['owner','admin','coach','staff']::public.membership_role[])) with check (public.has_academy_role(academy_id, array['owner','admin','coach','staff']::public.membership_role[]));
create policy "team players: academy member read" on public.team_players for select using (exists (select 1 from public.teams t where t.id = team_id and public.is_academy_member(t.academy_id)));
create policy "team players: staff write" on public.team_players for all using (exists (select 1 from public.teams t where t.id = team_id and public.has_academy_role(t.academy_id, array['owner','admin','coach','staff']::public.membership_role[]))) with check (exists (select 1 from public.teams t join public.players p on p.id = player_id where t.id = team_id and t.academy_id = p.academy_id and public.has_academy_role(t.academy_id, array['owner','admin','coach','staff']::public.membership_role[])));
create policy "player guardians: staff access" on public.player_guardians for all using (exists (select 1 from public.players p where p.id = player_id and public.has_academy_role(p.academy_id, array['owner','admin','coach','staff']::public.membership_role[]))) with check (exists (select 1 from public.players p join public.guardians g on g.id = guardian_id where p.id = player_id and p.academy_id = g.academy_id and public.has_academy_role(p.academy_id, array['owner','admin','coach','staff']::public.membership_role[])));
create policy "attendance: staff access" on public.attendance for all using (exists (select 1 from public.training_sessions s where s.id = session_id and public.has_academy_role(s.academy_id, array['owner','admin','coach','staff']::public.membership_role[]))) with check (exists (select 1 from public.training_sessions s join public.players p on p.id = player_id where s.id = session_id and s.academy_id = p.academy_id and public.has_academy_role(s.academy_id, array['owner','admin','coach','staff']::public.membership_role[])));
