import { isAcademyAdmin, type AcademyRole, type PlatformRole } from '@/lib/auth/roles';
import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';

export default async function DashboardPage() {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');
  const { data: profile } = await supabase.from('profiles').select('platform_role, active_academy_id').eq('id', user.id).single();
  if ((profile?.platform_role as PlatformRole) === 'super_admin') redirect('/super-admin');
  const { data: membership } = await supabase.from('academy_memberships').select('role').eq('academy_id', profile?.active_academy_id ?? '').eq('user_id', user.id).maybeSingle();
  if (isAcademyAdmin(membership?.role as AcademyRole | undefined)) redirect('/academy-admin');
  redirect('/register/academy');
}
