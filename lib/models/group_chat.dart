import 'package:flutter/material.dart';

class Chat {
  String? cid;
  String? senderId;
  String? massage;
  DateTime? date;
  TimeOfDay? time;
  bool? isImage;

  Chat({
    this.cid = "",
    this.senderId = "",
    this.massage = "",
    DateTime? date,
    this.time,
    this.isImage = false,
  }) : date = date ?? DateTime.now() {
    time = time ?? TimeOfDay.now();
  }

  Chat copyWith({
    String? cid,
    String? senderId,
    String? massage,
    DateTime? date,
    TimeOfDay? time,
    bool? isImage,
  }) {
    return Chat(
      cid: cid ?? this.cid,
      senderId: senderId ?? this.senderId,
      massage: massage ?? this.massage,
      date: date ?? this.date,
      time: time ?? this.time,
      isImage: isImage ?? this.isImage,
    );
  }

  factory Chat.fromJson(Map<String, dynamic> map) {
    return Chat(
      cid: map['cid'] != null ? map['cid'] as String : "",
      senderId: map['senderId'] != null ? map['senderId'] as String : "",
      massage: map['massage'] != null ? map['massage'] as String : "",
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      time: (map['time'] != null)
          ? TimeOfDay(
              hour: int.parse(map['time'].split(":")[0]),
              minute: int.parse(map['time'].split(":")[1]),
            )
          : TimeOfDay.now(),
      isImage: map['isImage'] != null ? map['isImage'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cid': cid,
      'senderId': senderId,
      'massage': massage,
      'date': date?.toIso8601String(),
      'time': '${time?.hour}:${time?.minute}',
      'isImage': isImage,
    };
  }
}
