const https = require('https');

function login() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ phone: '9999900000', password: 'Admin@123' });
    const req = https.request('https://agriflow-backend-t8o4.onrender.com/api/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve(JSON.parse(body).data.access_token));
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

async function run() {
  const token = await login();

  // Fetch first visit
  const listRes = await request('GET', '/api/v1/farm-visits?page=1&page_size=1', null, token);
  const firstVisit = listRes.data.data[0];
  console.log('First visit:', JSON.stringify(firstVisit, null, 2));

  // Test PATCH schedule (re-saving same scheduled_date)
  const patchRes = await request('PATCH', '/api/v1/farm-visits/' + firstVisit.id + '/schedule', {
    scheduled_date: firstVisit.scheduled_date
  }, token);
  console.log('PATCH schedule response:', patchRes.status, JSON.stringify(patchRes.data, null, 2));
}

run();
