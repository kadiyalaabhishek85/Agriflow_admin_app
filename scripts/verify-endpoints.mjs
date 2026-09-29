// Gate oracle for the build/endpoint/workflow review.
// Modes:
//   contract — extract every backend path the Flutter app references in lib/,
//              fetch the live OpenAPI contract, and require each client path to
//              exist in the deployed contract. Runs a built-in positive control
//              (self-test) before trusting any absence result.
//   probes   — live service probes with a negative control: an unknown path
//              must return 404 (otherwise probe semantics are meaningless),
//              public endpoints must be 200, and a representative set of
//              auth-guarded routes+methods must be reachable (401/422).
import fs from 'node:fs';
import path from 'node:path';

const BASE = 'https://agriflow-backend-t8o4.onrender.com';
const MODE = process.argv[2];

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.name.endsWith('.dart')) out.push(p);
  }
  return out;
}

function normalize(raw) {
  // interpolate Dart variables: /seeds/$seedId -> /seeds/{param}
  let p = raw.replace(/\$\{?[A-Za-z_]\w*\}?/g, '{param}');
  if (!p.startsWith('/')) p = '/' + p;
  if (!p.startsWith('/api/v1')) p = '/api/v1' + p;
  return p;
}

function extractClientPaths() {
  const files = walk('lib');
  const set = new Set();
  const uriCall = /_uri\(\s*'([^']+)'/g;
  const fullParse = /Uri\.parse\(\s*'https:\/\/[^']*\/api\/v1([^']*)'/g;
  for (const f of files) {
    const src = fs.readFileSync(f, 'utf8');
    for (const m of src.matchAll(uriCall)) set.add(normalize(m[1]));
    for (const m of src.matchAll(fullParse)) set.add(normalize(m[1] === '' ? '/' : m[1]));
  }
  return set;
}

async function get(url, method = 'GET') {
  const res = await fetch(url, {
    method,
    redirect: 'manual',
    signal: AbortSignal.timeout(70000),
  });
  return res.status;
}

async function contractMode() {
  const client = extractClientPaths();

  // Fetch deployed contract; a network/parse failure must fail the gate.
  const live = await get(`${BASE}/api/v1/openapi.json`);
  if (live !== 200) {
    console.error(`live openapi.json returned ${live}`);
    process.exit(1);
  }
  const doc = await (await fetch(`${BASE}/api/v1/openapi.json`, { signal: AbortSignal.timeout(70000) })).json();
  // Compare path templates structurally: parameter labels are cosmetic
  // ({booking_id} in the contract, $bookingId in the client).
  const livePaths = new Set(
    Object.keys(doc.paths ?? {}).map((p) => p.replace(/\{[^}]+\}/g, '{param}')),
  );
  const liveOps = Object.values(doc.paths ?? {}).reduce(
    (n, item) => n + Object.keys(item).filter((k) => ['get', 'post', 'put', 'patch', 'delete'].includes(k)).length,
    0,
  );

  // Positive control: extraction must have found a substantial inventory...
  if (client.size < 20) {
    console.error(`self-test failed: only ${client.size} client paths extracted`);
    process.exit(1);
  }
  // ...the membership test must accept a known-real path...
  if (!livePaths.has('/api/v1/seeds')) {
    console.error('self-test failed: live contract missing /api/v1/seeds');
    process.exit(1);
  }
  // ...and must reject a path known to be absent (controls the absence check).
  if (livePaths.has('/api/v1/__selftest_missing__')) {
    console.error('self-test failed: membership accepted a bogus path');
    process.exit(1);
  }

  const missing = [...client].filter((p) => !livePaths.has(p)).sort();
  if (missing.length) {
    console.error('client calls NOT in deployed contract:');
    for (const p of missing) console.error('  ' + p);
    process.exit(1);
  }
  console.log(
    `ENDPOINTS CONNECTED (${client.size} unique client paths, all present in live contract with ${liveOps} ops)`,
  );
}

async function probesMode() {
  const fail = (msg) => {
    console.error(msg);
    process.exit(1);
  };

  // Negative control: unknown path must be 404 or probe semantics prove nothing.
  const control = await get(`${BASE}/api/v1/__probe_missing__`);
  if (control !== 404) fail(`control probe returned ${control}, expected 404`);

  const uuid = '00000000-0000-0000-0000-000000000000';
  const expect200 = [
    '/health',
    '/api/v1/docs',
    '/api/v1/public/market-rates',
    '/api/v1/public/seeds',
    '/api/v1/public/stats',
  ];
  for (const p of expect200) {
    const s = await get(BASE + p);
    if (s !== 200) fail(`${p} returned ${s}, expected 200`);
  }

  // Route+method existence: no credentials are ever sent, so these are
  // non-mutating; an existing guarded route answers 401 (422 accepted where
  // body validation runs first). 404/405 means disconnected.
  const guarded = [
    ['GET', `/api/v1/seeds`],
    ['GET', `/api/v1/seeds/${uuid}`],
    ['GET', `/api/v1/warehouses/${uuid}`],
    ['PATCH', `/api/v1/warehouses/${uuid}`],
    ['DELETE', `/api/v1/warehouses/${uuid}`],
    ['GET', `/api/v1/warehouses/${uuid}/inventory`],
    ['DELETE', `/api/v1/warehouse-slots/${uuid}`],
    ['GET', `/api/v1/seeds/${uuid}/warehouses`],
    ['GET', '/api/v1/notifications'],
    ['GET', '/api/v1/transactions'],
    ['GET', '/api/v1/managers'],
    ['POST', '/api/v1/managers'],
  ];
  let n = expect200.length;
  for (const [method, p] of guarded) {
    const s = await get(BASE + p, method);
    if (s !== 401 && s !== 422) fail(`${method} ${p} returned ${s}, expected 401/422 (route exists)`);
    n++;
  }
  console.log(`PROBES OK (${n} probes, control 404 confirmed)`);
}

if (MODE === 'contract') {
  contractMode().catch((e) => {
    console.error(String(e));
    process.exit(1);
  });
} else if (MODE === 'probes') {
  probesMode().catch((e) => {
    console.error(String(e));
    process.exit(1);
  });
} else {
  console.error('usage: node scripts/verify-endpoints.mjs contract|probes');
  process.exit(2);
}
