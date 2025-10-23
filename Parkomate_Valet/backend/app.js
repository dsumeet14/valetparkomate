require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

// ===== Middleware =====
app.use(cors());


// Increase JSON & URL-encoded payload limits
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ limit: '20mb', extended: true }));

// ===== Serve Frontend =====

// Global frontend (login + superadmin)
app.use('/', express.static(path.join(__dirname, '../frontend')));

// Site 1 role pages
app.use('/site_1', express.static(path.join(__dirname, '../frontend/site_1')));

// Site 2 role pages
app.use('/site_2', express.static(path.join(__dirname, '../frontend/site_2')));

// Fallback root -> global index.html
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// ===== API Routes =====

// Global APIs (login, superadmin, etc.)
app.use('/api', require('./routes/api'));

// Site 1 APIs
app.use('/api/site_1', require('./site_1/routes/api'));

// Site 2 APIs
app.use('/api/site_2', require('./site_2/routes/api'));

// ===== Start Server =====
const PORT = process.env.PORT || 3000;
/*app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});*/
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server running at http://0.0.0.0:${PORT}`);
});
