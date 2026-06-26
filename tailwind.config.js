/** @type {import('tailwindcss').Config} */
module.exports = {
  // Scan the app source + the HTML shell (splash screen uses Tailwind classes).
  content: ['./index.html', './src/**/*.jsx'],
  // Belt-and-suspenders: the tile number colors are produced via a lookup map
  // of complete class strings, but safelist them too in case any slip through.
  safelist: [
    'text-slate-700', 'text-indigo-700', 'text-emerald-700',
    'text-rose-700', 'text-blue-700', 'text-amber-700', 'text-purple-700',
  ],
  theme: { extend: {} },
  plugins: [],
};
