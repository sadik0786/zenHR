const express = require("express");
const router = express.Router();
const {
  login,
  registerEmployee,
  getRoles,
  getUsersByRoles,
  updateMobile,
  uploadAvatar,
  forgotPasswordRequest,
  resetPasswordSelf,
  getCurrentUser,
  getProfile
} = require("../controllers/authController");
const { ROLES } = require("../config/constants");
const { authenticate, authorize } = require("../middleware/authMiddleware");
const multer = require("multer");
const upload = multer({ dest: "uploads/" });

// Authentication Routes
router.get("/me", authenticate, getCurrentUser);
router.post("/login", login);

// Admin/CEO/HR Level
router.post("/register", authenticate, authorize([ROLES.SUPER_ADMIN, ROLES.CEO, ROLES.HR]), registerEmployee);
router.get("/roles", authenticate, getRoles);
router.get("/users", authenticate, authorize([ROLES.SUPER_ADMIN, ROLES.CEO, ROLES.HR]), getUsersByRoles);
router.get("/profile", authenticate, getProfile);
router.post("/mobileUpdate", authenticate, updateMobile);
router.post("/upload", authenticate, upload.single("avatar"), uploadAvatar);

// Public / Self
router.post("/forgot_password", forgotPasswordRequest);
router.post("/reset_password_self", resetPasswordSelf);

module.exports = router;
