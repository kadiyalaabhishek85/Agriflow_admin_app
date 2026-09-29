const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== PATHS ===');
for (const [path, methods] of Object.entries(openapi.paths)) {
  if (path.includes('warehouse')) {
    for (const [m, op] of Object.entries(methods)) {
      console.log(`\n${m.toUpperCase()} ${path}`);
      console.log(`  Summary: ${op.summary}`);
      console.log(`  Security: ${JSON.stringify(op.security)}`);
      console.log(`  Parameters: ${JSON.stringify(op.parameters)}`);
      if (op.requestBody) {
        const schema = op.requestBody.content?.['application/json']?.schema;
        console.log(`  RequestBody: ${schema?.$ref || JSON.stringify(schema)}`);
      }
      for (const [status, resp] of Object.entries(op.responses)) {
        const schema = resp.content?.['application/json']?.schema;
        console.log(`  Response ${status}: ${schema?.$ref || JSON.stringify(schema)}`);
      }
    }
  }
}
