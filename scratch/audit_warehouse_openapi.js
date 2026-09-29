const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== WAREHOUSE & WAREHOUSE-SLOTS PATH DETAILS ===');
for (const [path, methods] of Object.entries(openapi.paths)) {
  if (path.includes('warehouse')) {
    console.log(`\n========================================`);
    console.log(`PATH: ${path}`);
    for (const [method, details] of Object.entries(methods)) {
      console.log(`\nMETHOD: ${method.toUpperCase()} (${details.operationId})`);
      console.log(`Summary: ${details.summary}`);
      console.log(`Security: ${JSON.stringify(details.security)}`);
      console.log(`Parameters: ${JSON.stringify(details.parameters, null, 2)}`);
      if (details.requestBody) {
        console.log(`RequestBody: ${JSON.stringify(details.requestBody, null, 2)}`);
      }
      console.log(`Responses: ${JSON.stringify(Object.keys(details.responses))}`);
      for (const [code, resp] of Object.entries(details.responses)) {
        if (resp.content && resp.content['application/json']) {
          console.log(`  Response ${code} Schema: ${JSON.stringify(resp.content['application/json'].schema, null, 2)}`);
        }
      }
    }
  }
}

// Also check schemas
console.log('\n=== RELEVANT SCHEMAS ===');
for (const [name, schema] of Object.entries(openapi.components.schemas)) {
  if (name.toLowerCase().includes('warehouse')) {
    console.log(`\nSCHEMA: ${name}`);
    console.log(JSON.stringify(schema, null, 2));
  }
}
