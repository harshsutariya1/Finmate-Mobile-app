// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:finmate/models/transaction.dart';
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
  List<String>? transactionIds;
  List<Transaction>? listOfTransactions;
  List<String>? memberIds;
  List<String>? memberPfpics;

  Group({
    this.gid = "",
    this.creatorId = "",
    this.name = "",
    this.image = "",
    DateTime? date,
    this.time,
    this.description = "",
    this.totalAmount = "0",
    this.transactionIds = const [],
    this.listOfTransactions = const [],
    this.memberIds = const [],
    this.memberPfpics = const [],
  }) : date = date ?? DateTime.now() {
    time = time ?? TimeOfDay.now();
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
    List<String>? transactionIds,
    List<Transaction>? listOfTransactions,
    List<String>? memberIds,
    List<String>? memberPfpics,
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
      transactionIds: transactionIds ?? this.transactionIds,
      listOfTransactions: listOfTransactions ?? this.listOfTransactions,
      memberIds: memberIds ?? this.memberIds,
      memberPfpics: memberPfpics ?? this.memberPfpics,
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
      transactionIds: map['transactionIds'] != null
          ? List<String>.from((map['transactionIds'] ?? []))
          : [],
      listOfTransactions: map['listOfTransactions'] != null
          ? List<Transaction>.from((map['listOfTransactions'] ?? []))
          : [],
      memberIds: map['memberIds'] != null
          ? List<String>.from((map['memberIds'] ?? []))
          : [],
      memberPfpics: map['memberPfpics'] != null
          ? List<String>.from((map['memberPfpics'] ?? []))
          : [],
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
      'transactionIds': transactionIds,
      'listOfTransactions': listOfTransactions,
      'memberIds': memberIds,
      'memberPfpics': memberPfpics,
    };
  }
}
