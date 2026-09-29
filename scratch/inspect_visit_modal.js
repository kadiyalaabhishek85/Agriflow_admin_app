const fs = require('fs');

function inspectModal(fileName) {
  console.log('=== FILE:', fileName);
  const content = fs.readFileSync(fileName, 'utf8');

  // Search for openVisit or data-open-visit handler or visit modal/sheet
  const matches = [...content.matchAll(/function\s+openVisit[^{]*\{([\s\S]*?)\n\s*function/g)];
  if (matches.length > 0) {
    matches.forEach(m => console.log(m[0].substring(0, 3000)));
  } else {
    // Search for data-open-visit
    const idx = content.indexOf('data-open-visit');
    if (idx !== -1) {
      console.log('Found data-open-visit in file. Let us search for click listeners:');
      const clickIdx = content.indexOf('open-visit', idx + 20);
      if (clickIdx !== -1) {
        console.log(content.substring(clickIdx - 100, clickIdx + 2000));
      }
    }
    // Search for visit-modal or visit-sheet
    const modalIdx = content.indexOf('modal-visit') !== -1 ? content.indexOf('modal-visit') : content.indexOf('visit-detail');
    if (modalIdx !== -1) {
      console.log('Found modal at', modalIdx);
      console.log(content.substring(modalIdx - 100, modalIdx + 2000));
    }
  }
}

inspectModal('AdminMobile UIUX.html');
inspectModal('Manager Dashboard UIUX.html');
