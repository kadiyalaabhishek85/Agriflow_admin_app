const fs = require('fs');

['AdminMobile UIUX.html', 'Manager Dashboard UIUX.html'].forEach(file => {
  console.log('=== FILE:', file);
  const text = fs.readFileSync(file, 'utf8');
  const screens = [...text.matchAll(/id="([^"]*(?:screen|flow|overlay|view)[^"]*)"/gi)].map(m => m[1]);
  console.log('Screens/Overlays:', Array.from(new Set(screens)));
  
  // Find drawer items or links
  const drawerLinks = [...text.matchAll(/class="[^"]*drawer[^"]*"[\s\S]*?<\/div>/gi)];
  console.log('Drawer occurrences found:', drawerLinks.length);
});
