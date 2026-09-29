const fs = require('fs');
const content = fs.readFileSync('Manager Dashboard UIUX.html', 'utf8');
const matches = [...content.matchAll(/type==='farmer'/g)];
matches.forEach((m, i) => {
  console.log(`--- Match ${i} at ${m.index} ---`);
  console.log(content.substring(m.index - 50, m.index + 500));
});
