const fs = require('fs');

const text = fs.readFileSync('Manager Dashboard UIUX.html', 'utf8');

const fnIdx = text.indexOf('function openWarehouseInventory');
if (fnIdx !== -1) {
  console.log('=== openWarehouseInventory ===');
  console.log(text.substring(fnIdx, fnIdx + 2000));
}

const flowIdx = text.indexOf('id="flow-warehouse-inventory"');
if (flowIdx !== -1) {
  console.log('=== flow-warehouse-inventory ===');
  console.log(text.substring(flowIdx, flowIdx + 3000));
}
