import { AcademyRegistrationForm } from '@/components/academy-registration-form';
import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';
export default async function AcademyRegistrationPage() { const { data: { user } } = await createClient().auth.getUser(); if (!user) redirect('/login'); return <main className="grid min-h-screen place-items-center p-6"><AcademyRegistrationForm /></main>; }
