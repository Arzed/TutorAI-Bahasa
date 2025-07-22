import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:chatbot_tutor/constant.dart';

import 'package:chatbot_tutor/model/message.dart';
import 'package:chatbot_tutor/openendedpage.dart';
import 'package:chatbot_tutor/provider/messagesprovider.dart';
import 'package:chatbot_tutor/texttospeech/TextToSpeechAPI.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import 'package:provider/provider.dart';

import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
// import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_10.dart';
// import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_2.dart';
// import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_3.dart';
// import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_4.dart';
// import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_5.dart';
// import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_6.dart';
// import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_7.dart';
// import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_8.dart';
// import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_9.dart';

import 'package:audioplayers/audioplayers.dart';

class VerbModePage extends StatefulWidget {
  @override
  _VerbModePageState createState() => _VerbModePageState();
}

class _VerbModePageState extends State<VerbModePage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  String _chatbotResponse = '';

  void _submitMessage() {
    String user_input = _textController.text;
    _textController.clear();
    setState(() {
      _chatbotResponse = 'Loading...';
      Provider.of<MessagesNotifier>(context, listen: false).add_Verb_Message(
        Messages(response: user_input, type: MessageType.user),
      );
    });

    _getChatbotResponse(user_input).then((response) {
      setState(() {
        var text = "";
        _chatbotResponse = response;

        var responseJson = json.decode(response);
        text = responseJson['choices'][0]['message']['content'];
        
        Provider.of<MessagesNotifier>(context, listen: false).add_Verb_Message(
          Messages(response: text, type: MessageType.chatbot),
        );
        // AudioPlayerWidget(text: text);
      });
    });
  }

  Future<String> _getChatbotResponse(String user_input) async {
    String url = 'https://api.deepseek.com/chat/completions';

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey'
    };

    var program_rules = """
        Pretends you are Indonesian language teacher that only teach about Indonesia verbs.
        Answer only indonesian verbs related question, other than verbs, say sorry.
        Only give the other example of verbs and sentences when received 'next' input.
        I will give you prompt in any language, and you will respond using this format:-
        Indonesian verbs (English Verbs)
        then give two sample sentences using that verbs with english translation separate by a number with spacing and open bracket 
        """;

    Map<String, dynamic> body = {
      "model": "deepseek-chat",
      "messages": [
        {"role": "system", "content": program_rules},
        {"role": "user", "content": user_input}
      ],
      "stream": false
    };

    String jsonBody = json.encode(body);

    http.Response response =
        await http.post(Uri.parse(url), headers: headers, body: jsonBody);
    return response.body;
  }

  // The controller for the input field.
  final TextEditingController _controller = TextEditingController();

  // The user's input.
  String _input = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _hasSentWelcomeMessage = false;

  @override
  Widget build(BuildContext context) {
    final messagesNotifier = Provider.of<MessagesNotifier>(context);
    final String avatar = messagesNotifier.avatar;
    Color chatbotbubblecolor = Color(0xFF4ECDC4);

    String introscript =
        "Hi! Welcome to Verb mode!\nLike English, Bahasa Indonesia also has its own set of vast vocabulary for verbs; verbs refer to the words people use to describe an action, act, or activity." +
            "\n\nHow to use Verb mode?\n1) Simply ask me the verb in English ,and i will provide you the correct verb in indonesian with sample sentences.\n\n2) Just simply  type , \" to (what verb) \", and i will teach the verb in indonesian with sample sentences." +
            "\nExample: To \"sleep\"\n\n3) Question that is not related to Verbs, I may not answer it.\n\n4) Thats it!  Enjoy your Indonesian Verbs learning!";

    if (Provider.of<MessagesNotifier>(context).verbmessages.isEmpty) {
      _hasSentWelcomeMessage = true;
      Provider.of<MessagesNotifier>(context, listen: false).add_Verb_Message(
        Messages(response: introscript, type: MessageType.chatbot),
      );
      Provider.of<MessagesNotifier>(context, listen: false).verbmessages.clear;
      print(_hasSentWelcomeMessage);
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Color(0xFF4ECDC4),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 28,),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verb Mode',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 10),
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFFDF0E6),
              backgroundImage: AssetImage(
                avatar == "Kiki" ? 'assets/images/ed696be3-b0aa-46c8-a566-7004455369fd_removalai_preview.png' : 'assets/images/99694bdb-f493-4935-b34a-266751503d5c_removalai_preview.png',
              ),
            )
          ],
        ),
        centerTitle: true,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      backgroundColor: Color(0xFFE8F9F5),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(top: 16, bottom: 8),
              itemCount: messagesNotifier.verbmessages.length,
              itemBuilder: (context, index) {
                final message = messagesNotifier.verbmessages[index];
                return _buildMessageBubble(message, avatar);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
            ),
          _buildInputField(),
        ],
      )
    );
  }

  Widget _buildMessageBubble(Messages message, String avatar) {
    final isUser = message.type == MessageType.user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange,
              backgroundImage: AssetImage(
                avatar == "Kiki" ? 'assets/images/ed696be3-b0aa-46c8-a566-7004455369fd_removalai_preview.png' : 'assets/images/99694bdb-f493-4935-b34a-266751503d5c_removalai_preview.png',
              ),
            ),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(left: isUser ? 0 : 8, right: isUser ? 8 : 0),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDarkMode ? Colors.teal[700] : Color(0xFFFF9E7D))
                    : (isDarkMode ? Colors.grey[800] : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 12 : 0),
                  topRight: Radius.circular(isUser ? 0 : 12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.response,
                    style: TextStyle(
                      color: isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                      fontSize: 15,
                    ),
                  ),
                  if (!isUser) ...[
                    SizedBox(height: 8),
                    AudioPlayerMini(text: message.response),
                  ],
                ],
              ),
            ),
          ),
          if (isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              backgroundImage: AssetImage('assets/images/user.png'),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.send, color: Color(0xFFFF9E7D)),
              onPressed: _submitMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}


class AudioPlayerWidget extends StatefulWidget {
  final String text;

  AudioPlayerWidget({required this.text});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  String? _path;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  synthesizeText(String text) async {
    final String audioContent = await TextToSpeechAPI().synthesizeText(
      text,
      context.read<MessagesNotifier>().voicename,
      context.read<MessagesNotifier>().gender,
    );
    if (audioContent == null) return;

    final bytes = Base64Decoder().convert(audioContent, 0, audioContent.length);
    final dir = await getTemporaryDirectory();
    // Generate a unique file name by including a timestamp.
    final file = File(
        '${dir.path}/wavenet_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await file.writeAsBytes(bytes);
    if (file.existsSync()) {
      // The file exists.
      setState(() {
        _path = file.path;
      });
    } else {
      // The file does not exist.
      print("File not found: ${file.path}");
    }
  }

  @override
  void initState() {
    super.initState();
    synthesizeText(widget.text);
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _path != null
            ? Row(
                children: [
                  IconButton(
                    icon: _isPlaying
                        ? const Icon(Icons.pause)
                        : const Icon(Icons.play_arrow),
                    onPressed: () {
                      if (_isPlaying) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.play(DeviceFileSource(_path!));
                      }
                      setState(() {
                        _isPlaying = !_isPlaying;
                      });
                    },
                  ),
                  Expanded(
                    child: Slider(
                      value: _position.inSeconds.toDouble() ?? 0,
                      onChanged: (double value) {
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      },
                      min: 0,
                      max: _duration.inSeconds.toDouble() ?? 0,
                    ),
                  ),
                ],
              )
            : Container(),
      ],
    );
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    super.dispose();
  }
}
