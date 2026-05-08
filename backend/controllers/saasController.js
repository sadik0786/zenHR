const bcrypt = require("bcryptjs");
const { poolPromise, sql } = require("../db");

// Get all companies
exports.getAllCompanies = async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request().query(`
      SELECT C.*, P.PlanName, 
      (SELECT COUNT(*) FROM ZenHR_Users WHERE CompanyID = C.CompanyID AND RoleID != 0) as EmployeeCount
      FROM ZenHR_Companies C
      JOIN ZenHR_Plans P ON C.PlanID = P.PlanID
    `);
    res.json({ success: true, data: result.recordset });
  } catch (err) { res.status(500).json({ error: "Server Error" }); }
};

// Create Company
exports.createCompany = async (req, res) => {
  const { companyName, adminName, adminEmail, adminPassword, planId } = req.body;
  try {
    const pool = await poolPromise;
    const companyResult = await pool.request()
      .input("name", sql.NVarChar(150), companyName)
      .input("planId", sql.Int, planId || 1)
      .query("INSERT INTO ZenHR_Companies (CompanyName, PlanID) VALUES (@name, @planId); SELECT SCOPE_IDENTITY() AS CompanyID");
    
    const companyId = companyResult.recordset[0].CompanyID;
    const hashed = await bcrypt.hash(adminPassword, 10);
    
    await pool.request()
      .input("Name", sql.NVarChar(100), adminName)
      .input("Email", sql.NVarChar(150), adminEmail)
      .input("Pass", sql.NVarChar(255), hashed)
      .input("Cid", sql.Int, companyId)
      .query("INSERT INTO ZenHR_Users (Name, Email, PasswordHash, RoleID, CompanyID, ReportingID, CreatedBy, UpdatedBy) VALUES (@Name, @Email, @Pass, 1, @Cid, 0, 0, 0)");
      
    res.json({ success: true, message: "Company onboarded successfully" });
  } catch (err) { res.status(500).json({ error: "Server Error" }); }
};

// Update Company
exports.updateCompany = async (req, res) => {
  const { companyId, companyName, subscriptionStatus, planId } = req.body;
  try {
    const pool = await poolPromise;
    await pool.request()
      .input("id", sql.Int, companyId)
      .input("name", sql.NVarChar(150), companyName)
      .input("status", sql.VarChar(20), subscriptionStatus)
      .input("plan", sql.Int, planId)
      .query("UPDATE ZenHR_Companies SET CompanyName = @name, SubscriptionStatus = @status, PlanID = @plan WHERE CompanyID = @id");
    res.json({ success: true, message: "Company updated" });
  } catch (err) { res.status(500).json({ error: "Server Error" }); }
};

// Delete Company
exports.deleteCompany = async (req, res) => {
  const { companyId } = req.params;
  try {
    const pool = await poolPromise;
    await pool.request().input("cid", sql.Int, companyId).query("DELETE FROM ZenHR_Users WHERE CompanyID = @cid");
    await pool.request().input("cid", sql.Int, companyId).query("DELETE FROM ZenHR_Companies WHERE CompanyID = @cid");
    res.json({ success: true, message: "Company deleted" });
  } catch (err) { res.status(500).json({ error: "Server Error" }); }
};
