const fs = require('fs');

function inspectHTML(fileName) {
  console.log('==============================================');
  console.log('INSPECTING:', fileName);
  console.log('==============================================');
  const content = fs.readFileSync(fileName, 'utf8');

  // Search for screen IDs
  const screens = [...content.matchAll(/id=["'](screen-[^"']+)["']/g)].map(m => m[1]);
  console.log('All screens:', screens);

  // Search specifically for screen-farm-visits or visits
  const visitScreens = screens.filter(s => s.includes('visit'));
  console.log('Visit screens:', visitScreens);

  // Search for the section containing visit
  const startIdx = content.indexOf('id="screen-farm-visits"');
  if (startIdx !== -1) {
    console.log('Found screen-farm-visits at index', startIdx);
    // Find next screen or end of section
    const nextScreenIdx = content.indexOf('id="screen-', startIdx + 20);
    const sliceEnd = nextScreenIdx !== -1 ? nextScreenIdx : startIdx + 10000;
    const section = content.substring(startIdx - 100, sliceEnd);
    console.log('--- SECTION PREVIEW (first 4000 chars) ---');
    console.log(section.substring(0, 4000));
    console.log('--- SECTION PREVIEW (next 4000 chars) ---');
    console.log(section.substring(4000, 8000));
  } else {
    console.log('screen-farm-visits NOT directly found. Searching for visits...');
    const lines = content.split('\n');
    lines.forEach((l, idx) => {
      if (l.toLowerCase().includes('visit') && l.includes('screen')) {
        console.log(`Line ${idx}: ${l.trim()}`);
      }
    });
  }
}

inspectHTML('AdminMobile UIUX.html');
inspectHTML('Manager Dashboard UIUX.html');
