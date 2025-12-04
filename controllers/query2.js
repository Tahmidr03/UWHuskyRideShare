const { query } = require('../dbConfig');

async function handleQuery2(req, res) {
  try {
    const { min_avg } = req.body;

    // Query 2: Top-rated drivers (those whose avg rating is >= every other driver's avg)
    // If min_avg is provided, show top-rated drivers who also meet the minimum threshold
    const params = [];
    let paramCount = 1;

    const sql = `
      WITH driver_ratings AS (
        SELECT 
          u.user_id,
          u.full_name AS driver_name,
          AVG(t.score) AS avg_score
        FROM Ratings t
        JOIN Users u ON t.ratee_user_id = u.user_id
        WHERE u.role IN ('driver','both')
        GROUP BY u.user_id, u.full_name
      ),
      max_avg AS (
        SELECT MAX(avg_score) AS max_avg_score
        FROM driver_ratings
      )
      SELECT 
        dr.driver_name,
        ROUND(dr.avg_score::numeric, 2) AS avg_score
      FROM driver_ratings dr
      CROSS JOIN max_avg ma
      WHERE dr.avg_score >= ma.max_avg_score
    ` + (min_avg && !isNaN(parseFloat(min_avg)) 
      ? ` AND dr.avg_score >= $1`
      : '') + `
      ORDER BY dr.avg_score DESC, dr.driver_name
    `;

    if (min_avg && !isNaN(parseFloat(min_avg))) {
      params.push(parseFloat(min_avg));
    }

    const result = await query(sql, params);

    // Return JSON response
    res.json({
      success: true,
      count: result.rows.length,
      drivers: result.rows
    });
  } catch (error) {
    console.error('Error in Query 2:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
}

module.exports = { handleQuery2 };

