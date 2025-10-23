const db = require('../db');

async function getTablesForSite(site_no) {
  const s = parseInt(site_no, 10);
  if (isNaN(s) || s <= 0) {
    throw new Error('Invalid site number');
  }

  const [rows] = await db.query(
    'SELECT login_table, car_table, dump_table FROM sites WHERE site_no = ?',
    [s]
  );

  if (!rows.length) {
    throw new Error('Site not found');
  }

  const { login_table, car_table, dump_table } = rows[0];

  // Safety check: prevent SQL injection
  const safe = (t) => /^[A-Za-z0-9_]+$/.test(t);
  if (![login_table, car_table, dump_table].every(safe)) {
    throw new Error('Unsafe table name');
  }

  return {
    login_table,
    car_table,
    dump_table,
    users_table: `site_${s}_users`,  // 🔑 dynamically build users table
    site_no: s
  };
}

module.exports = { getTablesForSite };
