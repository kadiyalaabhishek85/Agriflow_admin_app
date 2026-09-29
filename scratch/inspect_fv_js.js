const fs = require('fs');

function inspectJS(fileName) {
  console.log('=== FILE:', fileName);
  const content = fs.readFileSync(fileName, 'utf8');

  // Search for fv-list or renderFarmVisits or similar
  const matches = [...content.matchAll(/function\s+renderFarmVisits[^{]*\{([\s\S]*?)\n\s*function|\/\/ FARM VISITS[\s\S]*?\n\s*\/\//g)];
  if (matches.length > 0) {
    matches.forEach(m => console.log(m[0].substring(0, 3000)));
  } else {
    // Search for where fv-list is manipulated
    const idx = content.indexOf('fv-list');
    if (idx !== -1) {
      console.log('Found fv-list at', idx);
      console.log(content.substring(idx - 200, idx + 2500));
    }
  }
}

inspectJS('AdminMobile UIUX.html');
inspectJS('Manager Dashboard UIUX.html');
