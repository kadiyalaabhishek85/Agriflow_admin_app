const fs = require('fs');

['AdminMobile UIUX.html', 'Manager Dashboard UIUX.html'].forEach(file => {
  console.log(`\n================== ${file} ==================`);
  const text = fs.readFileSync(file, 'utf8');
  const idx = text.indexOf('id="screen-warehouse"');
  if (idx !== -1) {
    console.log(text.substring(idx - 30, idx + 4500));
  } else {
    console.log('screen-warehouse not found');
  }
});
