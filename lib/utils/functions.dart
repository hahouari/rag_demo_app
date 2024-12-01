import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rag_demo_app/data/article.dart';
import 'package:rag_demo_app/utils/constants.dart';

OpenAIChatCompletionChoiceMessageModel createMsg(
  String msg, [
  OpenAIChatMessageRole role = OpenAIChatMessageRole.user,
]) {
  return OpenAIChatCompletionChoiceMessageModel(
    content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(msg)],
    role: role,
  );
}

Dio getHttpSurreal() {
  final username = dotenv.env['SURREAL_USER'] ?? '';
  final password = dotenv.env['SURREAL_PASS'] ?? '';
  final basicAuth = base64Encode(utf8.encode("$username:$password"));
  final namespace = dotenv.env['SURREAL_NAMESPACE'] ?? '';
  final database = dotenv.env['SURREAL_DATABASE'] ?? '';
  return Dio(BaseOptions(
    baseUrl: "http://localhost:28900/",
    headers: {
      "Authorization": "Basic $basicAuth",
      "Accept": "application/json",
      "surreal-ns": namespace,
      "surreal-db": database,
      "Content-Type": null,
    },
  ));
}

Future<List<double>> getEmbedding(String text) async {
  final embedding = await OpenAI.instance.embedding.create(
    model: embedModelName,
    input: text,
  );

  return embedding.data.first.embeddings;
}

Future<List<Article>> searchArticles(
  Dio httpSurreal,
  List<double> qVector,
) async {
  final res = await httpSurreal.post(
    "sql",
    data: embeddingSearchQuery,
    queryParameters: {"q_vector": jsonEncode(qVector)},
  );
  final result = res.data[0]['result'] as List<dynamic>;
  return result.map((a) => Article.fromJson(a)).toList(growable: false);
}
