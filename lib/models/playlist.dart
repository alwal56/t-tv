class Playlist {
  final String id;
  final String name;
  final String url;
  final DateTime addedAt;
  final int channelCount;
  final bool isActive;

  Playlist({
    required this.id,
    required this.name,
    required this.url,
    required this.addedAt,
    this.channelCount = 0,
    this.isActive = true,
  });

  Playlist copyWith({String? name, bool? isActive, int? channelCount}) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      url: url,
      addedAt: addedAt,
      channelCount: channelCount ?? this.channelCount,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'addedAt': addedAt.toIso8601String(),
        'channelCount': channelCount,
        'isActive': isActive,
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'],
        name: json['name'],
        url: json['url'],
        addedAt: DateTime.parse(json['addedAt']),
        channelCount: json['channelCount'] ?? 0,
        isActive: json['isActive'] ?? true,
      );
}
