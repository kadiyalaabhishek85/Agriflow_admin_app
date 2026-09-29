const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== PATH /api/v1/grain-sales/{sale_id}/pay ===');
console.log(JSON.stringify(openapi.paths['/api/v1/grain-sales/{sale_id}/pay'], null, 2));

console.log('\n=== PATH /api/v1/grain-sales/{sale_id}/review ===');
console.log(JSON.stringify(openapi.paths['/api/v1/grain-sales/{sale_id}/review'], null, 2));

console.log('\n=== SCHEMAS ===');
const schemas = openapi.components.schemas;
for (const key of ['GrainSalePayRequest', 'GrainSaleReviewRequest', 'GrainSalePublic', 'GrainSaleStatus', 'GrainProcureRequest']) {
  console.log(`\n--- ${key} ---`);
  console.log(JSON.stringify(schemas[key], null, 2));
}
