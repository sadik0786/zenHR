import 'dart:convert';

List<LeaveTypeRequestModel> leaveTypeModelFromJson(String str) => List<LeaveTypeRequestModel>.from(
  json.decode(str).map((x) => LeaveTypeRequestModel.fromJson(x)),
);

String leaveTypeRequestModelToJson(List<LeaveTypeRequestModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class LeaveTypeRequestModel {
  int? id;
  String? leaveName;
  int? leaveCount;

  LeaveTypeRequestModel({this.id, this.leaveName, this.leaveCount});

  factory LeaveTypeRequestModel.fromJson(Map<String, dynamic> json) => LeaveTypeRequestModel(
    id: json["Id"],
    leaveName: json["LeaveName"],
    leaveCount: json["LeaveCount"],
  );

  Map<String, dynamic> toJson() => {"Id": id, "LeaveName": leaveName, "LeaveCount": leaveCount};
}
