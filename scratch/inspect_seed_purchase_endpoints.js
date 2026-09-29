const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== SEED PURCHASE ENDPOINTS ===');
for (const [path, methods] of Object.entries(openapi.paths)) {
  if (path.includes('seed-purchase') || path.includes('seed_purchase') || path.includes('farmer/seeds') || path.includes('farmer/seed-purchase')) {
    console.log(`\nPATH: ${path}`);
    for (const [method, details] of Object.entries(methods)) {
      console.log(`  ${method.toUpperCase()} (${details.operationId}): ${details.summary}`);
      if (details.parameters) {
        console.log(`    Parameters:`, JSON.stringify(details.parameters));
      }
      if (details.requestBody) {
        console.log(`    RequestBody:`, JSON.stringify(details.requestBody.content?.['application/json']?.schema));
      }
      for (const [status, resp] of Object.entries(details.responses)) {
        console.log(`    Response ${status}:`, JSON.stringify(resp.content?.['application/json']?.schema));
      }
    }
  }
}

// Also check any schemas used by requestBody of those endpoints
console.log('\n=== FARMER SEED PURCHASE REQUEST SCHEMA ===');
for (const [name, schema] of Object.entries(openapi.components.schemas)) {
  if (name.toLowerCase().includes('seedpurchasein') || name.toLowerCase().includes('seedpurchasecreate') || name.toLowerCase().includes('purchasecreate') || name.toLowerCase().includes('purchasein')) {
    console.log(`SCHEMA: ${name}`);
    console.log(JSON.stringify(schema, null, 2));
  }
}
