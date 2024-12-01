class Article {
  final String text;
  final double score;

  Article({required this.text, required this.score});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      text: json['text'] as String,
      score: json['score'] as double,
    );
  }
}
