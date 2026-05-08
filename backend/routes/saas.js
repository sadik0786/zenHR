const express = require("express");
const router = express.Router();
const { getAllCompanies, createCompany, updateCompany, deleteCompany } = require("../controllers/saasController");
const { authenticate, authorize } = require("../middleware/authMiddleware");
const { ROLES } = require("../config/constants");

// All routes are protected and restricted to SUPER_ADMIN
router.use(authenticate);
router.use(authorize([ROLES.SUPER_ADMIN]));

router.get("/companies", getAllCompanies);
router.post("/create-company", createCompany);
router.put("/update-company", updateCompany);
router.delete("/delete-company/:companyId", deleteCompany);

module.exports = router;
