const fs = require('fs');

const adminHtml = fs.readFileSync('C:\\Users\\DELL\\Downloads\\agriflow\\ui-ux\\AdminDashboard Mobile UI\\AdminMobile UIUX.html', 'utf8');
const managerHtml = fs.readFileSync('C:\\Users\\DELL\\Downloads\\agriflow\\ui-ux\\ManagerDashboard Mobile UI\\Manager Dashboard UIUX.html', 'utf8');

function extractBlock(html, id) {
  const start = html.indexOf(`id="${id}"`);
  if (start === -1) return `ID ${id} NOT FOUND`;
  const tagStart = html.lastIndexOf('<div', start);
  // Grab next 2000 chars
  return html.substring(tagStart, tagStart + 2500);
}

console.log('=== ADMIN overlay-farmer-view ===');
console.log(extractBlock(adminHtml, 'overlay-farmer-view'));

console.log('\n=== MANAGER flow-add-farmer ===');
console.log(extractBlock(managerHtml, 'flow-add-farmer'));

console.log('\n=== MANAGER flow-farmer-profile ===');
console.log(extractBlock(managerHtml, 'flow-farmer-profile'));
