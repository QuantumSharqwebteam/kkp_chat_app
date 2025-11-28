class GroupModel {
  final String id;
  final String groupName;
  final String groupDescription;
  final List<String> admins;
  final List<String> members;
  final String groupImage;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime lastActivity;
  final int version;

  GroupModel({
    required this.id,
    required this.groupName,
    required this.groupDescription,
    required this.admins,
    required this.members,
    required this.groupImage,
    required this.isDeleted,
    required this.createdAt,
    required this.lastActivity,
    required this.version,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'] ?? '',
      groupName: json['groupName'] ?? '',
      groupDescription: json['groupDescription'] ?? '',
      admins: List<String>.from(json['admins'] ?? []),
      members: List<String>.from(json['members'] ?? []),
      groupImage: json['groupImage'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActivity: DateTime.parse(json['lastActivity'] ?? DateTime.now().toIso8601String()),
      version: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'admins': admins,
      'members': members,
      'groupImage': groupImage,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      '__v': version,
    };
  }

  GroupModel copyWith({
    String? id,
    String? groupName,
    String? groupDescription,
    List<String>? admins,
    List<String>? members,
    String? groupImage,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? lastActivity,
    int? version,
  }) {
    return GroupModel(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      admins: admins ?? this.admins,
      members: members ?? this.members,
      groupImage: groupImage ?? this.groupImage,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      version: version ?? this.version,
    );
  }
}
