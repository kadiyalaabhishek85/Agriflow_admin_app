const https = require('https');

function login() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ phone: '9999900000', password: 'Admin@123' });
    const req = https.request('https://agriflow-backend-t8o4.onrender.com/api/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (parsed.data && parsed.data.access_token) {
            resolve(parsed.data.access_token);
          } else {
            console.log('Login failed body:', body);
            reject(new Error('Login failed'));
          }
        } catch(e) {
          console.log('Error parsing login response:', body);
          reject(e);
        }
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function request(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const headers = { 'Authorization': 'Bearer ' + token };
    let data;
    if (body) {
      data = JSON.stringify(body);
      headers['Content-Type'] = 'application/json';
      headers['Content-Length'] = Buffer.byteLength(data);
    }
    const req = https.request('https://agriflow-backend-t8o4.onrender.com' + path, {
      method,
      headers
    }, (res) => {
      let resBody = '';
      res.on('data', chunk => resBody += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(resBody) });
        } catch(e) {
          resolve({ status: res.statusCode, body: resBody });
        }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function testCancel() {
  const token = await login();

  const dummyId = '93fb433b-af5e-4f19-8627-3e9a240e4c69';

  console.log('Testing PATCH /api/v1/farm-visits/' + dummyId + '/cancel');
  let res = await request('PATCH', '/api/v1/farm-visits/' + dummyId + '/cancel', {}, token);
  console.log('Result:', res.status, res.data || res.body);

  console.log('Testing POST /api/v1/farm-visits/' + dummyId + '/cancel');
  res = await request('POST', '/api/v1/farm-visits/' + dummyId + '/cancel', {}, token);
  console.log('Result:', res.status, res.data || res.body);

  console.log('Testing DELETE /api/v1/farm-visits/' + dummyId);
  res = await request('DELETE', '/api/v1/farm-visits/' + dummyId, null, token);
  console.log('Result:', res.status, res.data || res.body);
}

testCancel();
