require("dotenv").config();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const sharp = require("sharp");
const fs = require("fs");
const path = require("path");
const { poolPromise, sql } = require("../db");
const { ROLES } = require("../config/constants");

const JWT_SECRET = process.env.JWT_SECRET || "super_secret_key";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1d";

exports.getCurrentUser = async (req, res) => {
  try {
    const userId = req.user.id;
    const pool = await poolPromise;
    const result = await pool.request().input("userId", sql.Int, userId).query(`
        SELECT U.ID, U.Name, U.Email, U.Mobile, U.RoleID AS UserRoleID, R.RoleName, U.CompanyID, C.CompanyName, U.ProfileImage, U.ReportingID
        FROM dbo.ZenHR_Users U
        INNER JOIN dbo.ZenHR_Roles R ON U.RoleID = R.RoleID
        LEFT JOIN dbo.ZenHR_Companies C ON U.CompanyID = C.CompanyID
        WHERE U.ID = @userId
      `);

    if (result.recordset.length === 0) return res.status(404).json({ success: false, error: "User not found" });
    res.json({ success: true, user: result.recordset[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: "Server error" });
  }
};

exports.registerEmployee = async (req, res) => {
  const { name, email, mobile, password, roleId, reportingId } = req.body;
  try {
    const companyId = req.user.companyId;
    const creatorId = req.user.id;
    const pool = await poolPromise;
    
    // SaaS Plan Limit Check
    const planInfo = await pool.request().input("cid", sql.Int, companyId).query(`
      SELECT C.CompanyID, P.MaxEmployees, (SELECT COUNT(*) FROM ZenHR_Users WHERE CompanyID = C.CompanyID) as CurrentCount
      FROM ZenHR_Companies C JOIN ZenHR_Plans P ON C.PlanID = P.PlanID WHERE C.CompanyID = @cid
    `);
    
    if (planInfo.recordset.length > 0) {
      const { MaxEmployees, CurrentCount } = planInfo.recordset[0];
      if (CurrentCount >= MaxEmployees) {
        return res.status(403).json({ success: false, error: `Plan limit reached (${MaxEmployees} employees). Please upgrade.` });
      }
    }

    const emailCheck = await pool.request().input("Email", sql.NVarChar(150), email).query("SELECT 1 FROM ZenHR_Users WHERE Email = @Email");
    if (emailCheck.recordset.length > 0) return res.status(400).json({ success: false, error: "Email exists" });

    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await pool.request()
      .input("Name", sql.NVarChar(100), name)
      .input("Email", sql.NVarChar(150), email)
      .input("Mobile", sql.VarChar(15), mobile || null)
      .input("PasswordHash", sql.NVarChar(255), hashedPassword)
      .input("RoleID", sql.Int, roleId)
      .input("ReportingID", sql.Int, reportingId || creatorId)
      .input("CompanyID", sql.Int, companyId)
      .input("CreatedBy", sql.Int, creatorId)
      .query(`INSERT INTO ZenHR_Users (Name, Email, Mobile, PasswordHash, RoleID, ReportingID, CompanyID, CreatedBy, UpdatedBy) 
              VALUES (@Name, @Email, @Mobile, @PasswordHash, @RoleID, @ReportingID, @CompanyID, @CreatedBy, 0); SELECT SCOPE_IDENTITY() AS ID`);

    res.json({ success: true, message: "Registered", employee: { id: result.recordset[0].ID, name, email } });
  } catch (err) { res.status(500).json({ error: "Server error" }); }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;
  try {
    const pool = await poolPromise;
    const result = await pool.request().input("Email", sql.NVarChar(150), email).query(`
        SELECT U.*, R.RoleName, C.SubscriptionStatus, C.CompanyName 
        FROM ZenHR_Users U 
        JOIN ZenHR_Roles R ON U.RoleID = R.RoleID
        LEFT JOIN ZenHR_Companies C ON U.CompanyID = C.CompanyID
        WHERE U.Email = @Email`);

    if (result.recordset.length === 0) return res.json({ success: false, message: "Not found" });
    const user = result.recordset[0];
    if (user.SubscriptionStatus === 'INACTIVE' && user.RoleID !== 0) return res.json({ success: false, message: "Expired" });

    const isValid = await bcrypt.compare(password, user.PasswordHash);
    if (!isValid) return res.json({ success: false, message: "Wrong password" });

    const token = jwt.sign({ id: user.ID, role: user.RoleName, companyId: user.CompanyID }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
    res.json({ success: true, token, user: { id: user.ID, name: user.Name, role: user.RoleName, companyId: user.CompanyID, companyName: user.CompanyName } });
  } catch (err) { res.status(500).json({ error: "Server error" }); }
};

exports.updateMobile = async (req, res) => {
    try {
      const userId = req.user.id;
      const { mobile } = req.body;
      const pool = await poolPromise;
      await pool.request().input("uid", sql.Int, userId).input("Mobile", sql.NVarChar(15), mobile).query("UPDATE ZenHR_Users SET Mobile = @Mobile WHERE ID = @uid");
      res.json({ success: true });
    } catch (error) { res.status(500).json({ error: "Server error" }); }
};

exports.uploadAvatar = async (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ error: "No file" });
      const userId = req.user.id;
      const filename = userId + path.extname(req.file.originalname);
      const outputPath = path.join("uploads", filename);
      await sharp(req.file.path).resize(300, 300, { fit: "cover" }).jpeg({ quality: 80 }).toFile(outputPath);
      fs.unlinkSync(req.file.path);
      const fileUrl = `${process.env.SERVER_URL || "http://localhost:5000"}/uploads/${filename}`;
      const pool = await poolPromise;
      await pool.request().input("uid", sql.Int, userId).input("Img", sql.NVarChar(sql.MAX), fileUrl).query("UPDATE ZenHR_Users SET ProfileImage = @Img WHERE ID = @uid");
      res.json({ success: true, url: fileUrl });
    } catch (err) { res.status(500).json({ error: "Server error" }); }
};

exports.getRoles = async (req, res) => {
    try {
      const pool = await poolPromise;
      const result = await pool.request().query("SELECT RoleId, RoleName FROM ZenHR_Roles WHERE IsActive = 1");
      res.json({ success: true, roles: result.recordset });
    } catch (err) { res.status(500).json({ error: "Server error" }); }
};

exports.getUsersByRoles = async (req, res) => {
    try {
      const pool = await poolPromise;
      const requestedRoles = (req.query.role || "").toLowerCase().split(",").filter(r => r);
      const placeholders = requestedRoles.map((_, i) => `@role${i}`).join(",");
      const request = pool.request();
      requestedRoles.forEach((role, index) => request.input(`role${index}`, role));
      const result = await request.input("cid", sql.Int, req.user.companyId).query(`SELECT U.ID, U.Name, U.Email, R.RoleName FROM ZenHR_Users U JOIN ZenHR_Roles R ON U.RoleID = R.RoleID WHERE LOWER(R.RoleName) IN (${placeholders}) AND U.CompanyID = @cid`);
      res.json({ success: true, users: result.recordset });
    } catch (err) { res.status(500).json({ error: "Server error" }); }
};

exports.getProfile = async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request().input("uid", sql.Int, req.user.id).query("SELECT * FROM ZenHR_Users WHERE ID = @uid");
    res.json({ success: true, user: result.recordset[0] });
  } catch (err) { res.status(500).json({ error: "Server error" }); }
};

exports.forgotPasswordRequest = async (req, res) => {
  try {
    const { email } = req.body;
    const pool = await poolPromise;
    const result = await pool.request().input("Email", sql.NVarChar, email).query("SELECT ID FROM ZenHR_Users WHERE Email = @Email");
    if (result.recordset.length === 0) return res.json({ success: true, message: "Reset link sent if email exists" });
    res.json({ success: true, message: "Reset link sent" });
  } catch (err) { res.status(500).json({ error: "Server error" }); }
};

exports.resetPasswordSelf = async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    if (newPassword.length < 6) return res.json({ success: false, error: "Too short" });
    const pool = await poolPromise;
    const hashed = await bcrypt.hash(newPassword, 10);
    await pool.request().input("Email", sql.NVarChar, email).input("pass", sql.NVarChar, hashed).query("UPDATE ZenHR_Users SET PasswordHash = @pass WHERE Email = @Email");
    res.json({ success: true, message: "Success" });
  } catch (err) { res.status(500).json({ error: "Server error" }); }
};
