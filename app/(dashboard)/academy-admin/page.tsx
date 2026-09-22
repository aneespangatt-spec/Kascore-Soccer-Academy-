import { SignOutButton } from '@/components/dashboard/sign-out-button';
import { isAcademyAdmin, type AcademyRole } from '@/lib/auth/roles';
import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';

export default async function AcademyAdminPage() {
  const supabase = createClient(); const { data: { user } } = await supabase.auth.getUser(); if (!user) redirect('/login');
  const { data: profile } = await supabase.from('profiles').select('active_academy_id').eq('id', user.id).single(); if (!profile?.active_academy_id) redirect('/register/academy');
  const { data: membership } = await supabase.from('academy_memberships').select('role').eq('academy_id', profile.active_academy_id).eq('user_id', user.id).maybeSingle(); if (!isAcademyAdmin(membership?.role as AcademyRole | undefined)) redirect('/dashboard');
  const { data: academy } = await supabase.from('academies').select('name, slug, timezone').eq('id', profile.active_academy_id).single();
  const { count: teamCount } = await supabase.from('teams').select('*', { count: 'exact', head: true }).eq('academy_id', profile.active_academy_id);
  const { count: playerCount } = await supabase.from('players').select('*', { count: 'exact', head: true }).eq('academy_id', profile.active_academy_id);
  return <main className="mx-auto max-w-6xl p-8"><header className="flex items-center justify-between"><div><p className="text-sm font-bold tracking-[.15em] text-pitch-700">{academy?.name ?? 'ACADEMIQ'}</p><h1 className="mt-2 text-3xl font-bold">Academy Admin dashboard</h1></div><SignOutButton /></header><p className="mt-4 text-slate-600">Managing <strong>{academy?.name}</strong> ({academy?.slug}). Data displayed here is scoped to this academy only.</p><section className="mt-10 grid gap-5 sm:grid-cols-2"><div className="rounded-xl bg-white p-6 shadow-sm"><p className="text-sm text-slate-500">Teams</p><p className="mt-2 text-3xl font-bold">{teamCount ?? 0}</p></div><div className="rounded-xl bg-white p-6 shadow-sm"><p className="text-sm text-slate-500">Players</p><p className="mt-2 text-3xl font-bold">{playerCount ?? 0}</p></div></section></main>;
}
