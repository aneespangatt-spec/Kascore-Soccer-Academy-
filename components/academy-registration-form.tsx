'use client';

import { createClient } from '@/lib/supabase/client';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export function AcademyRegistrationForm() {
  const router = useRouter();
  const [message, setMessage] = useState<string>();
  async function createAcademy(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const slug = String(form.get('slug')).trim().toLowerCase();
    const { error } = await createClient().rpc('create_academy', { academy_name: String(form.get('name')), academy_slug: slug, academy_timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC' });
    if (error) return setMessage(error.message);
    router.replace('/dashboard');
    router.refresh();
  }
  return <form onSubmit={createAcademy} className="w-full max-w-md rounded-2xl bg-white p-8 shadow-sm"><p className="text-sm font-bold tracking-[.15em] text-pitch-700">ACADEMIQ</p><h1 className="mt-5 text-3xl font-bold">Register your academy</h1><p className="mt-2 text-sm text-slate-600">You will be the first Academy Admin.</p><label className="mt-6 block text-sm font-medium" htmlFor="name">Academy name</label><input className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2" id="name" name="name" required minLength={2} /><label className="mt-4 block text-sm font-medium" htmlFor="slug">Academy URL slug</label><input className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2" id="slug" name="slug" required pattern="[a-z0-9]+(-[a-z0-9]+)*" title="Use lowercase letters, numbers and hyphens." /><button className="mt-6 w-full rounded-lg bg-pitch-700 px-4 py-2.5 font-semibold text-white" type="submit">Create academy</button>{message && <p className="mt-4 text-sm text-red-700" role="alert">{message}</p>}</form>;
}
