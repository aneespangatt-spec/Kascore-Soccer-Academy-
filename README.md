# AcademiQ

A multi-tenant football academy management SaaS built with Next.js App Router and Supabase.

## Local setup

1. Copy `.env.example` to `.env.local` and fill in the URL and publishable anon key from your Supabase project.
2. Install dependencies with `npm install`.
3. Apply the migrations with `supabase db push` (or execute both files in `supabase/migrations` in their timestamp order).
4. In Supabase Auth, enable email/password and email confirmation. Add `http://localhost:3000/auth/callback` to Auth redirect URLs.
5. Start with `npm run dev`.

## Phase 2 flows

- `/register` creates a real Supabase Auth account; after email confirmation the user lands on `/register/academy`.
- `/register/academy` invokes the authenticated `create_academy` database RPC, creating the tenant and its first `owner` membership atomically.
- `/login` sends a passwordless Supabase magic link to existing users.
- `/dashboard` routes Super Admins to `/super-admin` and Academy Admins to `/academy-admin`.

Create a Super Admin only through the controlled SQL/service-role process described in [the architecture plan](docs/foundation.md). Browser users cannot promote themselves.

See [the architecture plan](docs/foundation.md) for tenant boundaries, RLS policy choices, and the staged delivery roadmap.
