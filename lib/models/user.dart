class UserData {
  String? uid;
  String? name;
  String? pfpURL;
  String? email;
  bool? isOnline;
  String? phoneNumber;
  int? noOfGroups;
  List<String>? groupIds;
  int? noOfChats;
  List<String>? chatIds;
  // String? dateOfBirth;
  String? gender;

  UserData({
    required this.uid,
    required this.name,
    this.pfpURL = "",
    this.email = "",
    this.isOnline = false,
    this.phoneNumber = "",
    this.noOfGroups = 0,
    this.groupIds = const [],
    this.noOfChats = 0,
    this.chatIds = const [],
    // this.dateOfBirth = "",
    this.gender = "",
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      uid: json['uid'] as String,
      name: json['name'] as String,
      pfpURL: json['pfpURL'] as String? ?? "",
      email: json['email'] as String,
      isOnline: json['isOnline'] as bool? ?? false,
      phoneNumber: json['phoneNumber'] as String? ?? "",
      noOfGroups: json['noOfGroups'] as int? ?? 0,
      // Fix here: Convert List<dynamic> to Set<String>
      groupIds: List<String>.from(json['groupIds'] ?? []),
      noOfChats: json['noOfChats'] as int? ?? 0,
      // Fix here: Convert List<dynamic> to Set<String>
      chatIds:List<String>.from(json['chatIds'] ?? []),
      // dateOfBirth: json['dateOfBirth'] as String? ?? "",
      gender: json['gender'] as String? ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'pfpURL': pfpURL,
      'email': email,
      'isOnline': isOnline,
      'phoneNumber': phoneNumber,
      'noOfGroups': noOfGroups,
      'groupIds': groupIds,
      'noOfChats': noOfChats,
      'chatIds': chatIds,
      // 'dateOfBirth': dateOfBirth,
      'gender': gender,
    };
  }
}
