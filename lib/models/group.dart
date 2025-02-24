// ignore_for_file: public_member_api_docs, sort_constructors_first

class Group {
  String? gid;
  String? creatorId;
  String? name;
  String? image;
  String? description;
  String? totalAmount;
  List<String>? transactionIds;
  List<String>? memberIds;

  Group({
    this.gid = "",
    this.creatorId = "",
    this.name = "",
    this.image = "",
    this.description = "",
    this.totalAmount = "0",
    this.transactionIds = const [],
    this.memberIds = const [],
  });

  Group copyWith({
    String? gid,
    String? creatorId,
    String? name,
    String? image,
    String? description,
    String? totalAmount,
    List<String>? transactionIds,
    List<String>? memberIds,
  }) {
    return Group(
      gid: gid ?? this.gid,
      creatorId: creatorId ?? this.creatorId,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      transactionIds: transactionIds ?? this.transactionIds,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  factory Group.fromJson(Map<String, dynamic> map) {
    return Group(
      gid: map['gid'] as String,
      creatorId: map['creatorId'] as String,
      name: map['name'] != null ? map['name'] as String : "Group name",
      image: map['image'] != null ? map['image'] as String : "image",
      description: map['description'] != null
          ? map['description'] as String
          : "description",
      totalAmount:
          map['totalAmount'] != null ? map['totalAmount'] as String : "0.0",
      transactionIds: map['transactionIds'] != null
          ? List<String>.from((map['transactionIds'] ?? []))
          : [],
      memberIds: map['memberIds'] != null
          ? List<String>.from((map['memberIds'] ?? []))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'gid': gid,
      'creatorId': creatorId,
      'name': name,
      'image': image,
      'description': description,
      'totalAmount': totalAmount,
      'transactionIds': transactionIds,
      'memberIds': memberIds,
    };
  }
}
