const { query } = require('../dbConfig');

async function handleQuery1(req, res) {
  try {
    const { ride_date, zone_filter } = req.body;

    // Base query: confirmed rides with driver & rider names
    let sql = `
      SELECT 
        d.full_name AS driver_name,
        r.full_name AS rider_name,
        o.start_zone,
        o.end_zone,
        o.start_time,
        m.status
      FROM Matches m
      JOIN RideOffers   o ON m.offer_id   = o.offer_id
      JOIN RideRequests q ON m.request_id = q.request_id
      JOIN Users d ON o.driver_id = d.user_id
      JOIN Users r ON q.rider_id  = r.user_id
      WHERE m.status = 'confirmed'
    `;

    const params = [];
    let paramCount = 1;

    // Add date filter if provided
    if (ride_date && ride_date.trim() !== '') {
      sql += ` AND DATE(o.start_time) = $${paramCount}`;
      params.push(ride_date);
      paramCount++;
    }

    // Add zone filter if provided
    if (zone_filter && zone_filter.trim() !== '') {
      sql += ` AND (o.start_zone ILIKE $${paramCount} OR o.end_zone ILIKE $${paramCount})`;
      params.push(`%${zone_filter}%`);
      paramCount++;
    }

    sql += ` ORDER BY o.start_time`;

    const result = await query(sql, params);

    // Generate HTML response
    let html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Query 1 - Confirmed Rides | Husky Ride Share</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="/css/styles.css">
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand" href="/">Husky Ride Share</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item"><a class="nav-link" href="/">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query1.html">Query 1</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query2.html">Query 2</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query3.html">Query 3</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query4.html">Query 4</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query5.html">Query 5</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query6.html">Query 6</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <h1 class="mb-4">Query 1: Confirmed Rides</h1>
        
        <div class="card mb-4">
            <div class="card-body">
                <h5 class="card-title">Search Filters</h5>
                <form method="POST" action="/query1">
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label for="ride_date" class="form-label">Ride Date (YYYY-MM-DD)</label>
                            <input type="date" class="form-control" id="ride_date" name="ride_date" value="${ride_date || ''}">
                        </div>
                        <div class="col-md-4 mb-3">
                            <label for="zone_filter" class="form-label">Zone Filter</label>
                            <input type="text" class="form-control" id="zone_filter" name="zone_filter" placeholder="Enter zone name" value="${zone_filter || ''}">
                        </div>
                        <div class="col-md-4 mb-3 d-flex align-items-end">
                            <button type="submit" class="btn btn-primary me-2">Search</button>
                            <a href="/query1.html" class="btn btn-secondary">New Search</a>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <div class="card">
            <div class="card-body">
                <h5 class="card-title">Results</h5>
    `;

    if (result.rows.length === 0) {
      html += `
                <div class="alert alert-info">
                    <strong>No results found.</strong> Try adjusting your filters.
                </div>
      `;
    } else {
      html += `
                <div class="alert alert-success">
                    Found <strong>${result.rows.length}</strong> confirmed ride(s).
                </div>
                <div class="table-responsive">
                    <table class="table table-striped table-bordered">
                        <thead class="table-dark">
                            <tr>
                                <th>Driver Name</th>
                                <th>Rider Name</th>
                                <th>Start Zone</th>
                                <th>End Zone</th>
                                <th>Start Time</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
      `;

      result.rows.forEach(row => {
        const startTime = new Date(row.start_time).toLocaleString();
        html += `
                            <tr>
                                <td>${escapeHtml(row.driver_name)}</td>
                                <td>${escapeHtml(row.rider_name)}</td>
                                <td>${escapeHtml(row.start_zone)}</td>
                                <td>${escapeHtml(row.end_zone)}</td>
                                <td>${startTime}</td>
                                <td><span class="badge bg-success">${escapeHtml(row.status)}</span></td>
                            </tr>
        `;
      });

      html += `
                        </tbody>
                    </table>
                </div>
      `;
    }

    html += `
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
    `;

    res.send(html);
  } catch (error) {
    console.error('Error in Query 1:', error);
    res.status(500).send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Error | Husky Ride Share</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-4">
        <div class="alert alert-danger">
            <h4>Error</h4>
            <p>${escapeHtml(error.message)}</p>
            <a href="/query1.html" class="btn btn-primary">Try Again</a>
        </div>
    </div>
</body>
</html>
    `);
  }
}

function escapeHtml(text) {
  if (text == null) return '';
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return String(text).replace(/[&<>"']/g, m => map[m]);
}

module.exports = { handleQuery1 };

