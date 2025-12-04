# Database Connection Fixes - Husky Ride Share

## Problem
All query pages were failing with "Connection terminated due to connection timeout" errors.

## Root Causes Identified
1. **Connection timeout too short**: `connectionTimeoutMillis: 2000` (2 seconds) was too aggressive
2. **No connection testing on startup**: Server started without verifying database connectivity
3. **Poor error handling**: Connection errors weren't clearly identified or reported
4. **Aggressive error handling**: `process.exit(-1)` on pool errors would kill the server

## Fixes Applied

### 1. `dbConfig.js` - Database Connection Configuration

**Changes:**
- ✅ Increased `connectionTimeoutMillis` from 2000ms to 10000ms (10 seconds)
- ✅ Added explicit port conversion: `Number(process.env.DB_PORT)`
- ✅ Removed `process.exit(-1)` on pool errors (now just logs errors)
- ✅ Added `testConnection()` function to verify connectivity on startup
- ✅ Enhanced error logging with connection details
- ✅ Added better error messages for connection failures

**Key improvements:**
```javascript
// Before: connectionTimeoutMillis: 2000 (too short)
// After:  connectionTimeoutMillis: 10000 (10 seconds)

// Before: process.exit(-1) on pool errors
// After:  Just log errors, don't kill the server

// New: testConnection() function
async function testConnection() {
  // Tests connection and provides helpful error messages
}
```

### 2. `server.js` - Startup Connection Testing

**Changes:**
- ✅ Added connection test on server startup
- ✅ Shows clear success/failure messages
- ✅ Provides troubleshooting steps if connection fails

**New behavior:**
- Server starts and immediately tests database connection
- Shows connection status before accepting requests
- Provides helpful error messages if connection fails

### 3. All Controllers - Connection Error Detection

**Changes applied to:**
- `controllers/query1.js`
- `controllers/query2.js`
- `controllers/query3.js`
- `controllers/query4.js`
- `controllers/query5.js`
- `controllers/query6.js`

**Improvements:**
- ✅ Detects connection errors (ECONNREFUSED, ETIMEDOUT, timeout messages)
- ✅ Shows user-friendly error messages for connection issues
- ✅ Still shows detailed SQL errors for query problems
- ✅ Better error logging for debugging

**Connection error detection:**
```javascript
const isConnectionError = error.code === 'ECONNREFUSED' || 
                         error.code === 'ETIMEDOUT' || 
                         error.message.includes('timeout') ||
                         error.message.includes('Connection terminated');

const errorMessage = isConnectionError 
  ? 'Database connection failed. Please check your database configuration and ensure PostgreSQL is running.'
  : error.message;
```

### 4. `test-connection.js` - Connection Testing Script

**New file created:**
- Standalone script to test database connection
- Can be run independently: `node test-connection.js`
- Shows configuration, tests connection, lists tables, checks data

**Usage:**
```bash
node test-connection.js
```

## How to Verify the Fix

### Step 1: Test Connection
```bash
node test-connection.js
```

This will:
- Show your database configuration
- Test the connection
- List all tables in the database
- Check if sample data exists

### Step 2: Start Server
```bash
node server.js
```

You should see:
```
========================================
Server is running on http://localhost:5000
========================================

Testing database connection...
Connection config: { host: 'localhost', port: 5432, ... }
✓ Database connection successful!
  Connected to database: huskyrideshare
  Server time: 2025-01-XX ...

✓ Server is ready to handle requests.
```

### Step 3: Test Query Pages
1. Open http://localhost:5000
2. Navigate to each query page
3. Try running queries
4. Should see data (not connection errors)

## Troubleshooting

If you still see connection errors:

### 1. Check PostgreSQL is Running
```bash
# macOS
brew services list | grep postgresql

# Linux
sudo systemctl status postgresql
```

### 2. Verify .env File
Make sure `.env` has correct values:
```bash
cat .env
```

Should show:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=huskyrideshare
DB_USER=your_username
DB_PASSWORD=your_password
```

### 3. Test Connection Manually
```bash
psql -h localhost -p 5432 -U your_username -d huskyrideshare
```

### 4. Check Database Exists
```bash
psql -U your_username -l | grep huskyrideshare
```

### 5. Verify Schema is Loaded
```bash
psql -U your_username -d huskyrideshare -c "\dt"
```

Should show tables: Users, Vehicles, RideOffers, RideRequests, Matches, Ratings, BankAccounts

## Summary of Changes

| File | Changes |
|------|---------|
| `dbConfig.js` | Increased timeout, added testConnection(), better error handling |
| `server.js` | Added connection test on startup |
| `controllers/*.js` | Added connection error detection and user-friendly messages |
| `test-connection.js` | New file for standalone connection testing |

## Next Steps

1. ✅ Update `.env` with your actual PostgreSQL credentials
2. ✅ Run `node test-connection.js` to verify connection
3. ✅ Start server with `node server.js`
4. ✅ Test all query pages
5. ✅ If issues persist, check server logs for detailed error messages

All connection issues should now be resolved with clear error messages to help diagnose any remaining problems!

