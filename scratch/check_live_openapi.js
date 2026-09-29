const https = require('https');

https.get('https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const openapi = JSON.parse(data);
      console.log('OpenAPI Title:', openapi.info.title, 'Version:', openapi.info.version);
      const schemas = openapi.components?.schemas || {};
      
      const inspectSchema = (name) => {
        console.log(`\n=== SCHEMA: ${name} ===`);
        if (!schemas[name]) {
          console.log('NOT FOUND');
          return;
        }
        console.log('Properties:', Object.keys(schemas[name].properties || {}));
        console.log('Details:', JSON.stringify(schemas[name].properties, null, 2));
      };

      inspectSchema('SeedCreate');
      inspectSchema('SeedUpdate');
      inspectSchema('SeedPublic');
      inspectSchema('SeedOut');
      inspectSchema('SeedPurchaseIn');
      inspectSchema('SeedPurchaseReceipt');

      console.log('\n=== SEED PATHS ===');
      for (const p in openapi.paths) {
        if (p.includes('seed')) {
          console.log(p, Object.keys(openapi.paths[p]));
        }
      }

      console.log('\n=== UPLOAD PATHS ===');
      for (const p in openapi.paths) {
        if (p.includes('upload')) {
          console.log(p, Object.keys(openapi.paths[p]));
        }
      }

      console.log('\n=== WAREHOUSE PATHS ===');
      for (const p in openapi.paths) {
        if (p.includes('warehouse')) {
          console.log(p, Object.keys(openapi.paths[p]));
        }
      }
    } catch(e) {
      console.error('Parse error:', e.message);
    }
  });
}).on('error', err => console.error('HTTP error:', err.message));
