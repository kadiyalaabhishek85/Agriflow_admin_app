const fs = require('fs');
const content = fs.readFileSync('AdminMobile UIUX.html', 'utf8');

const drawerIdx = content.indexOf('class="drawer-panel"');
if (drawerIdx !== -1) {
  console.log(content.substring(drawerIdx, drawerIdx + 4000));
} else {
  console.log('drawer-panel not found');
}
