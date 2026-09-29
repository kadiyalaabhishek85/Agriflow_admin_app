const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('Seeds path security and details:');
['get', 'post'].forEach(m => {
  console.log(`\n/api/v1/seeds [${m}]:`);
  console.log(JSON.stringify(openapi.paths['/api/v1/seeds'][m], null, 2));
});
['patch', 'delete'].forEach(m => {
  console.log(`\n/api/v1/seeds/{seed_id} [${m}]:`);
  console.log(JSON.stringify(openapi.paths['/api/v1/seeds/{seed_id}'][m], null, 2));
});
