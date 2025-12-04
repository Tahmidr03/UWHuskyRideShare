const { query } = require('../dbConfig');

async function handleQuery5(req, res) {
  try {
    const { status_filter, role_filter } = req.body;

    // Query 5: Users who both offered and requested rides (INTERSECT)
    let sql = `
      SELECT 
        u.user_id, 
        u.full_name, 
        u.uw_email,
        u.role,
        u.status
      FROM Users u
      WHERE u.user_id IN (
        SELECT driver_id FROM RideOffers
        INTERSECT
        SELECT rider_id FROM RideRequests
      )
    `;

    const params = [];
    let paramCount = 1;

    // Add status filter if provided
    if (status_filter && status_filter !== 'all') {
      sql += ` AND u.status = $${paramCount}`;
      params.push(status_filter);
      paramCount++;
    }

    // Add role filter if provided
    if (role_filter && role_filter !== 'all') {
      sql += ` AND u.role = $${paramCount}`;
      params.push(role_filter);
      paramCount++;
    }

    sql += ` ORDER BY u.full_name`;

    const result = await query(sql, params);

    // Generate HTML response (Pattern 1)
    let html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Query 5 - Users Who Both Offered and Requested | Husky Ride Share</title>
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
        <h1 class="mb-4">Query 5: Users Who Both Offered and Requested Rides</h1>
        
        <div class="card mb-4">
            <div class="card-body">
                <h5 class="card-title">Filters</h5>
                <form method="POST" action="/query5">
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label for="status_filter" class="form-label">Status</label>
                            <select class="form-select" id="status_filter" name="status_filter">
                                <option value="all" ${status_filter === 'all' || !status_filter ? 'selected' : ''}>All</option>
                                <option value="ACTIVE" ${status_filter === 'ACTIVE' ? 'selected' : ''}>ACTIVE</option>
                                <option value="SUSPENDED" ${status_filter === 'SUSPENDED' ? 'selected' : ''}>SUSPENDED</option>
                            </select>
                        </div>
                        <div class="col-md-4 mb-3">
                            <label for="role_filter" class="form-label">Role</label>
                            <select class="form-select" id="role_filter" name="role_filter">
                                <option value="all" ${role_filter === 'all' || !role_filter ? 'selected' : ''}>All</option>
                                <option value="rider" ${role_filter === 'rider' ? 'selected' : ''}>Rider</option>
                                <option value="driver" ${role_filter === 'driver' ? 'selected' : ''}>Driver</option>
                                <option value="both" ${role_filter === 'both' ? 'selected' : ''}>Both</option>
                            </select>
                        </div>
                        <div class="col-md-4 mb-3 d-flex align-items-end">
                            <button type="submit" class="btn btn-primary me-2">Search</button>
                            <a href="/query5.html" class="btn btn-secondary">Reset</a>
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
                    <strong>No results found.</strong> No users match the criteria.
                </div>
      `;
    } else {
      html += `
                <div class="alert alert-success">
                    Found <strong>${result.rows.length}</strong> user(s) who both offered and requested rides.
                </div>
                <div class="table-responsive">
                    <table class="table table-striped table-bordered">
                        <thead class="table-dark">
                            <tr>
                                <th>User ID</th>
                                <th>Full Name</th>
                                <th>UW Email</th>
                                <th>Role</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
      `;

      result.rows.forEach(row => {
        const statusBadge = row.status === 'ACTIVE' ? 'bg-success' : 'bg-warning';
        html += `
                            <tr>
                                <td>${row.user_id}</td>
                                <td>${escapeHtml(row.full_name)}</td>
                                <td>${escapeHtml(row.uw_email)}</td>
                                <td><span class="badge bg-info">${escapeHtml(row.role)}</span></td>
                                <td><span class="badge ${statusBadge}">${escapeHtml(row.status)}</span></td>
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
    console.error('Error in Query 5:', error);
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
            <a href="/query5.html" class="btn btn-primary">Try Again</a>
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

module.exports = { handleQuery5 };

