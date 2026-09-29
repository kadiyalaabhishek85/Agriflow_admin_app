import pg from 'pg';
import fs from 'fs';

// Parse .env manually
const envFile = fs.readFileSync('.env', 'utf8');
const env = {};
envFile.split('\n').forEach(line => {
  const match = line.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/);
  if (match) {
    let value = match[2] || '';
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.slice(1, -1);
    }
    env[match[1]] = value;
  }
});

const connectionString = env.DATABASE_URL;
const client = new pg.Client({
  connectionString,
  ssl: {
    rejectUnauthorized: false
  }
});

async function run() {
  try {
    await client.connect();
    
    // Let's find some user UUIDs
    const usersRes = await client.query('SELECT id, name, role, uuid FROM users');
    const users = usersRes.rows;
    console.log('Available users:');
    users.forEach(u => console.log(`ID: ${u.id}, Name: ${u.name}, Role: ${u.role}, UUID: ${u.uuid}`));

    for (const u of users) {
      if (!u.uuid) continue;
      
      console.log(`\nTesting RLS for user ${u.name} (Role: ${u.role}, UUID: ${u.uuid})...`);
      
      // Start transaction to use SET LOCAL
      await client.query('BEGIN');
      
      // Set the JWT claims mock
      const jwtClaims = JSON.stringify({ sub: u.uuid, role: 'authenticated' });
      await client.query(`SELECT set_config('request.jwt.claims', $1, true)`, [jwtClaims]);
      
      // Try to select notifications for this user (mimics what RLS does)
      const res = await client.query(`
        SELECT id, title, message FROM notifications WHERE user_id = $1
      `, [parseInt(u.id)]);
      
      console.log(`Select notifications count: ${res.rows.length}`);
      if (res.rows.length > 0) {
        console.log('Sample notification:', res.rows[0]);
      }
      
      await client.query('ROLLBACK');
    }
  } catch (err) {
    console.error('Error during testing:', err.message);
  } finally {
    await client.end();
  }
}

run();
