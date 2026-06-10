class NewsArticle {
  final String title;
  final String? description;
  final String url;
  final String? imageUrl;
  final String source;
  final DateTime? pubDate;
  final bool isTransfer;

  const NewsArticle({
    required this.title,
    this.description,
    required this.url,
    this.imageUrl,
    required this.source,
    this.pubDate,
    this.isTransfer = false,
  });

  /// Transfer keywords in Arabic + English
  static const _transferKeywords = [
    'انتقال', 'ضم', 'صفقة', 'عقد', 'يرحل', 'ينضم', 'مليون',
    'يوقع', 'تعاقد', 'رحيل', 'استقطاب',
    'transfer', 'sign', 'deal', 'fee', 'bid', 'joins',
  ];

  static bool _detectTransfer(String text) {
    final t = text.toLowerCase();
    return _transferKeywords.any((k) => t.contains(k.toLowerCase()));
  }

  factory NewsArticle.fromRssItem({
    required String title,
    String? description,
    required String link,
    String? imageUrl,
    required String source,
    DateTime? pubDate,
  }) {
    final combined = '$title ${description ?? ''}';
    return NewsArticle(
      title: title,
      description: description,
      url: link,
      imageUrl: imageUrl,
      source: source,
      pubDate: pubDate,
      isTransfer: _detectTransfer(combined),
    );
  }
}
