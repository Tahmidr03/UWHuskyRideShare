const { Pool } = require('pg');
require('dotenv').config();

// Database configuration from environment variables
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT ? Number(process.env.DB_PORT) : 5432,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000, // 10 seconds
  allowExitOnIdle: false,
});

// Log DB config in use (without password) - IMMEDIATELY on module load
console.log('\n========================================');
console.log('DATABASE CONFIGURATION');
console.log('========================================');
console.log('DB config in use (without password):', {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT ? Number(process.env.DB_PORT) : 5432,
  user: process.env.DB_USER || '(NOT SET)',
  database: process.env.DB_NAME || '(NOT SET)',
  password: process.env.DB_PASSWORD ? '***SET***' : '(NOT SET)',
});
console.log('========================================\n');

// Log connection pool errors (but don't exit the process)
pool.on('error', (err) => {
  console.error('\n⚠️  Unexpected error on idle PostgreSQL client:', err);
  console.error('Error details:', {
    code: err.code,
    message: err.message,
    host: pool.options.host,
    port: pool.options.port,
    database: pool.options.database,
    user: pool.options.user,
  });
  // Don't exit - let the application handle errors gracefully
});

// Comprehensive diagnostic function - checks connection, tables, and data
async function runDiagnostics() {
  let client;
  console.log('\n========================================');
  console.log('DATABASE DIAGNOSTICS');
  console.log('========================================\n');
  
  try {
    // Step 1: Test connection
    console.log('Step 1: Testing database connection...');
    client = await pool.connect();
    const connectionTest = await client.query('SELECT NOW() as current_time, current_database() as db_name, version() as pg_version');
    console.log('✓ Connection successful!');
    console.log('  Database:', connectionTest.rows[0].db_name);
    console.log('  Server time:', connectionTest.rows[0].current_time);
    console.log('  PostgreSQL version:', connectionTest.rows[0].pg_version.split(',')[0]);
    console.log('');
    
    // Step 2: Check if required tables exist
    console.log('Step 2: Checking required tables...');
    // PostgreSQL converts unquoted identifiers to lowercase, so check for lowercase names
    const requiredTables = ['users', 'vehicles', 'rideoffers', 'riderequests', 'matches', 'ratings', 'bankaccounts'];
    const requiredTableDisplay = ['Users', 'Vehicles', 'RideOffers', 'RideRequests', 'Matches', 'Ratings', 'BankAccounts'];
    
    // Get all tables in public schema
    const allTablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    const allTables = allTablesResult.rows.map(row => row.table_name);
    const existingTables = requiredTables.filter(t => allTables.includes(t));
    const missingTables = requiredTables.filter(t => !allTables.includes(t));
    
    if (missingTables.length === 0) {
      console.log('✓ All required tables exist:');
      existingTables.forEach((t, i) => console.log(`  - ${requiredTableDisplay[requiredTables.indexOf(t)] || t}`));
    } else {
      console.log('⚠️  Missing tables:');
      missingTables.forEach((t, i) => {
        const displayName = requiredTableDisplay[requiredTables.indexOf(t)] || t;
        console.log(`  ✗ ${displayName} (NOT FOUND)`);
      });
      console.log('\n  Existing tables:');
      allTables.forEach(t => console.log(`  - ${t}`));
    }
    console.log('');
    
    // Step 3: Check row counts in each table
    console.log('Step 3: Checking row counts in tables...');
    for (let i = 0; i < requiredTables.length; i++) {
      const table = requiredTables[i];
      const displayName = requiredTableDisplay[i];
      if (existingTables.includes(table)) {
        try {
          const countResult = await client.query(`SELECT COUNT(*) as count FROM "${table}"`);
          const count = parseInt(countResult.rows[0].count);
          const status = count > 0 ? '✓' : '⚠️';
          console.log(`  ${status} ${displayName}: ${count} row(s)`);
        } catch (err) {
          console.log(`  ✗ ${displayName}: ERROR - ${err.message}`);
        }
      } else {
        console.log(`  ✗ ${displayName}: Table does not exist`);
      }
    }
    console.log('');
    
    // Step 4: Test a sample query on each table
    console.log('Step 4: Testing sample SELECT queries...');
    const sampleQueries = {
      'users': { 
        display: 'Users',
        query: 'SELECT user_id, full_name, role, status FROM users LIMIT 3'
      },
      'vehicles': { 
        display: 'Vehicles',
        query: 'SELECT vehicle_id, make, model, capacity FROM vehicles LIMIT 3'
      },
      'rideoffers': { 
        display: 'RideOffers',
        query: 'SELECT offer_id, driver_id, start_zone, end_zone FROM rideoffers LIMIT 3'
      },
      'riderequests': { 
        display: 'RideRequests',
        query: 'SELECT request_id, rider_id, from_zone, to_zone FROM riderequests LIMIT 3'
      },
      'matches': { 
        display: 'Matches',
        query: 'SELECT match_id, offer_id, request_id, status FROM matches LIMIT 3'
      },
      'ratings': { 
        display: 'Ratings',
        query: 'SELECT rating_id, rater_user_id, ratee_user_id, score FROM ratings LIMIT 3'
      },
      'bankaccounts': { 
        display: 'BankAccounts',
        query: 'SELECT account_id, name, balance FROM bankaccounts'
      }
    };
    
    for (const table of requiredTables) {
      if (existingTables.includes(table) && sampleQueries[table]) {
        try {
          const result = await client.query(sampleQueries[table].query);
          console.log(`  ✓ ${sampleQueries[table].display}: Query successful, returned ${result.rows.length} row(s)`);
          if (result.rows.length > 0) {
            console.log(`    Sample row:`, JSON.stringify(result.rows[0]));
          }
        } catch (err) {
          console.log(`  ✗ ${sampleQueries[table].display}: Query failed - ${err.message}`);
        }
      }
    }
    console.log('');
    
    console.log('========================================');
    console.log('✓ Diagnostics complete');
    console.log('========================================\n');
    
    return {
      connected: true,
      tablesExist: missingTables.length === 0,
      missingTables: missingTables.map(t => requiredTableDisplay[requiredTables.indexOf(t)] || t),
      existingTables: existingTables
    };
    
  } catch (error) {
    console.error('\n========================================');
    console.error('✗ DIAGNOSTICS FAILED');
    console.error('========================================');
    console.error('Error:', error.message);
    console.error('Error code:', error.code);
    console.error('Error detail:', error.detail);
    console.error('\nConnection details:');
    console.error('  Host:', pool.options.host);
    console.error('  Port:', pool.options.port);
    console.error('  Database:', pool.options.database);
    console.error('  User:', pool.options.user);
    console.error('\nTroubleshooting steps:');
    console.error('1. Verify PostgreSQL is running');
    console.error('2. Check .env file has correct values');
    console.error('3. Test connection manually: psql -h ' + pool.options.host + ' -p ' + pool.options.port + ' -U ' + pool.options.user + ' -d ' + pool.options.database);
    console.error('4. Verify database exists: psql -U ' + pool.options.user + ' -l');
    console.error('========================================\n');
    
    return {
      connected: false,
      error: error.message,
      errorCode: error.code
    };
  } finally {
    if (client) {
      client.release();
    }
  }
}

// Simple connection test (backward compatibility)
async function testConnection() {
  let client;
  try {
    client = await pool.connect();
    const result = await client.query('SELECT NOW() as current_time, current_database() as db_name');
    console.log('✓ Database connection successful!');
    console.log('  Connected to database:', result.rows[0].db_name);
    console.log('  Server time:', result.rows[0].current_time);
    return true;
  } catch (error) {
    console.error('✗ Database connection failed!');
    console.error('Error:', error.message);
    console.error('Error code:', error.code);
    return false;
  } finally {
    if (client) {
      client.release();
    }
  }
}

// Helper function to get a client from the pool
async function getClient() {
  try {
    const client = await pool.connect();
    return client;
  } catch (error) {
    console.error('Error getting database client:', error);
    console.error('Connection error details:', {
      code: error.code,
      message: error.message,
      host: pool.options.host,
      port: pool.options.port,
      database: pool.options.database,
    });
    throw error;
  }
}

// Helper function to execute a query
async function query(text, params) {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('Executed query', { 
      duration: `${duration}ms`, 
      rows: res.rowCount,
      // Only log first 100 chars of query to avoid cluttering logs
      query: text.substring(0, 100) + (text.length > 100 ? '...' : '')
    });
    return res;
  } catch (error) {
    console.error('Error executing query:', error);
    console.error('Query that failed:', text.substring(0, 200));
    console.error('Error details:', {
      code: error.code,
      message: error.message,
      detail: error.detail,
      hint: error.hint,
    });
    throw error;
  }
}

// Export functions
module.exports = {
  pool,
  getClient,
  query,
  testConnection,
  runDiagnostics, // Comprehensive diagnostic function
};

