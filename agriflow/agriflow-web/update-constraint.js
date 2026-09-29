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

    console.log('Altering check constraint on transactions table...');
    
    // Drop the old constraint
    await client.query(`ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_reference_type_check;`);
    
    // Add the new constraint with 'billing' included
    await client.query(`
      ALTER TABLE transactions 
      ADD CONSTRAINT transactions_reference_type_check 
      CHECK (reference_type IN ('seed_purchase', 'grain_sale', 'billing', 'other'));
    `);
    
    console.log('Successfully updated constraint!');

  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    await client.end();
  }
}
run();
