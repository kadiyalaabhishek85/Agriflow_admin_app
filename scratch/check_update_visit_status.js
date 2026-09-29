const fs = require('fs');

const content = fs.readFileSync('AdminMobile UIUX.html', 'utf8');
const idx = content.indexOf('function updateVisitStatus');
if (idx !== -1) {
  console.log(content.substring(idx, idx + 1000));
} else {
  console.log('function updateVisitStatus not found as function definition. Searching for updateVisitStatus...');
  const lines = content.split('\n');
  lines.forEach((l, i) => {
    if (l.includes('updateVisitStatus')) {
      console.log('Line ' + (i+1) + ': ' + l.trim());
    }
  });
}
