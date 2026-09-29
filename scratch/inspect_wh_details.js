const fs = require('fs');

['AdminMobile UIUX.html', 'Manager Dashboard UIUX.html'].forEach(file => {
  console.log(`\n================== ${file} ==================`);
  const text = fs.readFileSync(file, 'utf8');
  
  // Find screen-warehouse
  const start = text.indexOf('id="screen-warehouse"');
  if (start !== -1) {
    const end = text.indexOf('</section>', start);
    console.log(text.substring(start, end + 10));
  }
  
  // Find warehouse flows or modals
  const flows = [...text.matchAll(/id="(flow-warehouse[^"]*|flow-add-inv[^"]*|flow-add-slot[^"]*)"[\s\S]*?<\/div>\s*<\/div>/g)];
  flows.forEach(f => console.log('FLOW FOUND:', f[1]));
  
  // Find warehouse JS logic
  const whRender = text.match(/function renderWarehouse[\s\S]*?^}/m) || text.match(/function renderWarehouses[\s\S]*?^}/m);
  if (whRender) {
    console.log('\nJS render function:');
    console.log(whRender[0].substring(0, 1500));
  }
});
