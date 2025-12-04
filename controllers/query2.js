const { query } = require('../dbConfig');

async function handleQuery2(req, res) {
  try {
    const { min_avg } = req.body;

    // Query 2: Top-rated drivers (those whose avg rating is >= every other driver's avg)
    // Based on Oracle Query 2: Uses >= ALL to find drivers with max average rating
    // PostgreSQL supports >= ALL, so we use the same logic
    const params = [];
    let paramCount = 1;

    // Build the base query - using >= ALL like the Oracle version
    let sql = `
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

    // If min_avg is provided, add additional filter
    if (min_avg && !isNaN(parseFloat(min_avg))) {
      sql += ` AND AVG(t.score) >= $${paramCount}`;
      params.push(parseFloat(min_avg));
      paramCount++;
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

