const fs = require('fs');

['AdminMobile UIUX.html', 'Manager Dashboard UIUX.html'].forEach(filename => {
  console.log(`\n======================================================`);
  console.log(`FILE: ${filename}`);
  console.log(`======================================================`);
  const content = fs.readFileSync(filename, 'utf8');

  const idx = content.indexOf('function renderInventory');
  if (idx !== -1) {
    console.log(content.substring(idx, idx + 2500));
  } else {
    console.log('renderInventory not found');
  }
});
