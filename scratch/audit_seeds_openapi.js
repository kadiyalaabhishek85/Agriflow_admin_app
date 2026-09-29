const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== SEEDS PATHS IN OPENAPI ===');
for (const [path, methods] of Object.entries(openapi.paths)) {
  if (path.includes('seeds') || path.includes('seed')) {
    console.log(`\nPath: ${path}`);
    for (const [method, details] of Object.entries(methods)) {
      console.log(`  Method: ${method.toUpperCase()}`);
      console.log(`  Summary: ${details.summary}`);
      console.log(`  OperationId: ${details.operationId}`);
      console.log(`  Tags: ${JSON.stringify(details.tags)}`);
      if (details.parameters) {
        console.log(`  Parameters: ${JSON.stringify(details.parameters.map(p => ({ name: p.name, in: p.in, required: p.required, schema: p.schema })))}`);
      }
      if (details.requestBody) {
        console.log(`  RequestBody: ${JSON.stringify(details.requestBody)}`);
      }
      console.log(`  Responses: ${Object.keys(details.responses).join(', ')}`);
      if (details.responses['200']) {
        console.log(`  200 Response: ${JSON.stringify(details.responses['200'])}`);
      }
      if (details.responses['201']) {
        console.log(`  201 Response: ${JSON.stringify(details.responses['201'])}`);
      }
    }
  }
}
