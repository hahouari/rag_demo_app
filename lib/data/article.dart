class Article {
  final String text;
  final double sim;

  Article({required this.text, required this.sim});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      text: json['text'] as String,
      sim: json['sim'] as double,
    );
  }
}
