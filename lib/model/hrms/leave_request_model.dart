class LeaveRequestModel {
  final int id;
  final int userId;
  final String employeeName;
  final String leaveTypeName;
  final String fromDate;
  final String toDate;
  final double totalDays;
  final int sessionDay;
  final String? reason;
  final String? rejectReason;
  final String? approverName;
  final String status;

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.leaveTypeName,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.sessionDay,
    this.reason,
    this.rejectReason,
    this.approverName,
    required this.status,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] ?? json['Id'],
      userId: json['userId'] ?? json['UserTaskMateAppId'],
      employeeName: json['employeeName'] ?? json['EmployeeName'] ?? "Self",
      leaveTypeName: json['leaveName'] ?? json['LeaveName'] ?? json['leaveTypeName'] ?? "",
      fromDate: json['fromDate'] ?? json['FromDate'],
      toDate: json['toDate'] ?? json['ToDate'],
      totalDays: (json['totalDays'] ?? json['TotalDays'] as num).toDouble(),
      sessionDay: json['sessionDay'] ?? json['SessionDay'],
      reason: json['reason'] ?? json['Reason'] ?? '',
      rejectReason: json['rejectReason'] ?? json['RejectReason'] ?? '',
      approverName: json['approverName'] ?? json['ApproverName'] ?? '',
      status: json['status'] ?? json['Status'],
    );
  }
  LeaveRequestModel copyWith({String? status, String? rejectReason, String? approverName}) {
    return LeaveRequestModel(
      id: id,
      userId: userId,
      employeeName: employeeName,
      leaveTypeName: leaveTypeName,
      fromDate: fromDate,
      toDate: toDate,
      totalDays: totalDays,
      sessionDay: sessionDay,
      reason: reason,
      approverName: approverName ?? this.approverName,
      rejectReason: rejectReason ?? this.rejectReason,
      status: status ?? this.status,
    );
  }
}
