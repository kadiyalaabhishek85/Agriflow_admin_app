const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

console.log('Available OpenAPI Paths:');
Object.keys(openapi.paths).forEach(p => {
  const methods = Object.keys(openapi.paths[p]).map(m => m.toUpperCase()).join(',');
  console.log(`${methods.padEnd(10)} ${p}`);
});
