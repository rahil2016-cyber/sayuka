const jwt = require('jsonwebtoken');

const verifyAdmin = (req, res, next) => {
  const token = req.cookies.admin_token;

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access denied. No token provided.' });
  }

  try {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      return res.status(500).json({ success: false, message: 'Authentication configuration error.' });
    }

    const decoded = jwt.verify(token, secret);
    
    if (decoded.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Access denied. Unauthorized role.' });
    }

    req.admin = decoded;
    next();
  } catch (ex) {
    res.status(401).json({ success: false, message: 'Invalid or expired token.' });
  }
};

module.exports = verifyAdmin;
