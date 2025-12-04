const { getClient } = require('../dbConfig');

async function handleQuery6(req, res) {
  let client;
  
  try {
    client = await getClient();
    const { from_account, to_account, amount } = req.body;

    // Validation
    if (!from_account || !to_account || !amount) {
      throw new Error('All fields are required');
    }

    const fromAccountId = parseInt(from_account);
    const toAccountId = parseInt(to_account);
    const transferAmount = parseFloat(amount);

    if (isNaN(fromAccountId) || isNaN(toAccountId) || isNaN(transferAmount)) {
      throw new Error('Invalid input values');
    }

    if (transferAmount <= 0) {
      throw new Error('Transfer amount must be greater than 0');
    }

    if (fromAccountId === toAccountId) {
      throw new Error('Cannot transfer to the same account');
    }

    // Begin transaction
    await client.query('BEGIN');

    try {
      // Check source account exists and get balance
      const fromResult = await client.query(
        'SELECT account_id, name, balance FROM BankAccounts WHERE account_id = $1 FOR UPDATE',
        [fromAccountId]
      );

      if (fromResult.rows.length === 0) {
        await client.query('ROLLBACK');
        throw new Error(`Source account ${fromAccountId} not found`);
      }

      const fromAccount = fromResult.rows[0];

      // Check destination account exists
      const toResult = await client.query(
        'SELECT account_id, name, balance FROM BankAccounts WHERE account_id = $1 FOR UPDATE',
        [toAccountId]
      );

      if (toResult.rows.length === 0) {
        await client.query('ROLLBACK');
        throw new Error(`Destination account ${toAccountId} not found`);
      }

      const toAccount = toResult.rows[0];

      // Check sufficient balance
      if (parseFloat(fromAccount.balance) < transferAmount) {
        await client.query('ROLLBACK');
        throw new Error(`Insufficient balance. Available: $${fromAccount.balance}, Requested: $${transferAmount}`);
      }

      // Perform transfer
      await client.query(
        'UPDATE BankAccounts SET balance = balance - $1 WHERE account_id = $2',
        [transferAmount, fromAccountId]
      );

      await client.query(
        'UPDATE BankAccounts SET balance = balance + $1 WHERE account_id = $2',
        [transferAmount, toAccountId]
      );

      // Get updated balances
      const updatedFrom = await client.query(
        'SELECT account_id, name, balance FROM BankAccounts WHERE account_id = $1',
        [fromAccountId]
      );
      const updatedTo = await client.query(
        'SELECT account_id, name, balance FROM BankAccounts WHERE account_id = $1',
        [toAccountId]
      );

      // Commit transaction
      await client.query('COMMIT');

      // Generate HTML response
      const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Query 6 - Transaction Result | Husky Ride Share</title>
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
        <h1 class="mb-4">Query 6: Transaction Result</h1>
        
        <div class="alert alert-success">
            <h4>Transaction Successful!</h4>
            <p>Transferred <strong>$${transferAmount.toFixed(2)}</strong> from ${escapeHtml(updatedFrom.rows[0].name)} to ${escapeHtml(updatedTo.rows[0].name)}.</p>
        </div>

        <div class="row">
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header bg-primary text-white">
                        <h5>From Account</h5>
                    </div>
                    <div class="card-body">
                        <p><strong>Account ID:</strong> ${updatedFrom.rows[0].account_id}</p>
                        <p><strong>Name:</strong> ${escapeHtml(updatedFrom.rows[0].name)}</p>
                        <p><strong>New Balance:</strong> $${parseFloat(updatedFrom.rows[0].balance).toFixed(2)}</p>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header bg-success text-white">
                        <h5>To Account</h5>
                    </div>
                    <div class="card-body">
                        <p><strong>Account ID:</strong> ${updatedTo.rows[0].account_id}</p>
                        <p><strong>Name:</strong> ${escapeHtml(updatedTo.rows[0].name)}</p>
                        <p><strong>New Balance:</strong> $${parseFloat(updatedTo.rows[0].balance).toFixed(2)}</p>
                    </div>
                </div>
            </div>
        </div>

        <div class="mt-4">
            <a href="/query6.html" class="btn btn-primary">New Transaction</a>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
      `;

      res.send(html);
    } catch (error) {
      // Rollback on any error
      await client.query('ROLLBACK');
      throw error;
    }
  } catch (error) {
    // Log full error details for debugging
    console.error('Error in Query 6:', error);
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
    
    // Generate error HTML
    const errorHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Transaction Error | Husky Ride Share</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-4">
        <div class="alert alert-danger">
            <h4>Transaction Failed</h4>
            <p><strong>Error:</strong> ${escapeHtml(errorMessage)}</p>
            <p class="mb-0">The transaction was rolled back. No changes were made to the database.</p>
        </div>
        <a href="/query6.html" class="btn btn-primary">Try Again</a>
    </div>
</body>
</html>
    `;

    res.status(400).send(errorHtml);
  } finally {
    // Only release client if it was successfully acquired
    if (client) {
      client.release();
    }
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

module.exports = { handleQuery6 };

