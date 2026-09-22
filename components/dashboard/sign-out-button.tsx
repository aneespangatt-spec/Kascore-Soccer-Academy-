'use client';
import { createClient } from '@/lib/supabase/client';
import { useRouter } from 'next/navigation';
export function SignOutButton() { const router = useRouter(); return <button className="rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold" onClick={async () => { await createClient().auth.signOut(); router.replace('/login'); router.refresh(); }}>Sign out</button>; }
