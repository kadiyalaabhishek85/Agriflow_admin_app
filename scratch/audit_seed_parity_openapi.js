const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== OPENAPI PATHS FOR SEEDS & PURCHASES ===');
for (const [path, methods] of Object.entries(openapi.paths)) {
  if (path.includes('seed') || path.includes('purchase')) {
    console.log(`\nPATH: ${path}`);
    for (const [method, details] of Object.entries(methods)) {
      console.log(`  ${method.toUpperCase()} (${details.operationId}): ${details.summary}`);
      if (details.parameters) {
        console.log(`    Params:`, details.parameters.map(p => `${p.name} (${p.in})`));
      }
      if (details.requestBody) {
        const schema = details.requestBody.content?.['application/json']?.schema;
        console.log(`    RequestBody:`, schema?.$ref || JSON.stringify(schema));
      }
      for (const [status, resp] of Object.entries(details.responses)) {
        const schema = resp.content?.['application/json']?.schema;
        console.log(`    Response ${status}:`, schema?.$ref || JSON.stringify(schema));
      }
    }
  }
}

console.log('\n=== SCHEMAS RELATING TO SEED, PURCHASE, GRADE ===');
for (const [name, schema] of Object.entries(openapi.components.schemas)) {
  if (name.toLowerCase().includes('seed') || name.toLowerCase().includes('purchase') || name.toLowerCase().includes('grade')) {
    console.log(`\nSCHEMA: ${name}`);
    console.log(JSON.stringify(schema, null, 2));
  }
}
