const { query } = require('../dbConfig');

async function handleQuery3(req, res) {
  try {
    // Query 3: Overbooked offers (where matched seats exceed seats_available)
    const sql = `
      SELECT 
        o.offer_id,
        u.full_name AS driver_name,
        o.seats_available,
        (SELECT COUNT(*)
           FROM Matches m
          WHERE m.offer_id = o.offer_id
            AND m.status IN ('pending','confirmed')) AS seats_matched
      FROM RideOffers o
      JOIN Users u ON o.driver_id = u.user_id
      WHERE o.seats_available < (
        SELECT COUNT(*) 
        FROM Matches m
        WHERE m.offer_id = o.offer_id
          AND m.status IN ('pending','confirmed')
      )
      ORDER BY o.offer_id
    `;

    const result = await query(sql);

    // Generate HTML response
    let html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Query 3 - Overbooked Offers | Husky Ride Share</title>
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
        <h1 class="mb-4">Query 3: Overbooked Offers</h1>
        
        <div class="card mb-4">
            <div class="card-body">
                <p class="card-text">
                    This query shows ride offers where the number of matched seats (pending or confirmed) 
                    exceeds the available seats.
                </p>
                <form method="GET" action="/query3">
                    <button type="submit" class="btn btn-primary">Show Overbooked Offers</button>
                    <a href="/query3.html" class="btn btn-secondary ms-2">Refresh</a>
                </form>
            </div>
        </div>

        <div class="card">
            <div class="card-body">
                <h5 class="card-title">Results</h5>
    `;

    if (result.rows.length === 0) {
      html += `
                <div class="alert alert-success">
                    <strong>Great news!</strong> There are no overbooked offers. All ride offers have sufficient capacity.
                </div>
      `;
    } else {
      html += `
                <div class="alert alert-warning">
                    Found <strong>${result.rows.length}</strong> overbooked offer(s).
                </div>
                <div class="table-responsive">
                    <table class="table table-striped table-bordered">
                        <thead class="table-dark">
                            <tr>
                                <th>Offer ID</th>
                                <th>Driver Name</th>
                                <th>Seats Available</th>
                                <th>Seats Matched</th>
                                <th>Overbooked By</th>
                            </tr>
                        </thead>
                        <tbody>
      `;

      result.rows.forEach(row => {
        const overbookedBy = row.seats_matched - row.seats_available;
        html += `
                            <tr>
                                <td>${row.offer_id}</td>
                                <td>${escapeHtml(row.driver_name)}</td>
                                <td>${row.seats_available}</td>
                                <td>${row.seats_matched}</td>
                                <td><span class="badge bg-danger">${overbookedBy}</span></td>
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
    // Log full error details for debugging
    console.error('Error in Query 3:', error);
    console.error('SQL Error Details:', {
      message: error.message,
      code: error.code,
      detail: error.detail,
      hint: error.hint,
      position: error.position
    });
    
    // Check if it's a connection error
    const isConnectionError = error.code === 'ECONNREFUSED' || 
                             error.code === 'ETIMEDOUT' || 
                             error.message.includes('timeout') ||
                             error.message.includes('Connection terminated');
    
    const errorMessage = isConnectionError 
      ? 'Database connection failed. Please check your database configuration and ensure PostgreSQL is running.'
      : error.message;
    
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
            <p>${escapeHtml(errorMessage)}</p>
            <a href="/query3.html" class="btn btn-primary">Try Again</a>
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

module.exports = { handleQuery3 };

