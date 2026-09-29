const https = require('https');

https.get('https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const openapi = JSON.parse(data);
    const schemas = openapi.components?.schemas || {};
    console.log('PresignUploadRequest:', schemas['PresignUploadRequest']);
    console.log('DirectUploadResponse:', schemas['DirectUploadResponse']);
    console.log('Body_upload_file:', schemas['Body_upload_file_api_v1_uploads_post']);
  });
});
