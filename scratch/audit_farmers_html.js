const fs = require('fs');

function extractScreen(filename, screenId) {
  console.log(`\n====================================\nFILE: ${filename}, SCREEN: ${screenId}`);
  const content = fs.readFileSync(filename, 'utf8');
  const idx = content.indexOf(`id="${screenId}"`);
  if (idx === -1) {
    console.log('Screen not found:', screenId);
    return;
  }
  // print next 2500 chars
  console.log(content.substring(idx - 50, idx + 3500));
}

function findParentScreen(filename, elementId) {
  console.log(`\n====================================\nFIND PARENT SCREEN FOR: ${elementId} IN ${filename}`);
  const content = fs.readFileSync(filename, 'utf8');
  const idx = content.indexOf(`id="${elementId}"`);
  if (idx === -1) {
    console.log('Element not found');
    return;
  }
  // search backwards for class="screen" or id="screen-"
  const before = content.substring(Math.max(0, idx - 4000), idx);
  const matches = [...before.matchAll(/id=["'](screen-[^"']+)["']/g)];
  if (matches.length > 0) {
    const parentId = matches[matches.length - 1][1];
    console.log('Parent screen ID:', parentId);
    extractScreen(filename, parentId);
  } else {
    console.log('No parent screen- found');
  }
}

findParentScreen('AdminMobile UIUX.html', 'all-farmers-list');
findParentScreen('Manager Dashboard UIUX.html', 'all-farmers-list');

extractScreen('AdminMobile UIUX.html', 'overlay-farmer-view');
extractScreen('Manager Dashboard UIUX.html', 'overlay-farmer-view');
extractScreen('Manager Dashboard UIUX.html', 'flow-farmer-profile');
extractScreen('Manager Dashboard UIUX.html', 'flow-add-farmer');
