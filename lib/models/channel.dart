class Channel {
  final String id;
  final String name;
  final String url;
  final String? logo;
  final String? group;
  final String? tvgId;
  final String? tvgName;
  bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.url,
    this.logo,
    this.group,
    this.tvgId,
    this.tvgName,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'logo': logo,
        'group': group,
        'tvgId': tvgId,
        'tvgName': tvgName,
        'isFavorite': isFavorite,
      };

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'],
        name: json['name'],
        url: json['url'],
        logo: json['logo'],
        group: json['group'],
        tvgId: json['tvgId'],
        tvgName: json['tvgName'],
        isFavorite: json['isFavorite'] ?? false,
      );

  Channel copyWith({bool? isFavorite}) => Channel(
        id: id,
        name: name,
        url: url,
        logo: logo,
        group: group,
        tvgId: tvgId,
        tvgName: tvgName,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  @override
  String toString() => 'Channel(name: $name, group: $group)';
}
