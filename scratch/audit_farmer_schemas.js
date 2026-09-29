const fs = require('fs');

const openapi = JSON.parse(fs.readFileSync('openapi_dump.json', 'utf8'));

const schemasToInspect = [
  'FarmerAdminView',
  'FarmerCreateRequest',
  'FarmerApprovalRequest',
  'BankChangeRequestPublic',
  'BankChangeReviewRequest',
  'PaginatedResponse_FarmerAdminView_',
  'SuccessResponse_FarmerAdminView_',
  'FarmerProfilePublic',
  'UpdateFarmerProfileRequest'
];

console.log('=== FARMER SCHEMAS ===');
for (const name of schemasToInspect) {
  if (openapi.components.schemas[name]) {
    console.log(`\nSCHEMA: ${name}`);
    console.log(JSON.stringify(openapi.components.schemas[name], null, 2));
  } else {
    console.log(`\nSCHEMA ${name} NOT FOUND`);
  }
}
