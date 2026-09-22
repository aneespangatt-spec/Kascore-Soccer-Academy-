import Link from 'next/link';
import { LoginForm } from '@/components/login-form';
export default function LoginPage() { return <main className="grid min-h-screen place-items-center p-6"><div className="w-full max-w-md"><LoginForm /><p className="mt-5 text-center text-sm text-slate-600">New to AcademiQ? <Link className="font-semibold text-pitch-700" href="/register">Register your academy</Link></p></div></main>; }
