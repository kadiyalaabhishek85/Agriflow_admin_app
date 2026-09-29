import pg from 'pg';
import fs from 'fs';

const envContent = fs.readFileSync('.env', 'utf-8');
const dbUrlLine = envContent.split('\n').find(line => line.startsWith('DATABASE_URL='));
const dbUrl = dbUrlLine.split('=')[1].trim();

const { Client } = pg;

async function enableRls() {
  const client = new Client({
    connectionString: dbUrl
  });
  
  try {
    await client.connect();
    console.log("Connected to database");
    
    // Get all tables in public schema
    const result = await client.query(`
      SELECT tablename 
      FROM pg_tables 
      WHERE schemaname = 'public';
    `);
    
    const tables = result.rows.map(row => row.tablename);
    console.log("Found tables:", tables);
    
    for (const table of tables) {
      console.log(`Enabling RLS for ${table}...`);
      await client.query(`ALTER TABLE "${table}" ENABLE ROW LEVEL SECURITY;`);
    }
    
    console.log("Successfully enabled RLS on all tables.");
  } catch (error) {
    console.error("Error:", error);
  } finally {
    await client.end();
  }
}

enableRls();
