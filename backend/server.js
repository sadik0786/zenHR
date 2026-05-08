require("dotenv").config();
const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const path = require("path");
const { poolPromise, sql } = require("./db");
const saasConfig = require("./config/saas_config");

const authRoutes = require("./routes/auth");
const userRoutes = require("./routes/user");
const hrmsRoutes = require("./routes/hrms");
const saasRoutes = require("./routes/saas");

const PORT = process.env.PORT || 5000;
const app = express();

app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));

// ---------------- ZenHR SaaS Database Initialization ---------------- //
async function initializeSaaS() {
  try {
    const pool = await poolPromise;
    console.log("🛠️ Initializing ZenHR SaaS Architecture...");

    // 1. Create Companies Table
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ZenHR_Companies')
      BEGIN
        CREATE TABLE ZenHR_Companies (
          CompanyID INT PRIMARY KEY IDENTITY(1,1),
          CompanyName NVARCHAR(150) NOT NULL,
          Domain NVARCHAR(100),
          LogoUrl NVARCHAR(MAX),
          PlanID INT DEFAULT 1,
          SubscriptionStatus NVARCHAR(50) DEFAULT 'ACTIVE',
          ExpiryDate DATETIME,
          IsActive BIT DEFAULT 1,
          CreatedDate DATETIME DEFAULT GETDATE(),
          UpdatedDate DATETIME DEFAULT GETDATE()
        )
      END
    `);

    // 2. Create Plans Table
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ZenHR_Plans')
      BEGIN
        CREATE TABLE ZenHR_Plans (
          PlanID INT PRIMARY KEY IDENTITY(1,1),
          PlanName NVARCHAR(50) NOT NULL,
          MaxEmployees INT DEFAULT 10,
          Price DECIMAL(10,2) DEFAULT 0.0,
          Features NVARCHAR(MAX)
        )
        IF NOT EXISTS (SELECT 1 FROM ZenHR_Plans)
        BEGIN
          INSERT INTO ZenHR_Plans (PlanName, MaxEmployees, Price) VALUES ('Free', 10, 0), ('Pro', 100, 5000), ('Enterprise', 9999, 20000)
        END
      END
    `);

    // 3. Update/Create Application Tables
    const tables = {
      'ZenHR_Users': `(
        ID INT PRIMARY KEY IDENTITY(1,1),
        Name NVARCHAR(100),
        Email NVARCHAR(150) UNIQUE,
        Mobile VARCHAR(15),
        PasswordHash NVARCHAR(255),
        RoleID INT,
        ReportingID INT,
        CompanyID INT,
        ProfileImage NVARCHAR(MAX),
        IsActive BIT DEFAULT 1,
        CreatedBy INT,
        UpdatedBy INT,
        EntryTimeStamp DATETIME DEFAULT GETDATE()
      )`,
      'ZenHR_LeaveTypes': `(
        Id INT PRIMARY KEY IDENTITY(1,1),
        LeaveName VARCHAR(100),
        LeaveCount INT,
        CompanyID INT,
        IsActive BIT DEFAULT 1,
        EntryTimeStamp DATETIME DEFAULT GETDATE()
      )`,
      'ZenHR_Leaves': `(
        Id INT PRIMARY KEY IDENTITY(1,1),
        UserID INT,
        LeaveTypeID INT,
        FromDate DATE,
        ToDate DATE,
        TotalDays DECIMAL(5,2),
        SessionDay INT,
        Reason VARCHAR(150),
        Status VARCHAR(20) DEFAULT 'PENDING',
        ApprovedBy INT,
        ApprovedOn DATETIME,
        RejectReason VARCHAR(250),
        CompanyID INT,
        EntryTimeStamp DATETIME DEFAULT GETDATE()
      )`
    };

    for (const [tableName, schema] of Object.entries(tables)) {
      await pool.request().query(`
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = '${tableName}')
        BEGIN
          CREATE TABLE ${tableName} ${schema}
          PRINT '✅ Created table ${tableName}'
        END
      `);
    }

    // 4. Roles Table (If missing)
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ZenHR_Roles')
      BEGIN
        CREATE TABLE ZenHR_Roles (
          RoleID INT PRIMARY KEY,
          RoleName NVARCHAR(50),
          IsActive BIT DEFAULT 1
        )
        INSERT INTO ZenHR_Roles (RoleID, RoleName) VALUES (0, 'super_admin'), (1, 'ceo'), (2, 'hr'), (3, 'accountant'), (4, 'manager'), (5, 'admin'), (6, 'employee')
      END
    `);

    // 5. Seed System Company & Super Admin
    const companyCheck = await pool.request().query("SELECT * FROM ZenHR_Companies WHERE CompanyID = 1");
    if (companyCheck.recordset.length === 0) {
      await pool.request().query("SET IDENTITY_INSERT ZenHR_Companies ON; INSERT INTO ZenHR_Companies (CompanyID, CompanyName, PlanID) VALUES (1, 'ZenHR Systems', 3); SET IDENTITY_INSERT ZenHR_Companies OFF;");
    }

    const SuperAdminEmail = process.env.SUPER_ADMIN_EMAIL || "admin@zenhr.com";
    const check = await pool.request().input("email", sql.NVarChar, SuperAdminEmail).query("SELECT * FROM ZenHR_Users WHERE Email = @email");

    if (check.recordset.length === 0) {
      const hashed = await bcrypt.hash(process.env.SUPER_ADMIN_PASSWORD || "admin$123", 10);
      await pool.request()
        .input("name", sql.NVarChar, "Super Admin")
        .input("email", sql.NVarChar, SuperAdminEmail)
        .input("password", sql.NVarChar, hashed)
        .query(`INSERT INTO ZenHR_Users (Name, Email, PasswordHash, RoleID, CompanyID, ReportingID, CreatedBy, UpdatedBy) 
                VALUES (@name, @email, @password, 0, 1, 0, 0, 0)`);
      console.log("✅ ZenHR Super Admin created:", SuperAdminEmail);
    }

    console.log("🚀 ZenHR SaaS Architecture is ready.");
  } catch (error) {
    console.error("❌ ZenHR Initialization failed:", error);
  }
}

// Routes
app.get("/", (req, res) => res.json({ status: "working", app: "ZenHR", mode: saasConfig.DEPLOYMENT_MODE }));
app.use("/api/auth", authRoutes);
app.use("/api/user", userRoutes);
app.use("/api/hrms", hrmsRoutes);
app.use("/api/saas", saasRoutes);

// Start server
app.listen(PORT, "0.0.0.0", async () => {
  console.log(`🚀 ZenHR Server running on http://0.0.0.0:${PORT}`);
  await initializeSaaS();
});
