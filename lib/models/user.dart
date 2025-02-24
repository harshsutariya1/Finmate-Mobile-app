class UserData {
  String? uid;
  String? name;
  String? userName;
  String? pfpURL;
  String? email;
  String? gender;
  DateTime? dob;
  List<String>? transactionIds;
  List<String>? groupIds;

  UserData({
    required this.uid,
    required this.name,
    this.userName = "",
    this.pfpURL = "",
    this.email = "",
    this.gender = "",
    this.dob,
    this.transactionIds = const [],
    this.groupIds = const [],
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      uid: json['uid'] as String,
      name: json['name'] as String,
      userName: json['userName'] as String? ?? "",
      pfpURL: json['pfpURL'] as String? ?? "",
      email: json['email'] as String,
      gender: json['gender'] as String? ?? "",
      dob: json['dob'] == null ? null : DateTime.parse(json['dob']),
      transactionIds: List<String>.from(json['transactionIds'] ?? []),
      groupIds: List<String>.from(json['groupIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'userName': userName,
      'pfpURL': pfpURL,
      'email': email,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'transactionIds': transactionIds,
      'groupIds': groupIds,
    };
  }
}
