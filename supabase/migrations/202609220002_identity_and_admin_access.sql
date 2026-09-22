-- Phase 2: platform roles, academy provisioning, and administrator access controls.
create type public.platform_role as enum ('super_admin', 'user');

alter table public.profiles
  add column platform_role public.platform_role not null default 'user',
  add column active_academy_id uuid references public.academies(id) on delete set null;

create index profiles_active_academy_id_idx on public.profiles (active_academy_id);

create or replace function public.is_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and platform_role = 'super_admin')
$$;

create or replace function public.is_academy_admin(target_academy uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.academy_memberships
    where academy_id = target_academy
      and user_id = auth.uid()
      and role in ('owner', 'admin')
  )
$$;

-- Secure self-service academy creation. The first authenticated user becomes its owner.
create or replace function public.create_academy(academy_name text, academy_slug text, academy_timezone text default 'UTC')
returns uuid language plpgsql security definer set search_path = public as $$
declare new_academy_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication is required'; end if;
  if length(trim(academy_name)) < 2 then raise exception 'Academy name must be at least 2 characters'; end if;
  if academy_slug !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$' then raise exception 'Academy slug is invalid'; end if;
  insert into public.academies (name, slug, timezone)
    values (trim(academy_name), academy_slug, academy_timezone)
    returning id into new_academy_id;
  insert into public.academy_memberships (academy_id, user_id, role)
    values (new_academy_id, auth.uid(), 'owner');
  update public.profiles set active_academy_id = new_academy_id where id = auth.uid();
  return new_academy_id;
end;
$$;

create or replace function public.set_active_academy(target_academy uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_academy_member(target_academy) then raise exception 'You are not a member of this academy'; end if;
  update public.profiles set active_academy_id = target_academy where id = auth.uid();
end;
$$;

revoke all on function public.create_academy(text, text, text) from public;
revoke all on function public.set_active_academy(uuid) from public;
grant execute on function public.create_academy(text, text, text) to authenticated;
grant execute on function public.set_active_academy(uuid) to authenticated;

-- Replace broad member access with administrator-only access. Super admins can support all tenants.
drop policy if exists "academies: members read" on public.academies;
drop policy if exists "memberships: own read" on public.academy_memberships;
drop policy if exists "teams: member read" on public.teams;
drop policy if exists "teams: staff write" on public.teams;
drop policy if exists "players: member read" on public.players;
drop policy if exists "players: staff write" on public.players;
drop policy if exists "guardians: staff access" on public.guardians;
drop policy if exists "sessions: member read" on public.training_sessions;
drop policy if exists "sessions: staff write" on public.training_sessions;
drop policy if exists "team players: academy member read" on public.team_players;
drop policy if exists "team players: staff write" on public.team_players;
drop policy if exists "player guardians: staff access" on public.player_guardians;
drop policy if exists "attendance: staff access" on public.attendance;

create policy "academies: administrator read" on public.academies for select using (public.is_super_admin() or public.is_academy_admin(id));
create policy "academies: super admin manage" on public.academies for all using (public.is_super_admin()) with check (public.is_super_admin());
create policy "memberships: administrator read" on public.academy_memberships for select using (user_id = auth.uid() or public.is_super_admin() or public.is_academy_admin(academy_id));
create policy "memberships: super admin manage" on public.academy_memberships for all using (public.is_super_admin()) with check (public.is_super_admin());

create policy "teams: academy admin access" on public.teams for all using (public.is_super_admin() or public.is_academy_admin(academy_id)) with check (public.is_super_admin() or public.is_academy_admin(academy_id));
create policy "players: academy admin access" on public.players for all using (public.is_super_admin() or public.is_academy_admin(academy_id)) with check (public.is_super_admin() or public.is_academy_admin(academy_id));
create policy "guardians: academy admin access" on public.guardians for all using (public.is_super_admin() or public.is_academy_admin(academy_id)) with check (public.is_super_admin() or public.is_academy_admin(academy_id));
create policy "sessions: academy admin access" on public.training_sessions for all using (public.is_super_admin() or public.is_academy_admin(academy_id)) with check (public.is_super_admin() or public.is_academy_admin(academy_id));
create policy "team players: academy admin access" on public.team_players for all using (exists (select 1 from public.teams t where t.id = team_id and (public.is_super_admin() or public.is_academy_admin(t.academy_id)))) with check (exists (select 1 from public.teams t join public.players p on p.id = player_id where t.id = team_id and t.academy_id = p.academy_id and (public.is_super_admin() or public.is_academy_admin(t.academy_id))));
create policy "player guardians: academy admin access" on public.player_guardians for all using (exists (select 1 from public.players p where p.id = player_id and (public.is_super_admin() or public.is_academy_admin(p.academy_id)))) with check (exists (select 1 from public.players p join public.guardians g on g.id = guardian_id where p.id = player_id and p.academy_id = g.academy_id and (public.is_super_admin() or public.is_academy_admin(p.academy_id))));
create policy "attendance: academy admin access" on public.attendance for all using (exists (select 1 from public.training_sessions s where s.id = session_id and (public.is_super_admin() or public.is_academy_admin(s.academy_id)))) with check (exists (select 1 from public.training_sessions s join public.players p on p.id = player_id where s.id = session_id and s.academy_id = p.academy_id and (public.is_super_admin() or public.is_academy_admin(s.academy_id))));

-- RLS controls rows, so explicitly restrict profile columns to prevent self-promotion
-- or changing the active tenant through a direct browser update.
revoke update on table public.profiles from authenticated;
grant update (full_name, avatar_url) on table public.profiles to authenticated;
