const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('=== SCHEMA: SeedOut ===');
console.log(JSON.stringify(openapi.components.schemas['SeedOut'], null, 2));

console.log('\n=== SCHEMA: GrainGrade ===');
console.log(JSON.stringify(openapi.components.schemas['GrainGrade'], null, 2));

console.log('\n=== SCHEMA: SeedPublic ===');
console.log(JSON.stringify(openapi.components.schemas['SeedPublic'], null, 2));

console.log('\n=== SCHEMA: SeedCreate ===');
console.log(JSON.stringify(openapi.components.schemas['SeedCreate'], null, 2));

console.log('\n=== SCHEMA: SeedUpdate ===');
console.log(JSON.stringify(openapi.components.schemas['SeedUpdate'], null, 2));
