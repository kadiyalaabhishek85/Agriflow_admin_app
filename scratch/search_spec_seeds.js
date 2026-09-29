const fs = require('fs');
const content = fs.readFileSync('agriflow/agriflow-web/Backend_Technical_Specification.md', 'utf8');

const lines = content.split('\n');
lines.forEach((line, i) => {
  if (line.toLowerCase().includes('seed') && (line.toLowerCase().includes('inventory') || line.toLowerCase().includes('stock') || line.toLowerCase().includes('admin'))) {
    console.log(`Line ${i + 1}: ${line}`);
  }
});
