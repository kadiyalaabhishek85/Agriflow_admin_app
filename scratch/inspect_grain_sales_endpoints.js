const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== PATHS FOR GRAIN SALES ===');
for (const p in openapi.paths) {
  if (p.includes('grain-sales')) {
    console.log(p, Object.keys(openapi.paths[p]));
    for (const m in openapi.paths[p]) {
      const op = openapi.paths[p][m];
      console.log(`  ${m.toUpperCase()} ${p}: summary="${op.summary}", requestBody=`, JSON.stringify(op.requestBody || {}), 'responses=', Object.keys(op.responses || {}));
    }
  }
}
