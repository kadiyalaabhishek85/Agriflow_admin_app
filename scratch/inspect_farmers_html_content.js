const fs = require('fs');

const adminHtml = fs.readFileSync('C:\\Users\\DELL\\Downloads\\agriflow\\ui-ux\\AdminDashboard Mobile UI\\AdminMobile UIUX.html', 'utf8');
const managerHtml = fs.readFileSync('C:\\Users\\DELL\\Downloads\\agriflow\\ui-ux\\ManagerDashboard Mobile UI\\Manager Dashboard UIUX.html', 'utf8');

function extractScreen(html, screenId) {
  const start = html.indexOf(`id="${screenId}"`);
  if (start === -1) return 'NOT FOUND';
  // Find opening tag
  const tagStart = html.lastIndexOf('<section', start);
  const end = html.indexOf('</section>', start);
  return html.substring(tagStart, end + 10);
}

console.log('=== ADMIN SCREEN ALL FARMERS ===');
console.log(extractScreen(adminHtml, 'screen-all-farmers'));

console.log('\n=== MANAGER SCREEN ALL FARMERS ===');
console.log(extractScreen(managerHtml, 'screen-all-farmers'));
