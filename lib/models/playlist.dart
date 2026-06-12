class Playlist {
  final String id;
  final String name;
  final String url;
  final DateTime addedAt;
  final int channelCount;
  final bool isActive;

  /// اسم المجلد الذي يحدّده المستخدم — تُجمع قنوات هذا المصدر تحته
  final String? groupName;

  /// نوع المصدر: 'm3u' أو 'xtream'
  final String kind;

  Playlist({
    required this.id,
    required this.name,
    required this.url,
    required this.addedAt,
    this.channelCount = 0,
    this.isActive = true,
    this.groupName,
    this.kind = 'm3u',
  });

  Playlist copyWith({String? name, bool? isActive, int? channelCount}) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      url: url,
      addedAt: addedAt,
      channelCount: channelCount ?? this.channelCount,
      isActive: isActive ?? this.isActive,
      groupName: groupName,
      kind: kind,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'addedAt': addedAt.toIso8601String(),
        'channelCount': channelCount,
        'isActive': isActive,
        'groupName': groupName,
        'kind': kind,
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'],
        name: json['name'],
        url: json['url'],
        addedAt: DateTime.parse(json['addedAt']),
        channelCount: json['channelCount'] ?? 0,
        isActive: json['isActive'] ?? true,
        groupName: json['groupName'],
        kind: json['kind'] ?? 'm3u',
      );
}
