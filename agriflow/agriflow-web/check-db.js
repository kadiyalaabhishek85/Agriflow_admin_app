import pg from 'pg';
import fs from 'fs';

const envFile = fs.readFileSync('.env', 'utf8');
const env = {};
envFile.split('\n').forEach(line => {
  const match = line.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/);
  if (match) {
    let value = match[2] || '';
    if (value.startsWith('"') && value.endsWith('"')) value = value.slice(1, -1);
    env[match[1]] = value;
  }
});

const client = new pg.Client({ connectionString: env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

async function run() {
  try {
    await client.connect();

    // Check slots for 2026-07-21
    const res1 = await client.query(`SELECT * FROM warehouse_slots WHERE slot_date = '2026-07-21'`);
    console.log('Slots for 2026-07-21:', JSON.stringify(res1.rows, null, 2));

    // Check all active slots  
    const res2 = await client.query(`SELECT id, warehouse_id, slot_date, start_time, end_time, total_capacity_kg, booked_capacity_kg, status FROM warehouse_slots WHERE status = 'active' ORDER BY slot_date DESC`);
    console.log('All active slots:', JSON.stringify(res2.rows, null, 2));

    // Check the actual create_booking_slot function definition
    const res3 = await client.query(`
      SELECT prosrc FROM pg_proc WHERE proname = 'create_booking_slot';
    `);
    console.log('create_booking_slot source:', res3.rows[0]?.prosrc?.substring(0, 500));

  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    await client.end();
  }
}
run();
