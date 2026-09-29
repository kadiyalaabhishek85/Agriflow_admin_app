const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== BILLING / INVOICE PATHS IN OPENAPI ===');
for (const [path, methods] of Object.entries(openapi.paths)) {
  if (path.toLowerCase().includes('bill') || path.toLowerCase().includes('invoice')) {
    console.log(`\nPath: ${path}`);
    for (const [method, details] of Object.entries(methods)) {
      console.log(`  Method: ${method.toUpperCase()}`);
      console.log(`  Summary: ${details.summary}`);
      console.log(`  OperationId: ${details.operationId}`);
      console.log(`  Tags: ${JSON.stringify(details.tags)}`);
    }
  }
}
