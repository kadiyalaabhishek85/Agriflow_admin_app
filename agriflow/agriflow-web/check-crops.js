import pg from 'pg';
import fs from 'fs';

const envContent = fs.readFileSync('.env', 'utf-8');
const dbUrlLine = envContent.split('\n').find(line => line.startsWith('DATABASE_URL='));
const dbUrl = dbUrlLine.split('=')[1].trim();

const { Client } = pg;

async function checkSchema() {
  const client = new Client({
    connectionString: dbUrl
  });
  
  try {
    await client.connect();
    
    const result = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'crops';
    `);
    
    console.log("Crops table schema:");
    result.rows.forEach(r => console.log(`- ${r.column_name} (${r.data_type})`));
    
  } catch (error) {
    console.error("Error:", error);
  } finally {
    await client.end();
  }
}

checkSchema();
