const fs = require('fs');

const path = 'agriflow/ui-ux/FarmersMobileApp UI/Farmers UIUX.html';
const html = fs.readFileSync(path, 'utf8');

console.log('=== SEED PURCHASE IN Farmers UIUX.html ===');

// Find the seed purchase modal / form
const formStart = html.indexOf('id="flow-seed-purchase"') !== -1 
  ? html.indexOf('id="flow-seed-purchase"')
  : html.indexOf('modal-seed-purchase') !== -1
  ? html.indexOf('modal-seed-purchase')
  : html.indexOf('Seed Purchase');

console.log('Form Start pos:', formStart);

// Let's search for "crop-grade" context (5000 chars)
const gradeIdx = html.indexOf('name="crop-grade"');
if (gradeIdx !== -1) {
  console.log('\n--- CROP GRADE & PURCHASE FORM HTML ---');
  console.log(html.substring(gradeIdx - 1500, gradeIdx + 3000));
}

// Let's search for the JS that handles seed purchase submission and price calculations
const scriptStart = html.indexOf('<script>');
if (scriptStart !== -1) {
  const script = html.substring(scriptStart);
  console.log('\n--- JS FUNCTIONS FOR SEED PURCHASE ---');
  
  // Find updateGradeUI, submitPurchase, calculateTotal, openSeedPurchase, etc.
  const fnMatches = [...script.matchAll(/function\s+([a-zA-Z0-9_]+)\s*\([^)]*\)\s*\{/g)].map(m => m[1]);
  console.log('Available JS functions:', fnMatches.filter(f => /seed|purchase|grade|price|warehouse|calc/i.test(f)));
  
  const gradeFn = script.match(/window\.updateGradeUI\s*=\s*function[\s\S]*?^(\s*\}|\s*\}\;)/m) || script.match(/function updateGradeUI[\s\S]*?^(\s*\}|\s*\}\;)/m);
  if (gradeFn) {
    console.log('\nupdateGradeUI code:');
    console.log(gradeFn[0]);
  }
}
