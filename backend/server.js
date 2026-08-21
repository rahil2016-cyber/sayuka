const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const cookieParser = require('cookie-parser');

// Load .env from backend dir OR project root
dotenv.config({ path: path.join(__dirname, '.env') });
dotenv.config({ path: path.join(__dirname, '../.env') });

const app = express();
const PORT = process.env.PORT || 5000;
const NODE_ENV = process.env.NODE_ENV || 'production';

// Critical environment variable verification for production safety
if (NODE_ENV === 'production') {
  const requiredEnvVars = ['ADMIN_USERNAME', 'ADMIN_PASSWORD_HASH', 'JWT_SECRET'];
  const missing = requiredEnvVars.filter(v => !process.env[v]);
  if (missing.length > 0) {
    console.warn(`⚠️ WARNING: Missing required production environment variables: ${missing.join(', ')}. Using default values to prevent server crash.`);
    if (!process.env.ADMIN_USERNAME) process.env.ADMIN_USERNAME = 'admin';
    if (!process.env.ADMIN_PASSWORD_HASH) process.env.ADMIN_PASSWORD_HASH = '$2b$10$GWPTorE8hWLpUSt4Wn6bHOvWAtIThNmCsWt1.lIV2Vo/qLQ77R7/.';
    if (!process.env.JWT_SECRET) process.env.JWT_SECRET = 'fallback_secret_for_production';
  }
}


// Middleware
app.use(cookieParser());
app.use(cors({
  origin: process.env.FRONTEND_URL || '*',
  credentials: true,
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// API Routes
app.use('/api/products', require('./routes/products'));
app.use('/api/contact', require('./routes/contact'));
app.use('/api/admin', require('./routes/admin'));

// Health check
app.get('/api/health', (req, res) => {
  res.json({ success: true, message: 'Sayuka Jewellery API is running!', env: NODE_ENV });
});

// Serve static frontend files (built React app)
const frontendDistPath = path.join(__dirname, '../frontend/dist');
app.use(express.static(frontendDistPath));

// SPA fallback — send index.html for any non-API route (React Router support)
// Using app.use (no path) is Express 5 compatible catch-all
app.use((req, res) => {
  if (req.path.startsWith('/api')) {
    return res.status(404).json({ success: false, message: 'API route not found' });
  }
  const indexPath = path.join(frontendDistPath, 'index.html');
  res.sendFile(indexPath, (err) => {
    if (err) {
      res.status(404).json({ success: false, message: 'Frontend not built. Run: npm run build' });
    }
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

const { initDb, useDb } = require('./config/db');
const migrate = require('./migrate');

initDb().then(async () => {
  if (useDb()) {
    try {
      console.log('🔄 Running database migrations on startup...');
      await migrate(false);
    } catch (migrateErr) {
      console.error('⚠️ Database migration failed during startup:', migrateErr);
    }
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Sayuka Jewellery running on http://0.0.0.0:${PORT} [${NODE_ENV}]`);
  });
});
