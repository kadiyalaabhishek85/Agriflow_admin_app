const fs = require('fs');

const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

const paths = [
  '/api/v1/farmers',
  '/api/v1/farmers/{farmer_id}',
  '/api/v1/farmers/{farmer_id}/approval',
  '/api/v1/farmers/bank-change-requests',
  '/api/v1/farmers/bank-change-requests/{request_id}'
];

for (const p of paths) {
  console.log(`\n=== PATH: ${p} ===`);
  const methods = openapi.paths[p];
  if (!methods) {
    console.log('NOT FOUND');
    continue;
  }
  for (const [m, op] of Object.entries(methods)) {
    console.log(`METHOD: ${m.toUpperCase()}`);
    console.log(`Summary: ${op.summary}`);
    console.log(`Description: ${op.description}`);
    console.log(`Security:`, op.security);
    console.log(`Tags:`, op.tags);
  }
}
