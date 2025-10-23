const express = require('express');
const router = express.Router();
const db = require('../../db');
const { getTablesForSite } = require('../../lib/table-mapper');

/* =========================================================
   OPERATOR
========================================================= */
router.post('/car-in', async (req, res) => {
  const { car_no, valet_id, site_no, phone_number } = req.body;
  try {
    const { car_table } = await getTablesForSite(site_no);

    await db.query(
      `INSERT INTO \`${car_table}\`
       (car_no, valet_id, site_no, phone_number, status, timestamp_car_in_request,
        seen_parking, seen_bringing)
       VALUES (?, ?, ?, ?, "in_request", NOW(), 0, 0)`,
      [car_no, valet_id, site_no, phone_number || null]
    );

    res.json({ message: 'Car In Request with phone submitted successfully.' });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      if (err.sqlMessage.includes('car_no')) {
        return res.status(400).json({ message: `Car No ${car_no} already exists.` });
      }
      if (err.sqlMessage.includes('valet_id')) {
        return res.status(400).json({ message: `Valet ID ${valet_id} already exists.` });
      }
      return res.status(400).json({ message: 'Duplicate entry found.' });
    }
    console.error("Car In error (site2):", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

/* =========================================================
   MANAGER
========================================================= */
router.get('/car-requests/:site_no', async (req, res) => {
  const { site_no } = req.params;
  try {
    const { car_table } = await getTablesForSite(site_no);

    const [rows] = await db.query(
      `SELECT car_no, valet_id, status, driver_assigned_for_parking,
              driver_assigned_for_bringing, parking_spot,
              COALESCE(seen_parking,0) AS seen_parking, timestamp_seen_parking,
              COALESCE(seen_bringing,0) AS seen_bringing, timestamp_seen_bringing
       FROM \`${car_table}\`
       WHERE site_no=? 
         AND status IN ("in_request", "assigned_parking", "parked",
                        "out_request", "assigned_bringing", 
                        "brought_to_client", "handed_over")
       ORDER BY timestamp_car_in_request DESC`,
      [site_no]
    );

    res.json(rows);
  } catch (err) {
    console.error("Car requests error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/assign-driver', async (req, res) => {
  const { car_no, driver_id, site_no } = req.body;
  if (!car_no || !driver_id) {
    return res.status(400).json({ message: 'Both car_no and driver_id are required.' });
  }
  try {
    const { login_table, car_table } = await getTablesForSite(site_no);

    // Validate driver exists in site login table and is a driver
    const [driverRows] = await db.query(
      `SELECT * FROM \`${login_table}\` WHERE id=? AND role="driver" AND site_no=?`,
      [driver_id, site_no]
    );
    if (!driverRows.length) {
      return res.status(400).json({ message: `Driver ${driver_id} not found or not a driver.` });
    }

    // Check car status from site car table
    const [carRows] = await db.query(
      `SELECT status FROM \`${car_table}\` WHERE car_no=? AND site_no=?`,
      [car_no, site_no]
    );
    if (!carRows.length) {
      return res.status(400).json({ message: `Car ${car_no} not found.` });
    }

    const st = carRows[0].status;
    let updateQuery, params;

    if (['in_request', 'assigned_parking'].includes(st)) {
      // assign/reassign for parking
      updateQuery = `
        UPDATE \`${car_table}\`
        SET driver_assigned_for_parking=?, timestamp_driver_assigned=NOW(), status="assigned_parking", seen_parking=0
        WHERE car_no=? AND site_no=?`;
      params = [driver_id, car_no, site_no];
    } else if (['out_request', 'assigned_bringing'].includes(st)) {
      // assign/reassign for bringing
      updateQuery = `
        UPDATE \`${car_table}\`
        SET driver_assigned_for_bringing=?, timestamp_driver_assigned=NOW(), status="assigned_bringing", seen_bringing=0
        WHERE car_no=? AND site_no=?`;
      params = [driver_id, car_no, site_no];
    } else {
      return res.status(400).json({ message: "Car not in a state requiring driver assignment." });
    }

    await db.query(updateQuery, params);
    res.json({ message: `Driver ${driver_id} assigned/reassigned to car ${car_no}.` });
  } catch (err) {
    console.error("Assign Driver error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});/* =========================================================
    MANAGER: DRIVER STATS - CORRECTED LOGIC
========================================================= */
router.get('/driver-stats', async (req, res) => {
  const { site_no } = req.query;
  if (!site_no) {
    return res.status(400).json({ message: 'Site number is required.' });
  }

  try {
    const { login_table, car_table, dump_table } = await getTablesForSite(site_no);

    const [drivers] = await db.query(
      `SELECT id FROM \`${login_table}\` WHERE role="driver" AND site_no=?`,
      [site_no]
    );

    const driverStats = await Promise.all(
      drivers.map(async (driver) => {
        const driverId = driver.id;

        // Query for CURRENTLY ASSIGNED Parking Jobs
        const [currentParkingJobs] = await db.query(
          `SELECT COUNT(*) AS count
           FROM \`${car_table}\`
           WHERE driver_assigned_for_parking = ? AND status = "assigned_parking"`,
          [driverId]
        );
        
        // Query for CURRENTLY ASSIGNED Retrieval Jobs
        const [currentRetrievalJobs] = await db.query(
          `SELECT COUNT(*) AS count
           FROM \`${car_table}\`
           WHERE driver_assigned_for_bringing = ? AND status = "assigned_bringing"`,
          [driverId]
        );

        // Query for Total Completed Jobs Today
        const [completedJobsToday] = await db.query(
          `SELECT COUNT(*) AS count FROM (
            SELECT 1 FROM \`${car_table}\`
            WHERE (driver_assigned_for_parking = ? AND DATE(timestamp_parked) = CURDATE())
               OR (driver_assigned_for_bringing = ? AND DATE(timestamp_car_brought) = CURDATE())
            UNION ALL
            SELECT 1 FROM \`${dump_table}\`
            WHERE (driver_assigned_for_parking = ? AND DATE(timestamp_parked) = CURDATE())
               OR (driver_assigned_for_bringing = ? AND DATE(timestamp_car_brought) = CURDATE())
          ) AS subquery`,
          [driverId, driverId, driverId, driverId]
        );

        const parkingCount = currentParkingJobs[0]?.count || 0;
        const retrievalCount = currentRetrievalJobs[0]?.count || 0;
        const totalCompletedJobs = completedJobsToday[0]?.count || 0;
        const totalAssignedJobs = parkingCount + retrievalCount;

        return {
          driver_id: driverId,
          total_jobs_today: totalCompletedJobs, // Renamed to be more accurate
          parking_jobs_today: parkingCount,
          retrieval_jobs_today: retrievalCount,
          current_assigned_jobs: totalAssignedJobs,
        };
      })
    );

    res.json(driverStats);
  } catch (err) {
    console.error("Driver stats error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});
/* =========================================================
   MANAGER: MARK HANDED OVER (MOVE -> DUMP -> DELETE)
========================================================= */
router.post('/mark-handed-over', async (req, res) => {
  const { car_no, site_no } = req.body;
  try {
    const { car_table, dump_table } = await getTablesForSite(site_no);

    // fetch the row first
    const [rows] = await db.query(
      `SELECT * FROM \`${car_table}\` WHERE car_no=? AND site_no=? AND status="brought_to_client"`,
      [car_no, site_no]
    );
    if (!rows.length) {
      return res.status(400).json({ message: `Car ${car_no} not in 'brought_to_client' state.` });
    }

    const carRow = rows[0];

    // insert into dump table
    await db.query(
  `INSERT INTO \`${dump_table}\` 
  (car_no, valet_id, site_no, phone_number, parking_spot,
   driver_assigned_for_parking, driver_assigned_for_bringing, status,
   timestamp_car_in_request, timestamp_car_out_request, timestamp_parked, timestamp_driver_assigned,
   timestamp_car_brought, timestamp_car_handed_over,
   seen_parking, timestamp_seen_parking, seen_bringing, timestamp_seen_bringing)
   VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
  [
    carRow.car_no,
    carRow.valet_id,
    carRow.site_no,
    carRow.phone_number || null,
    carRow.parking_spot,
    carRow.driver_assigned_for_parking,
    carRow.driver_assigned_for_bringing,
    'handed_over',
    carRow.timestamp_car_in_request,
    carRow.timestamp_car_out_request,
    carRow.timestamp_parked,
    carRow.timestamp_driver_assigned,
    carRow.timestamp_car_brought,
    new Date(),
    carRow.seen_parking,
    carRow.timestamp_seen_parking,
    carRow.seen_bringing,
    carRow.timestamp_seen_bringing
  ]
);


    // delete from main table
    await db.query(
      `DELETE FROM \`${car_table}\` WHERE car_no=? AND site_no=?`,
      [car_no, site_no]
    );

    res.json({ message: `Car ${car_no} handed over and moved to dump table.` });
  } catch (err) {
    console.error("Mark Handed Over error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

/* =========================================================
   DRIVER
========================================================= */
router.get('/driver-tasks/:site_no/:driver_id', async (req, res) => {
  const { site_no, driver_id } = req.params;
  try {
    const { login_table, car_table } = await getTablesForSite(site_no);

    const [driverRows] = await db.query(
      `SELECT * FROM \`${login_table}\` WHERE id=? AND role="driver" AND site_no=?`,
      [driver_id, site_no]
    );
    if (!driverRows.length) {
      return res.status(400).json({ message: `Invalid driver ID: ${driver_id}` });
    }

    const [rows] = await db.query(
      `SELECT car_no, valet_id, status, parking_spot, driver_assigned_for_parking, driver_assigned_for_bringing
       FROM \`${car_table}\`
       WHERE site_no=?
         AND ((driver_assigned_for_parking=? AND status="assigned_parking")
          OR (driver_assigned_for_bringing=? AND status="assigned_bringing"))
       ORDER BY timestamp_driver_assigned DESC`,
      [site_no, driver_id, driver_id]
    );
    res.json(rows);
  } catch (err) {
    console.error("Driver tasks error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/driver-seen', async (req, res) => {
  const { car_no, site_no, driver_id, type } = req.body; // type: 'parking'|'bringing'
  try {
    const { car_table } = await getTablesForSite(site_no);

    if (type === 'parking') {
      await db.query(
        `UPDATE \`${car_table}\`
         SET seen_parking=1, timestamp_seen_parking=NOW()
         WHERE car_no=? AND site_no=?`,
        [car_no, site_no]
      );
      return res.json({ message: `Driver ${driver_id} has seen parking request for ${car_no}` });
    } else if (type === 'bringing') {
      await db.query(
        `UPDATE \`${car_table}\`
         SET seen_bringing=1, timestamp_seen_bringing=NOW()
         WHERE car_no=? AND site_no=?`,
        [car_no, site_no]
      );
      return res.json({ message: `Driver ${driver_id} has seen bringing request for ${car_no}` });
    } else {
      return res.status(400).json({ message: "Invalid type, must be 'parking' or 'bringing'." });
    }
  } catch (err) {
    console.error("Driver Seen error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/mark-parked', async (req, res) => {
  const { car_no, parking_spot, site_no } = req.body;
  try {
    const { car_table } = await getTablesForSite(site_no);

    await db.query(
      `UPDATE \`${car_table}\`
       SET status="parked", parking_spot=?, timestamp_parked=NOW()
       WHERE car_no=? AND site_no=? AND status="assigned_parking"`,
      [parking_spot, car_no, site_no]
    );

    res.json({ message: `Car ${car_no} marked as Parked.` });
  } catch (err) {
    console.error("Mark Parked error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/mark-brought', async (req, res) => {
  const { car_no, site_no } = req.body;
  try {
    const { car_table } = await getTablesForSite(site_no);

    const [result] = await db.query(
      `UPDATE \`${car_table}\`
       SET status="brought_to_client", timestamp_car_brought=NOW()
       WHERE car_no=? AND site_no=? AND status="assigned_bringing"`,
      [car_no, site_no]
    );

    if (result.affectedRows === 0) {
      return res.status(400).json({ message: `Car ${car_no} is not in 'assigned_bringing' state.` });
    }

    res.json({ message: `Car ${car_no} marked as Brought to Client.` });
  } catch (err) {
    console.error("Mark Brought error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});
/* =========================================================
   CLIENT
========================================================= */
router.post('/car-out-request', async (req, res) => {
  const { car_no, site_no } = req.body;
  try {
    const { car_table } = await getTablesForSite(site_no);

    await db.query(
      `UPDATE \`${car_table}\`
       SET status="out_request", timestamp_car_out_request=NOW()
       WHERE car_no=? AND site_no=? AND status="parked"`,
      [car_no, site_no]
    );

    res.json({ message: `Car Out Request for ${car_no} submitted.` });
  } catch (err) {
    console.error("Car Out Request error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.get('/client-car/:site_no/:valet_id', async (req, res) => {
  const { site_no, valet_id } = req.params;
  try {
    const { car_table } = await getTablesForSite(site_no);

    const [rows] = await db.query(
      `SELECT car_no, valet_id, status, phone_number ,parking_spot
       FROM \`${car_table}\`
       WHERE valet_id=? AND site_no=?`,
      [valet_id, site_no]
    );

    if (!rows.length) {
      return res.status(404).json({ message: `No car found for Valet ID ${valet_id}` });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error("Client fetch car error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

/* =========================================================
   ADMIN
========================================================= */
router.post('/admin-add-user', async (req, res) => {
  const { admin_id, site_no, new_id, password, role } = req.body;
  try {
    const { login_table } = await getTablesForSite(site_no);
    const [adminRows] = await db.query(
      `SELECT role FROM \`${login_table}\` WHERE id=? AND site_no=?`,
      [admin_id, site_no]
    );
    if (!adminRows.length || adminRows[0].role !== 'admin') {
      return res.status(403).json({ message: "Not authorized as admin." });
    }

    const [[{ count }]] = await db.query(
      `SELECT COUNT(*) AS count FROM \`${login_table}\` WHERE site_no=?`,
      [site_no]
    );
    const [[limitRow]] = await db.query(
  'SELECT max_users FROM sites WHERE site_no=?',
      [site_no]
    );
    if (limitRow && count >= limitRow.max_users) {
      return res.status(400).json({ message: `User limit reached for site ${site_no}.` });
    }

    await db.query(
      `INSERT INTO \`${login_table}\` (id, password, site_no, role) VALUES (?, ?, ?, ?)`,
      [new_id, password, site_no, role]
    );
    res.json({ message: `User ${new_id} added as ${role}.` });
  } catch (err) {
    console.error("Admin add user error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.delete('/admin-remove-user', async (req, res) => {
  const { admin_id, site_no, user_id } = req.body;
  try {
    const { login_table } = await getTablesForSite(site_no);
    const [adminRows] = await db.query(
      `SELECT role FROM \`${login_table}\` WHERE id=? AND site_no=?`,
      [admin_id, site_no]
    );
    if (!adminRows.length || adminRows[0].role !== 'admin') {
      return res.status(403).json({ message: "Not authorized as admin." });
    }

    const [targetRows] = await db.query(
      `SELECT role FROM \`${login_table}\` WHERE id=? AND site_no=?`,
      [user_id, site_no]
    );
    if (!targetRows.length) {
      return res.status(404).json({ message: `User ${user_id} not found.` });
    }
    if (targetRows[0].role === 'admin') {
      return res.status(400).json({ message: "Cannot remove another admin." });
    }

    await db.query(
      `DELETE FROM \`${login_table}\` WHERE id=? AND site_no=?`,
      [user_id, site_no]
    );
    res.json({ message: `User ${user_id} removed.` });
  } catch (err) {
    console.error("Admin remove user error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.get('/admin-stats/:site_no', async (req, res) => {
  const { site_no } = req.params;
  try {
    const { login_table } = await getTablesForSite(site_no);
    const [[{ count }]] = await db.query(
      `SELECT COUNT(*) AS count FROM \`${login_table}\` WHERE site_no=?`,
      [site_no]
    );
    const [[limitRow]] = await db.query(
  'SELECT max_users FROM sites WHERE site_no=?',
      [site_no]
    );
    res.json({ site_no, current_users: count, max_users: limitRow ? limitRow.max_users : null });
  } catch (err) {
    console.error("Admin stats error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.get('/admin-users/:site_no', async (req, res) => {
  const { site_no } = req.params;
  try {
    const { login_table } = await getTablesForSite(site_no);
    const [rows] = await db.query(
      `SELECT id, role, created_at FROM \`${login_table}\` WHERE site_no=?`,
      [site_no]
    );
    res.json(rows);
  } catch (err) {
    console.error("Admin users error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

/* =========================================================
   ADMIN: CAR HISTORY
========================================================= */
// TODAY (active + completed)
router.get('/admin-car-today/:site_no', async (req, res) => {
  const { site_no } = req.params;
  try {
    const { car_table, dump_table } = await getTablesForSite(site_no);

    const [rows] = await db.query(
      `
      SELECT car_no, valet_id, driver_assigned_for_parking, driver_assigned_for_bringing,
             status, parking_spot, timestamp_car_in_request, timestamp_parked,
             timestamp_car_handed_over
      FROM \`${car_table}\`
      WHERE site_no=? AND DATE(timestamp_car_in_request)=CURDATE()

      UNION ALL

      SELECT car_no, valet_id, driver_assigned_for_parking, driver_assigned_for_bringing,
             status, parking_spot, timestamp_car_in_request, timestamp_parked,
             timestamp_car_handed_over
      FROM \`${dump_table}\`
      WHERE site_no=? AND DATE(timestamp_car_in_request)=CURDATE()

      ORDER BY timestamp_car_in_request DESC
      `,
      [site_no, site_no]
    );

    res.json(rows);
  } catch (err) {
    console.error("Admin today cars error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});


// HISTORY (active + completed)
router.get('/admin-car-history/:site_no/:date', async (req, res) => {
  const { site_no, date } = req.params;
  try {
    const { car_table, dump_table } = await getTablesForSite(site_no);

    const [rows] = await db.query(
      `
      SELECT car_no, valet_id, driver_assigned_for_parking, driver_assigned_for_bringing,
             status, parking_spot, timestamp_car_in_request, timestamp_driver_assigned,
             timestamp_parked, timestamp_car_out_request, timestamp_car_brought,
             timestamp_car_handed_over
      FROM \`${car_table}\`
      WHERE site_no=? AND DATE(timestamp_car_in_request)=?

      UNION ALL

      SELECT car_no, valet_id, driver_assigned_for_parking, driver_assigned_for_bringing,
             status, parking_spot, timestamp_car_in_request, timestamp_driver_assigned,
             timestamp_parked, timestamp_car_out_request, timestamp_car_brought,
             timestamp_car_handed_over
      FROM \`${dump_table}\`
      WHERE site_no=? AND DATE(timestamp_car_in_request)=?

      ORDER BY timestamp_car_in_request DESC
      `,
      [site_no, date, site_no, date]
    );

    res.json(rows);
  } catch (err) {
    console.error("Admin car history error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

/* ===========================
   SEARCH CAR
=========================== */
router.get('/search-car/:site_no/:query?', async (req, res) => {
  const { site_no, query } = req.params;
  try {
    const { car_table } = await getTablesForSite(site_no);

    let sql = `
      SELECT car_no, valet_id, status, parking_spot,
             driver_assigned_for_parking, driver_assigned_for_bringing,
             COALESCE(seen_parking,0) AS seen_parking,
             COALESCE(seen_bringing,0) AS seen_bringing,
             timestamp_car_in_request, timestamp_driver_assigned,
             timestamp_parked, timestamp_car_out_request, timestamp_car_brought,
             timestamp_car_handed_over
      FROM \`${car_table}\`
      WHERE site_no = ?`;

    const params = [site_no];

    if (query) {
      const likeQuery = `%${query}%`;
      const last4Query = `%${query.slice(-4)}%`;
      sql += ` AND (valet_id = ? OR car_no LIKE ? OR RIGHT(car_no,4) LIKE ?)`;
      params.push(query, likeQuery, last4Query);
    }

    sql += ` ORDER BY timestamp_car_in_request DESC LIMIT 100`;

    const [rows] = await db.query(sql, params);

    if (!rows.length) return res.status(404).json({ message: 'No cars found' });

    res.json(rows);
  } catch (err) {
    console.error('Search car error:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});


// ===========================
//  ADMIN: CAR SEARCH
// ===========================
router.get('/admin-search-car/:site_no/:query?', async (req, res) => {
  const { site_no, query } = req.params;
  try {
    const { car_table, dump_table } = await getTablesForSite(site_no);

    let baseSql = `
      SELECT car_no, valet_id, status, parking_spot,
             driver_assigned_for_parking, driver_assigned_for_bringing,
             COALESCE(seen_parking,0) AS seen_parking,
             COALESCE(seen_bringing,0) AS seen_bringing,
             timestamp_car_in_request, timestamp_driver_assigned,
             timestamp_parked, timestamp_car_out_request, timestamp_car_brought,
             timestamp_car_handed_over
      FROM \`TABLE_NAME\`
      WHERE site_no=?`;

    let params = [site_no];

    if (query) {
      const likeQuery = `%${query}%`;
      const last4Query = `%${query.slice(-4)}%`;
      baseSql += ` AND (valet_id = ? OR car_no LIKE ? OR RIGHT(car_no,4) LIKE ?)`;
      params.push(query, likeQuery, last4Query);
    }

    // Active cars
    const [activeRows] = await db.query(baseSql.replace('TABLE_NAME', car_table), params);
    activeRows.forEach(r => r.source = "active");

    // Dump cars
    const [dumpRows] = await db.query(baseSql.replace('TABLE_NAME', dump_table), params);
    dumpRows.forEach(r => r.source = "dump");

    const rows = [...activeRows, ...dumpRows].sort((a, b) =>
      new Date(b.timestamp_car_in_request) - new Date(a.timestamp_car_in_request)
    );

    if (!rows.length) return res.status(404).json({ message: 'No cars found' });

    res.json(rows);
  } catch (err) {
    console.error('Admin search car error:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});


module.exports = router;
