const https = require('https');

function request(options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, headers: res.headers, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, headers: res.headers, raw: data });
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(typeof body === 'string' ? body : JSON.stringify(body));
    req.end();
  });
}

async function main() {
  console.log('--- 1. Login as Super Admin ---');
  const loginRes = await request({
    hostname: 'agriflow-backend-t8o4.onrender.com',
    path: '/api/v1/auth/login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, {
    phone: '9999999999',
    password: 'Admin@123'
  });

  const token = loginRes.body?.data?.access_token || loginRes.body?.access_token;
  console.log('Token acquired:', token ? 'YES' : 'NO');
  if (!token) {
    console.log('Login response:', loginRes.body);
    return;
  }

  console.log('\n--- 2. Fetch Grain Sales ---');
  const salesRes = await request({
    hostname: 'agriflow-backend-t8o4.onrender.com',
    path: '/api/v1/grain-sales?page=1&page_size=50',
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json'
    }
  });

  const sales = salesRes.body?.data || [];
  console.log(`Found ${sales.length} grain sales:`);
  const statusCounts = {};
  sales.forEach(s => {
    statusCounts[s.status] = (statusCounts[s.status] || 0) + 1;
    console.log(`  ID: ${s.id} | Status: [${s.status}] | Grain: ${s.grain_type} | Total: ₹${s.total_amount}`);
  });
  console.log('Status counts:', statusCounts);

  const receivedSale = sales.find(s => s.status === 'received');
  const approvedSale = sales.find(s => s.status === 'approved');

  if (receivedSale) {
    console.log(`\n--- 3. Testing PATCH /api/v1/grain-sales/${receivedSale.id}/pay on [received] sale ---`);
    const payReceivedRes = await request({
      hostname: 'agriflow-backend-t8o4.onrender.com',
      path: `/api/v1/grain-sales/${receivedSale.id}/pay`,
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    }, {
      payment_reference: 'TEST_PAY_REF_REC'
    });
    console.log('Response Status:', payReceivedRes.status);
    console.log('Response Body:', JSON.stringify(payReceivedRes.body || payReceivedRes.raw, null, 2));
  } else {
    console.log('No received sale found.');
  }

  if (approvedSale) {
    console.log(`\n--- 4. Checking approved sale info ---`);
    console.log(`Approved sale ID: ${approvedSale.id}`);
  }
}

main().catch(console.error);
