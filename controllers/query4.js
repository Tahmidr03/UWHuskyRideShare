const { query } = require('../dbConfig');

async function handleQuery4(req, res) {
  try {
    const { start_date, end_date } = req.body;

    // Query 4: FULL OUTER JOIN of offers and requests by zone and date
    // Based on Oracle Query 4: Uses TRUNC for dates, converted to DATE() for PostgreSQL
    // PostgreSQL supports FULL OUTER JOIN
    const params = [];
    let paramCount = 1;

    // Build base query with FULL OUTER JOIN
    let sql = `
      SELECT 
        COALESCE(o.start_zone, q.from_zone) AS zone,
        DATE(COALESCE(o.start_time, q.desired_time)) AS ride_day,
        o.offer_id,
        q.request_id
      FROM RideOffers o
      FULL OUTER JOIN RideRequests q
        ON o.start_zone  = q.from_zone
       AND o.end_zone    = q.to_zone
       AND DATE(o.start_time) = DATE(q.desired_time)
    `;

    // Add date range filter if provided - WHERE clause must come after JOIN
    if (start_date && start_date.trim() !== '') {
      sql += ` WHERE DATE(COALESCE(o.start_time, q.desired_time)) >= $${paramCount}`;
      params.push(start_date);
      paramCount++;
      
      if (end_date && end_date.trim() !== '') {
        sql += ` AND DATE(COALESCE(o.start_time, q.desired_time)) <= $${paramCount}`;
        params.push(end_date);
        paramCount++;
      }
    } else if (end_date && end_date.trim() !== '') {
      sql += ` WHERE DATE(COALESCE(o.start_time, q.desired_time)) <= $${paramCount}`;
      params.push(end_date);
      paramCount++;
    }

    sql += ` ORDER BY ride_day, zone`;

    const result = await query(sql, params);

    // Return JSON response
    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows
    });
  } catch (error) {
    // Log full error details for debugging
    console.error('Error in Query 4:', error);
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

module.exports = { handleQuery4 };

