const fs = require('fs');

['AdminMobile UIUX.html', 'Manager Dashboard UIUX.html'].forEach(file => {
  console.log(`\n================== ${file} ==================`);
  const text = fs.readFileSync(file, 'utf8');
  
  // Find where warehouse is rendered or handled
  const matches = [...text.matchAll(/warehouse-list|renderWarehouse|flow-warehouse|openWarehouse/g)];
  console.log('Matches:', matches.map(m => m[0]));

  const idx = text.indexOf('warehouse-list');
  if (idx !== -1) {
    // Look at JS usages after the HTML body
    const scriptStart = text.indexOf('<script>');
    if (scriptStart !== -1) {
      const script = text.substring(scriptStart);
      const pos = script.indexOf('warehouse-list');
      if (pos !== -1) {
        console.log('JS usage around warehouse-list:');
        console.log(script.substring(pos - 100, pos + 1500));
      }
    }
  }
});
