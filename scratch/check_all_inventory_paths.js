const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== INVENTORY PATHS IN OPENAPI ===');
for (const [path, methods] of Object.entries(openapi.paths)) {
  if (path.toLowerCase().includes('inventory')) {
    console.log(`\nPath: ${path}`);
    for (const [method, details] of Object.entries(methods)) {
      console.log(`  Method: ${method.toUpperCase()} (${details.operationId})`);
    }
  }
}
