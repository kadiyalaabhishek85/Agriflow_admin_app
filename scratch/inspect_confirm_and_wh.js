const fs = require('fs');

const path = 'agriflow/ui-ux/FarmersMobileApp UI/Farmers UIUX.html';
const html = fs.readFileSync(path, 'utf8');

const confirmIdx = html.indexOf('btnConfirm.onclick');
if (confirmIdx !== -1) {
  console.log('=== btnConfirm.onclick ===');
  console.log(html.substring(confirmIdx, confirmIdx + 2000));
}

// Also let's check warehouse select options in modal-purchase
const whIdx = html.indexOf('id="purchase-warehouse"');
if (whIdx !== -1) {
  console.log('=== purchase-warehouse select ===');
  console.log(html.substring(whIdx - 100, whIdx + 600));
}
