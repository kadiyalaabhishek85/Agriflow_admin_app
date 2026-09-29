const fs = require('fs');

const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

const relevantPaths = [
  '/api/v1/farmers',
  '/api/v1/farmers/{farmer_id}',
  '/api/v1/farmers/{farmer_id}/approval',
  '/api/v1/farmers/bank-change-requests',
  '/api/v1/farmers/bank-change-requests/{request_id}'
];

for (const p of relevantPaths) {
  console.log(`\n========================================`);
  console.log(`PATH: ${p}`);
  console.log(`========================================`);
  console.log(JSON.stringify(openapi.paths[p], null, 2));
}
