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
    
    // Count notifications
    const countRes = await client.query('SELECT count(*) FROM notifications');
    console.log('Total notifications in DB:', countRes.rows[0].count);

    // Latest 10 notifications
    const latestRes = await client.query('SELECT id, user_id, title, message, type, is_read, created_at FROM notifications ORDER BY created_at DESC LIMIT 10');
    console.log('Latest 10 notifications:', latestRes.rows);

    // Check users
    const usersRes = await client.query('SELECT id, name, role, status FROM users LIMIT 10');
    console.log('Users in public.users table:', usersRes.rows);
  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    await client.end();
  }
}

run();
