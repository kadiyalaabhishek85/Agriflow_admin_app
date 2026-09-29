const fs = require('fs');
const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

const schemas = ['SeedPublic', 'SeedCreate', 'SeedUpdate', 'SuccessResponse_list_SeedPublic__', 'SuccessResponse_SeedPublic_'];

schemas.forEach(s => {
  console.log(`\n================ SCHEMA: ${s} ================`);
  console.log(JSON.stringify(openapi.components.schemas[s], null, 2));
});
