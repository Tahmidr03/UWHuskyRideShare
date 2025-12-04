# Husky Ride Share - Phase III Web Application

A full-stack web application demonstrating database-driven features for the Husky Ride Share system, built for TCSS 445 Phase III.

## Overview

Husky Ride Share is a platform that connects UW Tacoma students for carpooling, addressing challenges like parking costs, limited availability, and environmental concerns. This web application provides six query interfaces to explore and interact with the ride-sharing database.

## Tech Stack

- **Backend**: Node.js + Express
- **Database**: PostgreSQL
- **Frontend**: HTML, Bootstrap 5, JavaScript
- **Database Driver**: `pg` (node-postgres)

## Project Structure

```
UWHuskyRideShare/
├── server.js              # Express server setup
├── dbConfig.js            # Database connection configuration
├── schema.sql             # PostgreSQL schema and sample data
├── package.json           # Node.js dependencies
├── controllers/           # Route handlers
│   ├── query1.js         # Confirmed rides (Pattern 1: Direct HTML)
│   ├── query2.js         # Top-rated drivers (Pattern 2: JSON API)
│   ├── query3.js         # Overbooked offers (Pattern 1: Direct HTML)
│   ├── query4.js         # Supply vs demand (Pattern 2: JSON API)
│   ├── query5.js         # Dual role users (Pattern 1: Direct HTML)
│   └── query6.js         # Transaction demo (Pattern 1: Direct HTML)
└── public/                # Static files
    ├── index.html         # Main entry page
    ├── query1.html        # Query 1 page
    ├── query2.html        # Query 2 page
    ├── query3.html        # Query 3 page
    ├── query4.html        # Query 4 page
    ├── query5.html        # Query 5 page
    ├── query6.html        # Query 6 page
    ├── css/
    │   └── styles.css     # Custom styles
    └── js/
        ├── query2.js      # Client-side JS for Query 2
        └── query4.js      # Client-side JS for Query 4
```

## Prerequisites

- Node.js (v14 or higher)
- PostgreSQL (v12 or higher)
- npm (comes with Node.js)

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

This will install:
- `express` - Web framework
- `pg` - PostgreSQL client
- `body-parser` - Request body parsing

### 2. Database Setup

#### Option A: Using psql command line

```bash
# Create database
createdb huskyrideshare

# Run schema file
psql -d huskyrideshare -f schema.sql
```

#### Option B: Using PostgreSQL GUI (pgAdmin, DBeaver, etc.)

1. Create a new database named `huskyrideshare`
2. Open and execute the `schema.sql` file

### 3. Configure Database Connection

Set environment variables or modify `dbConfig.js` with your PostgreSQL credentials:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=huskyrideshare
export DB_USER=postgres
export DB_PASSWORD=your_password
```

Or edit `dbConfig.js` directly:

```javascript
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'huskyrideshare',
  user: 'postgres',
  password: 'your_password',
  // ...
});
```

### 4. Start the Server

```bash
npm start
```

Or for development with auto-reload:

```bash
npm run dev
```

The server will start on `http://localhost:5000` (or the port specified in `PORT` environment variable).

### 5. Access the Application

Open your browser and navigate to:
- Main page: `http://localhost:5000`
- Query pages: `http://localhost:5000/query1.html` through `query6.html`

## Features

### Query 1: Confirmed Rides (Pattern 1: Direct HTML)
- View all confirmed rides with driver and rider information
- Filter by date and/or zone
- Server-rendered HTML table

### Query 2: Top-Rated Drivers (Pattern 2: JSON API)
- Find drivers with the highest average ratings
- Optional minimum rating filter
- Client-side JavaScript renders results from JSON API

### Query 3: Overbooked Offers (Pattern 1: Direct HTML)
- Identify ride offers where matched seats exceed available capacity
- Server-rendered HTML table

### Query 4: Supply vs Demand (Pattern 2: JSON API)
- Compare ride offers and requests by zone and date
- Color-coded results showing excess supply or unmet demand
- Client-side JavaScript renders results from JSON API

### Query 5: Dual Role Users (Pattern 1: Direct HTML)
- Find users who have both offered and requested rides
- Filter by status and role
- Server-rendered HTML table

### Query 6: Transaction Demo (Pattern 1: Direct HTML)
- Demonstrates database transactions (BEGIN, COMMIT, ROLLBACK)
- Fund transfer between bank accounts
- Shows transaction rollback on errors or insufficient balance

## Database Schema

The application uses the following main tables:
- `Users` - User accounts (drivers, riders, or both)
- `Vehicles` - Vehicle information
- `RideOffers` - Ride offers from drivers
- `RideRequests` - Ride requests from riders
- `Matches` - Matches between offers and requests
- `Ratings` - User ratings
- `BankAccounts` - For transaction demo (Query 6)

See `schema.sql` for complete schema definition.

## Environment Variables

- `PORT` - Server port (default: 5000)
- `DB_HOST` - Database host (default: localhost)
- `DB_PORT` - Database port (default: 5432)
- `DB_NAME` - Database name (default: huskyrideshare)
- `DB_USER` - Database user (default: postgres)
- `DB_PASSWORD` - Database password (default: postgres)

## Troubleshooting

### Database Connection Errors

1. Ensure PostgreSQL is running:
   ```bash
   # macOS
   brew services start postgresql
   
   # Linux
   sudo systemctl start postgresql
   ```

2. Verify database exists:
   ```bash
   psql -l | grep huskyrideshare
   ```

3. Check credentials in `dbConfig.js` or environment variables

### Port Already in Use

Change the port:
```bash
PORT=3000 npm start
```

### Module Not Found Errors

Reinstall dependencies:
```bash
rm -rf node_modules package-lock.json
npm install
```

## Development Notes

- **Pattern 1 (Direct HTML)**: Queries 1, 3, 5, 6 - Server renders complete HTML pages
- **Pattern 2 (JSON API)**: Queries 2, 4 - Server returns JSON, client-side JS renders results

All pages include:
- Bootstrap 5 for styling
- Responsive navigation bar
- Form validation (client and server-side)
- Error handling and user feedback

## Team Members

Please update the team member names and emails in `public/index.html`.

## License

This project is for educational purposes (TCSS 445).
