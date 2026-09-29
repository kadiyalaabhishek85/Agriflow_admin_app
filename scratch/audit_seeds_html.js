const fs = require('fs');

function inspectSeedsInHtml(filename) {
  console.log(`\n======================================================`);
  console.log(`FILE: ${filename}`);
  console.log(`======================================================`);
  const content = fs.readFileSync(filename, 'utf8');

  // Find screen-seeds-inventory
  const screenIdx = content.indexOf('id="screen-seeds-inventory"');
  if (screenIdx !== -1) {
    console.log('\n--- SCREEN HTML (first 1500 chars) ---');
    console.log(content.substring(screenIdx, screenIdx + 1500));
  }

  // Find overlays / modals related to seeds: seed form, edit stock, add seed
  const matches = [...content.matchAll(/id="([^"]*seed[^"]*)"/gi)].map(m => m[1]);
  console.log('\n--- SEED RELATED IDs ---');
  console.log(Array.from(new Set(matches)));

  // Find JS functions related to seeds inventory: renderInventory, openSeedForm, etc.
  const jsMatches = [...content.matchAll(/(function\s+[a-zA-Z0-9_]*seed[a-zA-Z0-9_]*\s*\([^)]*\)[\s\S]*?\{[\s\S]*?\n\s*\})/gi)].map(m => m[1]);
  console.log(`\n--- JS SEED FUNCTIONS (${jsMatches.length}) ---`);
  jsMatches.slice(0, 5).forEach(f => console.log(f.substring(0, 400) + '...\n'));
}

inspectSeedsInHtml('AdminMobile UIUX.html');
inspectSeedsInHtml('Manager Dashboard UIUX.html');
