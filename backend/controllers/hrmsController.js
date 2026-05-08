const { poolPromise, sql } = require("../db");

exports.addAllLeaveType = async (req, res) => {
  const { leaveName, leaveCount } = req.body;
  const companyId = req.user.companyId;
  try {
    const pool = await poolPromise;
    const check = await pool.request()
      .input("name", sql.VarChar(100), leaveName)
      .input("cid", sql.Int, companyId)
      .query("SELECT 1 FROM ZenHR_LeaveTypes WHERE LeaveName = @name AND CompanyID = @cid AND IsActive = 1");
    if (check.recordset.length > 0) return res.status(400).json({ success: false, message: "Exists" });
    await pool.request()
      .input("name", sql.VarChar(100), leaveName)
      .input("count", sql.Int, leaveCount)
      .input("cid", sql.Int, companyId)
      .query("INSERT INTO ZenHR_LeaveTypes (LeaveName, LeaveCount, IsActive, CompanyID) VALUES (@name, @count, 1, @cid)");
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: "error" }); }
};

exports.getAllLeaveType = async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .input("cid", sql.Int, req.user.companyId)
      .query("SELECT Id, LeaveName, LeaveCount FROM ZenHR_LeaveTypes WHERE IsActive = 1 AND CompanyID = @cid ORDER BY LeaveName");
    res.json({ success: true, data: result.recordset });
  } catch (err) { res.status(500).json({ error: "error" }); }
};

exports.applyLeave = async (req, res) => {
  const { leaveTypeId, fromDate, toDate, days, sessionDay, reason } = req.body;
  try {
    const pool = await poolPromise;
    await pool.request()
      .input("uid", sql.Int, req.user.id)
      .input("ltid", sql.Int, leaveTypeId)
      .input("fd", sql.Date, fromDate)
      .input("td", sql.Date, toDate)
      .input("days", sql.Decimal(5, 2), days)
      .input("sd", sql.Int, sessionDay)
      .input("rs", sql.VarChar(150), reason || "")
      .input("cid", sql.Int, req.user.companyId)
      .query("INSERT INTO ZenHR_Leaves (UserID, LeaveTypeID, FromDate, ToDate, TotalDays, SessionDay, Reason, Status, CompanyID) VALUES (@uid, @ltid, @fd, @td, @days, @sd, @rs, 'PENDING', @cid)");
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: "error" }); }
};

exports.getMyAppliedLeaves = async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
        .input("uid", sql.Int, req.user.id)
        .input("cid", sql.Int, req.user.companyId)
        .query("SELECT al.Id, lt.LeaveName, al.FromDate, al.ToDate, al.TotalDays, al.Status FROM ZenHR_Leaves al JOIN ZenHR_LeaveTypes lt ON al.LeaveTypeID = lt.Id WHERE al.UserID = @uid AND al.CompanyID = @cid ORDER BY al.EntryTimeStamp DESC");
    res.json({ success: true, data: result.recordset });
  } catch (err) { res.status(500).json({ error: "error" }); }
};

exports.getOtherLeavesRequest = async (req, res) => {
  const role = req.user.role;
  try {
    const pool = await poolPromise;
    let query = "SELECT al.Id, u.Name as employeeName, lt.LeaveName, al.FromDate, al.ToDate, al.Status FROM ZenHR_Leaves al JOIN ZenHR_LeaveTypes lt ON al.LeaveTypeID = lt.Id JOIN ZenHR_Users u ON al.UserID = u.ID WHERE al.CompanyID = @cid AND al.Status = 'PENDING'";
    if (role !== 'ceo' && role !== 'super_admin') query += " AND u.ReportingID = @uid";
    const result = await pool.request().input("uid", sql.Int, req.user.id).input("cid", sql.Int, req.user.companyId).query(query);
    res.json({ success: true, data: result.recordset });
  } catch (err) { res.status(500).json({ error: "error" }); }
};

exports.updateLeaveStatus = async (req, res) => {
  const { id } = req.params;
  const { status, remarks } = req.body;
  try {
    const pool = await poolPromise;
    await pool.request()
      .input("id", sql.Int, id)
      .input("status", sql.VarChar(20), status)
      .input("uid", sql.Int, req.user.id)
      .input("cid", sql.Int, req.user.companyId)
      .input("rem", sql.VarChar(250), remarks || "")
      .query("UPDATE ZenHR_Leaves SET Status = @status, ApprovedBy = @uid, ApprovedOn = GETDATE(), RejectReason = @rem WHERE Id = @id AND CompanyID = @cid");
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: "error" }); }
};
