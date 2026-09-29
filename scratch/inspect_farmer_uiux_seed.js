const fs = require('fs');

const path = 'agriflow/ui-ux/FarmersMobileApp UI/Farmers UIUX.html';
const html = fs.readFileSync(path, 'utf8');

console.log('=== SEED PURCHASE IN Farmers UIUX.html ===');
// Search for crop-grade or modal-seed-purchase or seed purchase
const idx = html.indexOf('crop-grade');
if (idx !== -1) {
  console.log(html.substring(idx - 500, idx + 2500));
} else {
  console.log('crop-grade not found');
}
