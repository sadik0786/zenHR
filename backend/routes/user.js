const express = require("express");
const { authenticate, authorize } = require("../middleware/authMiddleware");
const { getAllEmployees, deleteEmployee } = require("../controllers/userController");
const { ROLES, ROLE_IDS } = require("../config/constants");
const router = express.Router();
router.get(
  "/employees",
  authenticate,
  authorize([ROLES.CEO, ROLES.HR]),
  getAllEmployees,
);
router.delete(
  "/employee/:id",
  authenticate,
  authorize([ROLES.CEO, ROLES.HR]),
  deleteEmployee,
);
module.exports = router;
