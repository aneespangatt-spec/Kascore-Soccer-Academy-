import Link from 'next/link';

export default function Home() {
  return <main className="min-h-screen bg-[#0d5428] px-6 py-16 text-white"><div className="mx-auto max-w-5xl"><p className="text-sm font-bold tracking-[0.2em] text-emerald-200">ACADEMIQ</p><h1 className="mt-8 max-w-3xl text-5xl font-bold tracking-tight sm:text-7xl">Your academy, in perfect formation.</h1><p className="mt-6 max-w-xl text-lg leading-8 text-emerald-50">A secure, multi-tenant platform for football academies to manage players, teams, training and families.</p><Link className="mt-10 inline-block rounded-lg bg-white px-5 py-3 font-semibold text-pitch-700" href="/register">Register your academy</Link></div></main>;
}
