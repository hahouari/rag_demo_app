import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rag_demo_app/utils/constants.dart';
import 'package:rag_demo_app/utils/functions.dart';

enum ChatState { streaming, embedding, searching, idle }

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final _controller = TextEditingController();
  final _httpSurreal = getHttpSurreal();
  var _loading = ChatState.idle;
  final _focusNode = FocusNode();
  var _answer = '';

  @override
  void initState() {
    super.initState();
    // Focus on the text field when the page is loaded
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _onSubmitted() async {
    // if already submitted but not yet finished, do nothing
    if (_loading != ChatState.idle) return;
    // if text is empty, do nothing as well
    if (_controller.text.isEmpty) return;

    final query = _controller.text.trim();
    _controller.text = '';

    try {
      setState(() {
        _loading = ChatState.embedding;
        _answer = '';
      });
      final qVector = await getEmbedding(query);
      debugPrint(qVector.toString());

      setState(() => _loading = ChatState.searching);
      final articles = await searchArticles(_httpSurreal, qVector);
      articles.map((a) => debugPrint(a.text));

      var userPrompt = "```context\n";
      for (var article in articles) {
        userPrompt += "${article.text}\n";
      }
      userPrompt += "```\n";
      userPrompt += "```question\n$query\n```";

      debugPrint(userPrompt);

      setState(() => _loading = ChatState.streaming);
      final stream = OpenAI.instance.chat.createStream(
        model: llmModelName,
        messages: [
          createMsg(systemPrompt, OpenAIChatMessageRole.system),
          createMsg(query),
        ],
      );

      await for (var e in stream) {
        final chunck = e.choices.first.delta.content?.first?.text;
        if (chunck == null || chunck.isEmpty) continue;
        setState(() => _answer += chunck);
      }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
    } finally {
      setState(() => _loading = ChatState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_answer.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6.0,
                horizontal: 8.0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: MarkdownBody(data: _answer, selectable: true),
            ),
          ),
        Stack(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Ask me anything',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                contentPadding: const EdgeInsets.only(
                  left: 16.0,
                  right: 64.0,
                ),
              ),
              onSubmitted: (_) => _onSubmitted(),
            ),
            Positioned(
              right: 4,
              top: 4,
              bottom: 4,
              width: 48,
              child: TextButton(
                onPressed: _loading != ChatState.idle ? null : _onSubmitted,
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: _loading != ChatState.idle
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 18,
                      ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
