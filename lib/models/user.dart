class UserData {
  String? uid;
  String? firstName;
  String? lastName;
  String? name;
  String? userName;
  String? pfpURL;
  String? email;
  String? gender;
  DateTime? dob;
  // List<String>? groupIds;
  // List<String>? bankAccountIds;
  // List<String>? walletIds;
  // List<String>? cardIds;

  UserData({
    required this.uid,
    required this.name,
    this.firstName = "",
    this.lastName = "",
    this.userName = "",
    this.pfpURL = "",
    this.email = "",
    this.gender = "",
    this.dob,
    // this.groupIds = const [],
    // this.bankAccountIds = const [],
    // this.walletIds = const [],
    // this.cardIds = const [],
  });

  UserData copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? name,
    String? userName,
    String? pfpURL,
    String? email,
    String? gender,
    DateTime? dob,
    List<String>? groupIds,
    List<String>? bankAccountIds,
    List<String>? walletIds,
    List<String>? cardIds,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      userName: userName ?? this.userName,
      pfpURL: pfpURL ?? this.pfpURL,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      // groupIds: groupIds ?? this.groupIds,
      // bankAccountIds: bankAccountIds ?? this.bankAccountIds,
      // walletIds: walletIds ?? this.walletIds,
      // cardIds: cardIds ?? this.cardIds,
    );
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      uid: json['uid'] as String,
      firstName: json['firstName'] as String? ?? "",
      lastName: json['lastName'] as String? ?? "",
      name: json['name'] as String,
      userName: json['userName'] as String? ?? "",
      pfpURL: json['pfpURL'] as String? ?? "",
      email: json['email'] as String,
      gender: json['gender'] as String? ?? "",
      dob: json['dob'] == null ? null : DateTime.parse(json['dob']),
      // groupIds: List<String>.from(json['groupIds'] ?? []),
      // bankAccountIds: List<String>.from(json['bankAccountIds'] ?? []),
      // walletIds: List<String>.from(json['walletIds'] ?? []),
      // cardIds: List<String>.from(json['cardIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'name': name,
      'userName': userName,
      'pfpURL': pfpURL,
      'email': email,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      // 'groupIds': groupIds,
      // 'bankAccountIds': bankAccountIds,
      // 'walletIds': walletIds,
      // 'cardIds': cardIds,
    };
  }
}