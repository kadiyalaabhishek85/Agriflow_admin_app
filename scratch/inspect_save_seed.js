const fs = require('fs');
const content = fs.readFileSync('AdminMobile UIUX.html', 'utf8');

const idx = content.indexOf('function saveSeed');
if (idx !== -1) {
  console.log(content.substring(idx, idx + 1500));
}
