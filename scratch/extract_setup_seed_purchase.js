const fs = require('fs');

const path = 'agriflow/ui-ux/FarmersMobileApp UI/Farmers UIUX.html';
const html = fs.readFileSync(path, 'utf8');

const setupIdx = html.indexOf('function setupSeedPurchase') !== -1
  ? html.indexOf('function setupSeedPurchase')
  : html.indexOf('setupSeedPurchase');

if (setupIdx !== -1) {
  console.log('=== setupSeedPurchase implementation ===');
  console.log(html.substring(setupIdx, setupIdx + 4000));
} else {
  console.log('setupSeedPurchase not found');
}
