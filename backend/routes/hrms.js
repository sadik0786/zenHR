const express = require("express");
const router = express.Router();

const {
  addAllLeaveType,
  getAllLeaveType,
  applyLeave,
  getMyAppliedLeaves,
  getOtherLeavesRequest,
  updateLeaveStatus,
} = require("../controllers/hrmsController");
const { authenticate, authorize } = require("../middleware/authMiddleware");
const { ROLES } = require("../config/constants");

router.post(
  "/leave-types",
  authenticate,
  authorize([ROLES.HR]),
  addAllLeaveType,
);
router.get("/leave-types", authenticate, getAllLeaveType);
router.post(
  "/apply-leave",
  authenticate,
  authorize([
    ROLES.HR,
    ROLES.Accountant,
    ROLES.Manager,
    ROLES.Admin,
    ROLES.Employee,
  ]),
  applyLeave,
);
router.get("/my-leaves", authenticate, getMyAppliedLeaves);
router.get("/other-leaves", authenticate, getOtherLeavesRequest);
router.put("/update-leave-status/:id", authenticate, updateLeaveStatus);

module.exports = router;
