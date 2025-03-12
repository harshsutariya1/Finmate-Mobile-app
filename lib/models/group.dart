// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:flutter/material.dart';

class Group {
  String? gid;
  String? creatorId;
  String? name;
  String? image;
  DateTime? date;
  TimeOfDay? time;
  String? description;
  String? totalAmount;
  List<Transaction>? listOfTransactions;
  List<String>? memberIds;
  List<UserData>? listOfMembers;
  Map<String, String>? membersBalance;

  Group({
    this.gid = "",
    this.creatorId = "",
    this.name = "",
    this.image = "",
    DateTime? date,
    this.time,
    this.description = "",
    this.totalAmount = "0",
    this.listOfTransactions,
    this.memberIds,
    this.listOfMembers,
    this.membersBalance,
  }) : date = date ?? DateTime.now() {
    time = time ?? TimeOfDay.now();
    listOfTransactions = listOfTransactions ?? [];
    memberIds = memberIds ?? [];
    listOfMembers = listOfMembers ?? [];
    membersBalance = membersBalance ?? {};
  }

  Group copyWith({
    String? gid,
    String? creatorId,
    String? name,
    String? image,
    DateTime? date,
    TimeOfDay? time,
    String? description,
    String? totalAmount,
    List<Transaction>? listOfTransactions,
    List<String>? memberIds,
    List<UserData>? listOfMembers,
    Map<String, String>? membersBalance,
  }) {
    return Group(
      gid: gid ?? this.gid,
      creatorId: creatorId ?? this.creatorId,
      name: name ?? this.name,
      image: image ?? this.image,
      date: date ?? this.date,
      time: time ?? this.time,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      listOfTransactions: listOfTransactions ?? this.listOfTransactions,
      memberIds: memberIds ?? this.memberIds,
      listOfMembers: listOfMembers ?? this.listOfMembers,
      membersBalance: membersBalance ?? this.membersBalance,
    );
  }

  factory Group.fromJson(Map<String, dynamic> map) {
    return Group(
      gid: map['gid'] as String,
      creatorId: map['creatorId'] as String,
      name: map['name'] != null ? map['name'] as String : "Group name",
      image: map['image'] != null ? map['image'] as String : "image",
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      time: (map['time'] != null)
          ? TimeOfDay(
              hour: int.parse(map['time'].split(":")[0]),
              minute: int.parse(map['time'].split(":")[1]),
            )
          : TimeOfDay.now(),
      description: map['description'] != null
          ? map['description'] as String
          : "description",
      totalAmount:
          map['totalAmount'] != null ? map['totalAmount'] as String : "0.0",
      listOfTransactions: map['listOfTransactions'] != null
          ? List<Transaction>.from((map['listOfTransactions'] ?? []))
          : [],
      memberIds: map['memberIds'] != null
          ? List<String>.from((map['memberIds'] ?? []))
          : [],
      listOfMembers: map['listOfMembers'] != null
          ? List<UserData>.from((map['listOfMembers'] ?? []))
          : [],
      membersBalance: map['membersBalance'] != null
          ? Map<String, String>.from((map['membersBalance'] ?? {}))
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'gid': gid,
      'creatorId': creatorId,
      'name': name,
      'image': image,
      'date': date?.toIso8601String(),
      'time': '${time?.hour}:${time?.minute}',
      'description': description,
      'totalAmount': totalAmount,
      'listOfTransactions': listOfTransactions,
      'memberIds': memberIds,
      'listOfMembers': listOfMembers,
      'membersBalance': membersBalance,
    };
  }
}
