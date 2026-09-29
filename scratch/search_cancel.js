const fs = require('fs');

function searchCancel() {
  const content = fs.readFileSync('agriflow/agriflow-web/src/pages/admin/FarmVisits.jsx', 'utf8');
  const lines = content.split('\n');
  console.log('=== MATCHES IN FarmVisits.jsx ===');
  lines.forEach((line, i) => {
    if (line.toLowerCase().includes('cancel')) {
      console.log('Line ' + (i+1) + ': ' + line.trim());
    }
  });

  // Let's also check all occurrences of handleAction or updateVisit
  console.log('\n=== USAGES OF updateVisit IN FarmVisits.jsx ===');
  lines.forEach((line, i) => {
    if (line.includes('updateVisit')) {
      console.log('Line ' + (i+1) + ': ' + line.trim());
    }
  });

  // Let's check status buttons or transitions
  console.log('\n=== STATUS BUTTONS / ACTIONS IN FarmVisits.jsx ===');
  lines.forEach((line, i) => {
    if (line.includes('handleAction') || line.includes('status') && line.includes('button')) {
      console.log('Line ' + (i+1) + ': ' + line.trim());
    }
  });
}

searchCancel();
