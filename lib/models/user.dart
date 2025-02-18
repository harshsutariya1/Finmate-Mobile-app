class UserData {
  String? uid;
  String? name;
  String? userName;
  String? pfpURL;
  String? email;
  String? gender;
  int? cash;
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
    this.cash = 0,
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
      cash: json['cash'] as int? ?? 0,
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
      'cash': cash,
      'dob': dob?.toIso8601String(),
      'transactionIds': transactionIds,
      'groupIds': groupIds,
    };
  }
}
