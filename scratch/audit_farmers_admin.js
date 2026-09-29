const fs = require('fs');

const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== ADMIN / MANAGER / SHARED FARMER ENDPOINTS ===');
for (const [path, methods] of Object.entries(openapi.paths)) {
  if (path.includes('farmer') && !path.startsWith('/api/v1/farmer/')) {
    console.log(`PATH: ${path}`);
    for (const [method, op] of Object.entries(methods)) {
      console.log(`  [${method.toUpperCase()}] ${op.summary} (tags: ${op.tags})`);
      console.log(`    operationId: ${op.operationId}`);
      if (op.parameters) {
        console.log(`    parameters:`, op.parameters.map(p => `${p.name} (${p.in}${p.required ? ', req' : ''})`));
      }
      if (op.requestBody) {
        console.log(`    requestBody schema:`, JSON.stringify(op.requestBody));
      }
      console.log(`    responses:`, Object.keys(op.responses || {}));
      for (const [code, resp] of Object.entries(op.responses || {})) {
        if (resp.content && resp.content['application/json']) {
          console.log(`      ${code} schema:`, JSON.stringify(resp.content['application/json'].schema));
        }
      }
    }
  }
}
