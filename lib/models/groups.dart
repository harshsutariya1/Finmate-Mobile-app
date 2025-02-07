class Group {
  final String gid;
   String? name;
   String? image;
   String? description;
   List<String>? transactionIds;
   List<String>? memberIds;

  Group({
    required this.gid,
     this.name,
     this.image,
     this.description,
     this.transactionIds,
     this.memberIds,
  });
}