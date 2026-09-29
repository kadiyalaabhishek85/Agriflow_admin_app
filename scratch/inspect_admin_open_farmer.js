const fs = require('fs');
const adminHtml = fs.readFileSync('C:\\Users\\DELL\\Downloads\\agriflow\\ui-ux\\AdminDashboard Mobile UI\\AdminMobile UIUX.html', 'utf8');

const idx = adminHtml.indexOf('function openFarmerView');
console.log('=== ADMIN openFarmerView full ===');
console.log(adminHtml.substring(idx, idx + 2000));
