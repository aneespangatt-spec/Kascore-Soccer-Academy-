import { createClient } from '@/lib/supabase/server';
import type { EmailOtpType } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

export async function GET(request: Request) {
  const url = new URL(request.url);
  const code = url.searchParams.get('code');
  const tokenHash = url.searchParams.get('token_hash');
  const type = url.searchParams.get('type');
  const next = url.searchParams.get('next');
  const supabase = createClient();
  if (code) await supabase.auth.exchangeCodeForSession(code);
  if (tokenHash && type) await supabase.auth.verifyOtp({ token_hash: tokenHash, type: type as EmailOtpType });
  return NextResponse.redirect(new URL(next?.startsWith('/') ? next : '/dashboard', url.origin));
}
