'use client';

import { createClient } from '@/lib/supabase/client';
import Link from 'next/link';
import { useState } from 'react';

export function RegistrationForm() {
  const [message, setMessage] = useState<string>();
  async function register(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const { error } = await createClient().auth.signUp({ email: String(data.get('email')), password: String(data.get('password')), options: { emailRedirectTo: `${location.origin}/auth/callback?next=/register/academy` } });
    setMessage(error ? error.message : 'Check your email to confirm your account, then create your academy.');
  }
  return <form onSubmit={register} className="w-full max-w-md rounded-2xl bg-white p-8 shadow-sm"><p className="text-sm font-bold tracking-[.15em] text-pitch-700">ACADEMIQ</p><h1 className="mt-5 text-3xl font-bold">Create your account</h1><p className="mt-2 text-sm text-slate-600">Start with one academy; add further memberships later.</p><label className="mt-6 block text-sm font-medium" htmlFor="email">Email</label><input className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2" id="email" name="email" type="email" required autoComplete="email" /><label className="mt-4 block text-sm font-medium" htmlFor="password">Password</label><input className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2" id="password" name="password" type="password" minLength={8} required autoComplete="new-password" /><button className="mt-6 w-full rounded-lg bg-pitch-700 px-4 py-2.5 font-semibold text-white" type="submit">Create account</button>{message && <p className="mt-4 text-sm text-slate-600" role="status">{message}</p>}<p className="mt-5 text-sm text-slate-600">Already registered? <Link className="font-semibold text-pitch-700" href="/login">Sign in</Link></p></form>;
}
