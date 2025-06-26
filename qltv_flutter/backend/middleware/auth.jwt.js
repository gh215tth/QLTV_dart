// middleware/auth.jwt.js
const jwt = require('jsonwebtoken');
const config = require('../config/auth.config.js');

const verifyToken = (req, res, next) => {
  console.log("======= VERIFY TOKEN =======");
  console.log(">> Request Headers:", req.headers);

  let token = req.headers["x-access-token"] || req.headers["authorization"];

  if (token && token.startsWith("Bearer ")) {
    token = token.slice(7); // Remove 'Bearer '
  }

  console.log(">> Final Token:", token);

  if (!token) {
    return res.status(403).json({ message: "No token provided!" });
  }

  jwt.verify(token, config.secret, (err, decoded) => {
    if (err) {
      console.error(">> ❌ JWT verification failed:", err.message);
      return res.status(401).json({ message: "Unauthorized!" });
    }

    console.log(">> ✅ Token verified");
    console.log(">> Decoded payload:", decoded);

    // ✅ Attach user object to request
    req.user = {
      id: decoded.id,
      role: decoded.role
    };

    next();
  });
};

module.exports = {
  verifyToken
};
