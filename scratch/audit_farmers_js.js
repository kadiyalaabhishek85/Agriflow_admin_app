const fs = require('fs');

function extractJsForFarmers(filename) {
  console.log(`\n====================================\nJS IN ${filename}`);
  const content = fs.readFileSync(filename, 'utf8');
  
  // Look for functions mentioning 'farmer' or 'renderFarmers'
  const regex = /function\s+([a-zA-Z0-9_]*farmer[a-zA-Z0-9_]*)\s*\([^)]*\)\s*\{/gi;
  let match;
  while ((match = regex.exec(content)) !== null) {
    const fnName = match[1];
    console.log('Found function:', fnName);
    const startIdx = match.index;
    console.log(content.substring(startIdx, startIdx + 1200));
    console.log('------------------------------------');
  }
}

extractJsForFarmers('AdminMobile UIUX.html');
extractJsForFarmers('Manager Dashboard UIUX.html');
