const fs = require('fs');

['AdminMobile UIUX.html', 'Manager Dashboard UIUX.html'].forEach(file => {
  console.log(`\n================== ${file} ==================`);
  const text = fs.readFileSync(file, 'utf8');
  const screens = [...text.matchAll(/id="(screen-[^"]+)"/g)].map(m => m[1]);
  console.log('Screens in order of appearance:');
  screens.forEach((s, i) => console.log(`  ${i + 1}. ${s}`));

  // Also check drawer items
  const drawerMatch = text.match(/class="drawer-panel"[\s\S]*?<\/nav>/) || text.match(/class="drawer[^"]*"[\s\S]*?<\/nav>/);
  if (drawerMatch) {
    const items = [...drawerMatch[0].matchAll(/onclick="[^"]*showScreen\('([^']+)'\)[^>]*>([\s\S]*?)<\/div>/g)];
    console.log('Drawer items:');
    items.forEach(it => {
      const cleanText = it[2].replace(/<[^>]+>/g, '').trim();
      console.log(`  Target: ${it[1]} -> Label: ${cleanText}`);
    });
  }
});
