const https = require('https');

https.get('https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const openapi = JSON.parse(data);
    console.log('/api/v1/uploads/presign:', JSON.stringify(openapi.paths['/api/v1/uploads/presign'], null, 2));
    console.log('/api/v1/uploads:', JSON.stringify(openapi.paths['/api/v1/uploads'], null, 2));
  });
});
