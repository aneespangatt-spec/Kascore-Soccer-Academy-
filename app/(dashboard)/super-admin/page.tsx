import { SignOutButton } from '@/components/dashboard/sign-out-button';
import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';

export default async function SuperAdminPage() {
  const supabase = createClient(); const { data: { user } } = await supabase.auth.getUser(); if (!user) redirect('/login');
  const { data: profile } = await supabase.from('profiles').select('platform_role, full_name').eq('id', user.id).single(); if (profile?.platform_role !== 'super_admin') redirect('/dashboard');
  const { data: academies } = await supabase.from('academies').select('id, name, slug, created_at').order('created_at', { ascending: false });
  return <main className="mx-auto max-w-6xl p-8"><header className="flex items-center justify-between"><div><p className="text-sm font-bold tracking-[.15em] text-pitch-700">ACADEMIQ PLATFORM</p><h1 className="mt-2 text-3xl font-bold">Super Admin dashboard</h1></div><SignOutButton /></header><section className="mt-10 rounded-xl bg-white p-6 shadow-sm"><h2 className="text-lg font-bold">Academies</h2><p className="mt-1 text-sm text-slate-600">Platform-wide tenant directory. This view is only available to Super Admins.</p><ul className="mt-5 divide-y divide-slate-100">{academies?.map((academy) => <li className="flex justify-between py-3" key={academy.id}><span className="font-medium">{academy.name}</span><span className="text-sm text-slate-500">{academy.slug}</span></li>)}{academies?.length === 0 && <li className="py-3 text-sm text-slate-500">No academies registered yet.</li>}</ul></section></main>;
}
