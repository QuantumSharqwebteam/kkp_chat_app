class MeetingModel {
  final String id;
  final String title;
  final String location;
  final String link;
  final String startTime;
  final String status;
  final ScheduledPerson scheduledPerson;
  final List<dynamic> participants;
  final String createdAt;
  final int version;

  MeetingModel({
    required this.id,
    required this.title,
    required this.location,
    required this.link,
    required this.startTime,
    required this.status,
    required this.scheduledPerson,
    required this.participants,
    required this.createdAt,
    required this.version,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      link: json['link'] ?? '',
      startTime: json['startTime'] ?? '',
      status: json['status'] ?? '',
      scheduledPerson: ScheduledPerson.fromJson(json['scheduledPerson'] ?? {}),
      participants: json['participants'] ?? [],
      createdAt: json['createdAt'] ?? '',
      version: json['__v'] ?? 0,
    );
  }

  /// Mirrors [fromJson]'s key names so a logged payload can be compared
  /// directly against the raw API response.
  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'location': location,
        'link': link,
        'startTime': startTime,
        'status': status,
        'scheduledPerson': scheduledPerson.toJson(),
        'participants': participants,
        'createdAt': createdAt,
        '__v': version,
      };
}

class ScheduledPerson {
  final String id;
  final String email;
  final String name;

  ScheduledPerson({
    required this.id,
    required this.email,
    required this.name,
  });

  factory ScheduledPerson.fromJson(Map<String, dynamic> json) {
    return ScheduledPerson(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'email': email,
        'name': name,
      };
}
