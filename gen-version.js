// Writes version.json with the current build number, parsed from the BUILD
// constant in src/app.jsx. Runs as the first step of the Vercel build so the
// deployed site always advertises its exact build — the app fetches this and
// compares it to the build it's running to decide whether to show the
// "New version available" pill (and to hide it once the user is current).
const fs = require('fs');
const src = fs.readFileSync('src/app.jsx', 'utf8');
const m = src.match(/Live build\s+(\d+)/i);
const build = m ? m[1] : String(Date.now());
fs.writeFileSync('version.json', JSON.stringify({ build }) + '\n');
console.log('version.json ->', build);
