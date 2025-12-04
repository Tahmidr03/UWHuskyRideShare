const { query } = require('../dbConfig');

async function handleQuery4(req, res) {
  try {
    const { start_date, end_date } = req.body;

    // Query 4: FULL OUTER JOIN of offers and requests by zone and date
    // PostgreSQL supports FULL OUTER JOIN
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

    const params = [];
    let paramCount = 1;

    // Add date range filter if provided
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
    console.error('Error in Query 4:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
}

module.exports = { handleQuery4 };

