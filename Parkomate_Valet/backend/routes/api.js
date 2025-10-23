const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken'); // Import jsonwebtoken
const db = require('../db');
const { translateText } = require('../deepl');
const { getTablesForSite } = require('../lib/table-mapper');

// IMPORTANT: In a real application, store this in an environment variable!
const JWT_SECRET = 'your_super_secret_jwt_key'; 

/* =========================================================
   LOGIN (GLOBAL + SUPERADMIN)
========================================================= */
router.post('/login', async (req, res) => {
  const { site_no, id, password } = req.body;
  try {
    let user;
    let role;

    if (site_no == 0) {
      // Superadmin login
      const [rows] = await db.query(
        'SELECT id, "superadmin" AS role, 0 AS site_no FROM superadmin_login WHERE id=? AND password=?',
        [id, password]
      );
      if (!rows.length) return res.status(401).json({ message: 'Invalid credentials' });
      user = rows[0];
      role = user.role;
    } else {
      // Normal site login
      const { login_table } = await getTablesForSite(site_no);
      const [rows] = await db.query(
        `SELECT id, role, site_no FROM \`${login_table}\` WHERE id=? AND password=? AND site_no=?`,
        [id, password, site_no]
      );
      if (!rows.length) return res.status(401).json({ message: 'Invalid credentials' });
      user = rows[0];
      role = user.role;
    }

    // Generate JWT token
    const token = jwt.sign({ 
      id: user.id, 
      role: user.role, 
      site_no: user.site_no 
    }, JWT_SECRET, { expiresIn: '1h' });

    // Return the token along with user data
    return res.json({
      message: 'Login successful',
      id: user.id,
      role: role,
      site_no: user.site_no,
      token: token // This is the new field required by the frontend
    });

  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

/* =========================================================
   SUPERADMIN (GLOBAL)
========================================================= */

// Set site limit -> updates `sites.max_users`
router.post('/set-site-limit', async (req, res) => {
  const { site_no, max_users } = req.body;
  try {
    await db.query(
      `UPDATE sites SET max_users=? WHERE site_no=?`,
      [max_users, site_no]
    );
    res.json({ message: `Limit for site ${site_no} set to ${max_users} users.` });
  } catch (err) {
    console.error("Set site limit error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get all sites and their current user counts
router.get('/get-sites', async (req, res) => {
  try {
    const [sites] = await db.query('SELECT site_no, max_users, login_table FROM sites');
    const result = [];

    for (const site of sites) {
      try {
        const [rows] = await db.query(`SELECT COUNT(*) AS cnt FROM \`${site.login_table}\``);
        result.push({
          site_no: site.site_no,
          max_users: site.max_users,
          current_users: rows[0].cnt
        });
      } catch (err) {
        console.warn(`No login table for site ${site.site_no}:`, err.message);
        result.push({
          site_no: site.site_no,
          max_users: site.max_users,
          current_users: 0
        });
      }
    }

    res.json(result);
  } catch (err) {
    console.error("Get sites error:", err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

/* =========================================================
   TRANSLATION (GLOBAL)
========================================================= */
router.post('/translate', async (req, res) => {
  const { text, targetLang } = req.body;
  if (!text) {
    return res.status(400).json({ message: "Text is required" });
  }
  try {
    const translated = await translateText(text, targetLang || "EN");
    res.json({ translated });
  } catch (err) {
    res.status(500).json({ message: "Translation failed", error: err.message });
  }
});

module.exports = router;