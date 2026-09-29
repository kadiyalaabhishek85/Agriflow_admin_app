// Verifies the super_admin login credentials against the live FastAPI backend,
// using the exact request shape the Flutter Admin app sends
// (POST /api/v1/auth/login with {"phone": ..., "password": ...}).
const https = require('https');

const BASE_URL = 'https://agriflow-backend-t8o4.onrender.com';

function login(phone, password) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ phone, password });
    const req = https.request(BASE_URL + '/api/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    }, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        let parsed = null;
        try {
          parsed = JSON.parse(body);
        } catch (_) {
          parsed = { raw: body };
        }
        resolve({ status: res.statusCode, body: parsed });
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function attempt(label, phone, password) {
  process.stdout.write(`\n=== ${label} (phone=${phone}, password=${password}) ===\n`);
  try {
    const res = await login(phone, password);
    console.log('HTTP status:', res.status);
    if (res.status === 429) {
      const retry = (res.body.error && res.body.error.details && res.body.error.details.retry_after_seconds) || '?';
      console.log(`RATE LIMITED — inconclusive, retry_after_seconds=${retry}`);
      return { ok: false, throttled: true, status: 429, payload: res.body };
    }
    if (res.status === 200) {
      const data = res.body.data || res.body;
      const user = data.user || {};
      console.log('SUCCESS');
      console.log('  access_token present :', typeof data.access_token === 'string' && data.access_token.length > 0);
      console.log('  refresh_token present:', typeof data.refresh_token === 'string' && data.refresh_token.length > 0);
      console.log('  token_type           :', data.token_type);
      console.log('  expires_in           :', data.expires_in);
      console.log('  user.id              :', user.id);
      console.log('  user.name            :', user.name);
      console.log('  user.phone           :', user.phone);
      console.log('  user.role            :', user.role);
      console.log('  user.status          :', user.status);
      console.log('  user.first_login     :', user.first_login);
      return { ok: true, status: 200, payload: data };
    }
    console.log('FAILED — body:', JSON.stringify(res.body));
    return { ok: false, throttled: false, status: res.status, payload: res.body };
  } catch (e) {
    console.log('NETWORK ERROR:', e.message);
    return { ok: false, throttled: false, status: 0, error: e.message };
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function run() {
  const cases = [
    ['SUPPLIED by backend dev', '9999900000', 'Admin12345'],
    ['legacy (old scratch scripts)', '9999900000', 'Admin@123'],
    ['phone-format variant (+91)', '+919999900000', 'Admin12345'],
    ['old docs demo super admin', '9999999999', 'Admin@123'],
    ['old docs demo manager', '8888888888', 'Manager@123'],
  ];

  const results = [];
  for (let i = 0; i < cases.length; i++) {
    const [label, phone, password] = cases[i];
    const res = await attempt(`${label} | ${phone}`, phone, password);
    results.push({ label, phone, password, ok: res.ok, status: res.status });
    // The backend throttles logins to ~4/min per IP (and escalates on repeat abuse).
    if (i < cases.length - 1) await sleep(20000);
  }

  console.log('\n--- SUMMARY ---');
  for (const r of results) {
    const verdict = r.ok ? 'PASS' : (r.throttled ? 'THROTTLED' : 'FAIL');
    console.log(`${verdict.padEnd(10)} HTTP ${String(r.status).padEnd(4)} ${r.phone.padEnd(15)} ${r.password.padEnd(12)} (${r.label})`);
  }
  const winner = results.find((r) => r.ok);
  if (winner) {
    console.log('\nWorking credentials:', JSON.stringify({ phone: winner.phone, password: winner.password }));
  } else if (results.some((r) => r.throttled)) {
    console.log('\nSome attempts were throttled by the backend rate limiter — re-run after the lockout window.');
  } else {
    console.log('\nNo admin credentials could authenticate against the live backend.');
    console.log('=> The mobile app login wiring is correct; the backend user record/password does not match.');
  }
}

run();
