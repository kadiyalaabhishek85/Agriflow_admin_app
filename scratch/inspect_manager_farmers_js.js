const fs = require('fs');
const managerHtml = fs.readFileSync('C:\\Users\\DELL\\Downloads\\agriflow\\ui-ux\\ManagerDashboard Mobile UI\\Manager Dashboard UIUX.html', 'utf8');

const idx = managerHtml.indexOf('function renderAllFarmers');
console.log(managerHtml.substring(idx, idx + 1500));
