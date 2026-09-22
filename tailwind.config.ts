import type { Config } from 'tailwindcss';
export default { content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'], theme: { extend: { colors: { pitch: { 500: '#16803C', 700: '#0D5428' } } } }, plugins: [] } satisfies Config;
