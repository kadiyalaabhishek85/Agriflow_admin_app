const fs = require('fs');

const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

const schemas = ['FarmerAdminView', 'UserStatus', 'BankStatus', 'BankRequestStatus', 'FarmerProfileAdminView'];

for (const name of schemas) {
  console.log(`\n=== SCHEMA: ${name} ===`);
  console.log(JSON.stringify(openapi.components.schemas[name], null, 2));
}
