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
    <!-- Navigation Bar -->
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="/">🐾 Husky Ride Share</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item"><a class="nav-link" href="/">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query1.html">Query 1</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query2.html">Query 2</a></li>
                    <li class="nav-item"><a class="nav-link active" href="/query3.html">Query 3</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query4.html">Query 4</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query5.html">Query 5</a></li>
                    <li class="nav-item"><a class="nav-link" href="/query6.html">Query 6</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <!-- Page Header -->
    <div class="page-header">
        <div class="container">
            <h1>Query 3: Overbooked Offers</h1>
            <p class="lead">Identify ride offers where matched seats exceed available capacity</p>
        </div>
    </div>

    <!-- Main Content -->
    <div class="container mb-5">
        <!-- Query Card -->
        <div class="card query-section">
            <div class="card-header">
                <h5 class="mb-0">Query Description</h5>
            </div>
            <div class="card-body">
                <p class="query-description">
                    This query shows ride offers where the number of matched seats (pending or confirmed) 
                    exceeds the available seats.
                </p>
                <form method="GET" action="/query3">
                    <button type="submit" class="btn btn-primary">🔍 Show Overbooked Offers</button>
                    <a href="/query3.html" class="btn btn-secondary ms-2">Refresh</a>
                </form>
            </div>
        </div>

        <!-- Results Card -->
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Results</h5>
            </div>
            <div class="card-body">
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
                        <thead>
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

    <!-- Footer -->
    <footer>
        <div class="container text-center">
            <p class="mb-0">TCSS 445 - Phase III | Husky Ride Share Web Application</p>
        </div>
    </footer>

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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error | Husky Ride Share</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="/css/styles.css">
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="/">🐾 Husky Ride Share</a>
        </div>
    </nav>
    <div class="container mt-5 mb-5">
        <div class="alert alert-danger">
            <h4>Error</h4>
            <p>${escapeHtml(errorMessage)}</p>
            <a href="/query3.html" class="btn btn-primary">Try Again</a>
        </div>
    </div>
    <footer>
        <div class="container text-center">
            <p class="mb-0">TCSS 445 - Phase III | Husky Ride Share Web Application</p>
        </div>
    </footer>
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

