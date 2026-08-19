const mysql = require('mysql2/promise');

let pool = null;
let useDb = false;

const initDb = async () => {
  const isProduction = process.env.NODE_ENV === 'production';
  const hasDbConfig = process.env.DB_HOST || process.env.DB_USER || process.env.DB_NAME;

  // If there's no DB config in development, fall back immediately to avoid timeout lag
  if (!isProduction && !hasDbConfig) {
    console.warn('👉 No DB config environment variables found. Falling back to in-memory store for local development.');
    useDb = false;
    return;
  }

  try {
    pool = mysql.createPool({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'sayuka_jewellery',
      waitForConnections: true,
      connectionLimit: 5,
      queueLimit: 0,
      enableKeepAlive: true,
      keepAliveInitialDelay: 0
    });

    // Test connection
    const connection = await pool.getConnection();
    connection.release();
    useDb = true;
    console.log('✅ Connected to MySQL database successfully.');
  } catch (err) {
    pool = null;
    useDb = false;
    console.warn('⚠️ MySQL database connection failed.');
    console.warn(`Reason: ${err.message}`);
    
    if (isProduction) {
      console.error('❌ CRITICAL WARNING: Database connection failed in production! Falling back to in-memory store.');
    } else {
      console.warn('👉 Falling back to in-memory store for local development.');
    }
  }
};

const getConnection = async () => {
  if (!pool) {
    await initDb();
  }
  if (!pool) {
    throw new Error('Database pool could not be initialized.');
  }
  return await pool.getConnection();
};

module.exports = {
  initDb,
  pool: () => pool,
  useDb: () => useDb,
  getConnection
};
