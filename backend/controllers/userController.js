const { poolPromise, sql } = require("../db");

// Get all employees for the current tenant (Company)
exports.getAllEmployees = async (req, res) => {
  try {
    const companyId = req.user.companyId;
    const pool = await poolPromise;

    const query = `
      SELECT 
        U.ID,
        U.Name,
        U.Email,
        U.Mobile,
        U.ReportingID,
        RU.Name AS ReportingName,
        U.CreatedBy,
        U.EntryTimeStamp as CreatedAt,
        R.RoleName
      FROM dbo.ZenHR_Users U
      INNER JOIN dbo.ZenHR_Roles R ON U.RoleID = R.RoleID
      LEFT JOIN dbo.ZenHR_Users RU ON U.ReportingID = RU.ID
      WHERE U.CompanyID = @cid AND U.RoleID != 0
      ORDER BY U.ID ASC
    `;

    const result = await pool.request()
      .input("cid", sql.Int, companyId)
      .query(query);

    return res.json({
      success: true,
      count: result.recordset.length,
      employees: result.recordset,
    });
  } catch (err) {
    res.status(500).json({ success: false, error: "Server error" });
  }
};

// Delete employee (Tenant Isolated)
exports.deleteEmployee = async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.user.companyId;
    const pool = await poolPromise;

    // Check if user belongs to this company before deleting
    await pool.request()
      .input("id", sql.Int, id)
      .input("cid", sql.Int, companyId)
      .query("DELETE FROM dbo.ZenHR_Users WHERE ID = @id AND CompanyID = @cid");

    return res.json({
      success: true,
      message: "Employee deleted successfully",
    });
  } catch (err) {
    res.status(500).json({ success: false, error: "Server error" });
  }
};
