const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');

// Import controllers
const query1Controller = require('./controllers/query1');
const query2Controller = require('./controllers/query2');
const query3Controller = require('./controllers/query3');
const query4Controller = require('./controllers/query4');
const query5Controller = require('./controllers/query5');
const query6Controller = require('./controllers/query6');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

// Routes for query pages (HTML)
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.post('/query1', query1Controller.handleQuery1);
app.get('/query3', query3Controller.handleQuery3);
app.post('/query5', query5Controller.handleQuery5);
app.post('/query6', query6Controller.handleQuery6);

// API routes (JSON)
app.post('/api/query2', query2Controller.handleQuery2);
app.post('/api/query4', query4Controller.handleQuery4);

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
  console.log(`Make sure PostgreSQL is running and the database is set up.`);
});

