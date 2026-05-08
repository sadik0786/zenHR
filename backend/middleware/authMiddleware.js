const jwt = require("jsonwebtoken");
const saasConfig = require("../config/saas_config");
const JWT_SECRET = process.env.JWT_SECRET || "secret123";

function authenticate(req, res, next) {
  const authHeader = req.headers["authorization"];
  if (!authHeader) {
    return res.status(401).json({ success: false, error: "Authorization header missing" });
  }

  const token = authHeader.startsWith("Bearer ") ? authHeader.split(" ")[1] : authHeader;

  if (!token) {
    return res.status(401).json({ error: "Token missing" });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = {
      id: decoded.id || decoded.userId || decoded.UserId,
      role: (decoded.role || "").toString().toLowerCase().trim(),
      reportingId: decoded.reportingId || 0,
      // If SaaS mode, take from token. if On-premise, use default.
      companyId: saasConfig.DEPLOYMENT_MODE === 'SAAS' ? (decoded.companyId || 1) : saasConfig.DEFAULT_COMPANY_ID,
    };
    next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}

function authorize(roles = []) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: "Authentication required" });
    }
    const userRole = (req.user.role || "").toLowerCase();
    const allowedRoles = roles.map((r) => (r || "").toLowerCase());
    
    // Super Admin can bypass most role checks if needed, but here we stay strict
    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({ error: "Forbidden: insufficient role permission" });
    }
    next();
  };
}

module.exports = { authenticate, authorize };
