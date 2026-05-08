class LeaveTypeResponseModel {
  bool? success;
  String? message;
  List<LeaveTypeData>? data;

  LeaveTypeResponseModel({this.success, this.message, this.data});

  factory LeaveTypeResponseModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeResponseModel(
      success: json["success"],
      message: json["message"],
      data: json["data"] != null
          ? List<LeaveTypeData>.from(json["data"].map((x) => LeaveTypeData.fromJson(x)))
          : [],
    );
  }
}

class LeaveTypeData {
  int? id;
  String? leaveName;
  int? leaveCount;
  bool? isActive;
  String? entryTimeStamp;

  LeaveTypeData({this.id, this.leaveName, this.leaveCount, this.isActive, this.entryTimeStamp});

  factory LeaveTypeData.fromJson(Map<String, dynamic> json) {
    return LeaveTypeData(
      id: json["Id"],
      leaveName: json["LeaveName"],
      leaveCount: json["LeaveCount"],
      isActive: json["IsActive"],
      entryTimeStamp: json["EntryTimeStamp"],
    );
  }
}
