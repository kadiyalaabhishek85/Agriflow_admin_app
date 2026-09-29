const fs = require('fs');

const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== FARMER ENDPOINTS IN OPENAPI ===');
const farmerPaths = {};
for (const [path, methods] of Object.entries(openapi.paths)) {
  if (path.toLowerCase().includes('farmer')) {
    farmerPaths[path] = {};
    for (const [method, op] of Object.entries(methods)) {
      farmerPaths[path][method] = {
        summary: op.summary,
        operationId: op.operationId,
        tags: op.tags,
        parameters: op.parameters,
        requestBody: op.requestBody,
        responses: Object.keys(op.responses || {}),
        description: op.description
      };
    }
  }
}

console.log(JSON.stringify(farmerPaths, null, 2));
