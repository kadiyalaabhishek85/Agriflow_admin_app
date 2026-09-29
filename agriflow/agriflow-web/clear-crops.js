import pg from 'pg';
import fs from 'fs';

const envContent = fs.readFileSync('.env', 'utf-8');
const dbUrlLine = envContent.split('\n').find(line => line.startsWith('DATABASE_URL='));
const dbUrl = dbUrlLine.split('=')[1].trim();

const { Client } = pg;

async function clearCrops() {
  const client = new Client({
    connectionString: dbUrl
  });
  
  try {
    await client.connect();
    console.log("Connected to database");
    
    // Delete all records from the crops table
    const result = await client.query('DELETE FROM crops;');
    
    console.log(`Successfully deleted all records from the crops table. Rows affected: ${result.rowCount}`);
    
  } catch (error) {
    console.error("Error clearing crops table:", error);
  } finally {
    await client.end();
  }
}

clearCrops();
