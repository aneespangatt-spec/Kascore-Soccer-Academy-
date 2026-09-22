# AcademiQ foundation architecture

## Delivered in this foundation

- **Next.js 14 App Router** shell with a public landing page, passwordless login, auth callback, protected dashboard route and an accessible base design system.
- **Supabase SSR clients** split by browser and server, plus middleware that refreshes the session and blocks unauthenticated dashboard requests.
- **Tenant-first PostgreSQL schema** and default-deny Row Level Security migration.

## Database tables

| Table | Purpose | Tenant boundary |
| --- | --- | --- |
| `profiles` | Public account details for `auth.users` | User-owned |
| `academies` | Each customer organization | One row per academy |
| `academy_memberships` | User-to-academy role assignment | `(academy_id, user_id)` |
| `teams`, `players` | Core sporting records | `academy_id` |
| `team_players` | Team roster membership | Validated against matching tenant |
| `guardians`, `player_guardians` | Family contact and player relationship | Academy-owned and tenant-validated |
| `training_sessions`, `attendance` | Training operations | Academy-owned and tenant-validated |

`auth.users` remains Supabase-managed. The `on_auth_user_created` trigger creates a matching `profiles` record. Provisioning an academy and its first owner should run only in a trusted server-side workflow using Supabase's service-role key; it must never be exposed to the browser.

## RLS model

Every domain table has RLS enabled with no anonymous access. `is_academy_member(academy_id)` limits member reads to the requesting user's tenant. `has_academy_role` additionally gates operational writes to `owner`, `admin`, `coach`, and `staff` roles. Cross-table policies explicitly require child records to share an academy, preventing a valid user from linking records across tenants.

The initial guardian role deliberately does not expose child data yet. Before launching a guardian portal, add an identity link from `guardians` to `auth.users` and narrowly scoped child/attendance policies; do not grant broad academy-member read access to guardians. Also add audit logging, consent/retention workflows, and authorization tests before storing sensitive medical or safeguarding data.

## Authentication flow

1. The login form sends an email magic-link request to Supabase Auth.
2. Supabase returns to `/auth/callback`, which exchanges the authorization code for an SSR session.
3. Middleware validates and refreshes that session on dashboard requests.
4. Server Components retrieve the authenticated user from the server Supabase client; client components only use the publishable anon key and are constrained by RLS.

## Next delivery increments

1. Add tenant provisioning, invitation acceptance, tenant switcher and role-management Server Actions.
2. Build academy, team, player and guardian CRUD with validation and RLS integration tests.
3. Add calendar, attendance, communications, billing, audit logs, observability, backups, and production deployment controls.

## Phase 2: administrator access

The second migration adds a global `platform_role` to `profiles` and an `active_academy_id` pointer. `super_admin` is a platform-only role and is deliberately not assignable through the browser or registration flow. Bootstrap it once from the Supabase SQL editor or an audited service-role task:

```sql
update public.profiles set platform_role = 'super_admin' where id = '<auth-user-uuid>';
```

Every academy account remains many-to-many through `academy_memberships`; `active_academy_id` is only the selected working context. The `create_academy` RPC is a `security definer` function callable only by authenticated users. It creates the academy, assigns the caller the `owner` role (an Academy Admin), and makes it active atomically. The client cannot send a role or another user's identifier.

The `002` migration removes the initial broad member policies. Academy Admin access now requires `owner` or `admin` for the target `academy_id`; Super Admin access is verified independently from `profiles.platform_role`. Direct data access and dashboard queries remain subject to these same RLS policies, rather than relying on UI routing.
