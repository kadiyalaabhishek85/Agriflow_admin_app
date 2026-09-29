const fs = require('fs');

const adminHtml = fs.readFileSync('C:\\Users\\DELL\\Downloads\\agriflow\\ui-ux\\AdminDashboard Mobile UI\\AdminMobile UIUX.html', 'utf8');
const managerHtml = fs.readFileSync('C:\\Users\\DELL\\Downloads\\agriflow\\ui-ux\\ManagerDashboard Mobile UI\\Manager Dashboard UIUX.html', 'utf8');

function extractJsFunction(html, fnName) {
  const idx = html.indexOf(fnName);
  if (idx === -1) return `${fnName} NOT FOUND`;
  return html.substring(idx - 20, idx + 1500);
}

console.log('=== ADMIN: renderAllFarmers ===');
console.log(extractJsFunction(adminHtml, 'renderAllFarmers'));

console.log('\n=== MANAGER: renderAllFarmers ===');
console.log(extractJsFunction(managerHtml, 'renderAllFarmers'));

console.log('\n=== ADMIN: openFarmerView ===');
console.log(extractJsFunction(adminHtml, 'openFarmerView'));

console.log('\n=== MANAGER: openFarmerView / openFarmerProfile ===');
console.log(extractJsFunction(managerHtml, 'openFarmerProfile'));
