const fs = require('fs');

const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== CHECKING ALL PATHS IN OPENAPI ===');
for (const [path, methods] of Object.entries(openapi.paths)) {
  if (path.includes('farmer') || path.includes('farmer') || path.includes('admin/farmer')) {
    console.log(`PATH: ${path}`);
  }
}
