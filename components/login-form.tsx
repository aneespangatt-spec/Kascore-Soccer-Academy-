'use client';

import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';

export function LoginForm() {
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState<string>();
  async function signIn(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const { error } = await createClient().auth.signInWithOtp({ email, options: { emailRedirectTo: `${location.origin}/auth/callback?next=/dashboard` } });
    setMessage(error ? error.message : 'Check your email for a secure sign-in link.');
  }
  return <form onSubmit={signIn} className="w-full max-w-md rounded-2xl bg-white p-8 shadow-sm"><p className="text-sm font-bold tracking-[0.15em] text-pitch-700">ACADEMIQ</p><h1 className="mt-5 text-3xl font-bold">Sign in</h1><label className="mt-6 block text-sm font-medium" htmlFor="email">Work email</label><input className="mt-2 w-full rounded-lg border border-slate-300 px-3 py-2" id="email" type="email" autoComplete="email" required value={email} onChange={(event) => setEmail(event.target.value)} /><button className="mt-5 w-full rounded-lg bg-pitch-700 px-4 py-2.5 font-semibold text-white" type="submit">Email me a sign-in link</button>{message && <p className="mt-4 text-sm text-slate-600" role="status">{message}</p>}</form>;
}
