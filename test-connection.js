#!/usr/bin/env node
/**
 * Test script to verify PostgreSQL database connection
 * Run with: node test-connection.js
 */

require('dotenv').config();
const { testConnection, pool } = require('./dbConfig');

async function main() {
  console.log('========================================');
  console.log('PostgreSQL Connection Test');
  console.log('========================================\n');
  
  // Show configuration (without password)
  console.log('Configuration:');
  console.log('  Host:', process.env.DB_HOST || 'localhost');
  console.log('  Port:', process.env.DB_PORT || 5432);
  console.log('  Database:', process.env.DB_NAME || 'huskyrideshare');
  console.log('  User:', process.env.DB_USER || 'postgres');
  console.log('  Password:', process.env.DB_PASSWORD ? '***' : 'NOT SET');
  console.log('');
  
  // Test connection
  const connected = await testConnection();
  
  if (connected) {
    // Try a simple query to verify tables exist
    try {
      const { query } = require('./dbConfig');
      const result = await query(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        ORDER BY table_name
      `);
      
      console.log('\n✓ Found tables in database:');
      if (result.rows.length === 0) {
        console.log('  ⚠️  No tables found. You may need to run schema.sql');
      } else {
        result.rows.forEach(row => {
          console.log('  -', row.table_name);
        });
      }
      
      // Check if we have data
      const userCount = await query('SELECT COUNT(*) as count FROM Users');
      console.log('\n✓ Sample data check:');
      console.log('  Users:', userCount.rows[0].count);
      
    } catch (err) {
      console.error('\n✗ Error querying database:', err.message);
    }
  }
  
  // Close pool
  await pool.end();
  console.log('\n========================================');
  process.exit(connected ? 0 : 1);
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});

