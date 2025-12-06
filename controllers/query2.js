const { query } = require('../dbConfig');

async function handleQuery2(req, res) {
  try {
    const { min_avg } = req.body;

    // Query 2: Top-rated drivers with optional minimum rating filter
    // If min_avg is provided, return all drivers with avg >= min_avg
    // Otherwise, return only drivers with the maximum average rating (>= ALL)
    const params = [];
    let paramCount = 1;

    let sql;
    
    if (min_avg && !isNaN(parseFloat(min_avg))) {
      // Filter by minimum average rating - return all drivers meeting the threshold
      sql = `
        SELECT 
          u.full_name AS driver_name, 
          ROUND(AVG(t.score)::numeric, 2) AS avg_score
        FROM Ratings t
        JOIN Users u ON t.ratee_user_id = u.user_id
        WHERE u.role IN ('driver','both')
        GROUP BY u.user_id, u.full_name
        HAVING AVG(t.score) >= $${paramCount}
      `;
      params.push(parseFloat(min_avg));
    } else {
      // No filter - return only top-rated drivers (those with max average)
      sql = `
        SELECT 
          u.full_name AS driver_name, 
          ROUND(AVG(t.score)::numeric, 2) AS avg_score
        FROM Ratings t
        JOIN Users u ON t.ratee_user_id = u.user_id
        WHERE u.role IN ('driver','both')
        GROUP BY u.user_id, u.full_name
        HAVING AVG(t.score) >= ALL (
          SELECT AVG(t2.score)
          FROM Ratings t2
          JOIN Users u2 ON t2.ratee_user_id = u2.user_id
          WHERE u2.role IN ('driver','both')
          GROUP BY u2.user_id
        )
      `;
    }

    sql += ` ORDER BY avg_score DESC, driver_name`;

    const result = await query(sql, params);

    // Return JSON response
    res.json({
      success: true,
      count: result.rows.length,
      drivers: result.rows
    });
  } catch (error) {
    // Log full error details for debugging
    console.error('Error in Query 2:', error);
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
    
    res.status(500).json({
      success: false,
      error: errorMessage
    });
  }
}

module.exports = { handleQuery2 };

