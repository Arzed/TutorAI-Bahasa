import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:chatbot_tutor/constant.dart';

import 'package:chatbot_tutor/model/message.dart';
import 'package:chatbot_tutor/provider/messagesprovider.dart';
import 'package:chatbot_tutor/texttospeech/TextToSpeechAPI.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

class VocabModePage extends StatefulWidget {
  @override
  _VocabModePageState createState() => _VocabModePageState();
}

class _VocabModePageState extends State<VocabModePage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _chatbotResponse = '';

  void _submitMessage() {
    String user_input = _textController.text;
    _textController.clear();
    setState(() {
      _chatbotResponse = 'Loading...';
      Provider.of<MessagesNotifier>(context, listen: false).add_Vocab_Message(
        Messages(response: user_input, type: MessageType.user),
      );
    });

    _getChatbotResponse(user_input).then((response) {
      setState(() {
        var text = "";
        _chatbotResponse = response;

        var responseJson = json.decode(response);
        text = responseJson['choices'][0]['message']['content'];
        
        Provider.of<MessagesNotifier>(context, listen: false).add_Vocab_Message(
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
        Act as if you are a Indonesian language teacher that only teach about Indonesian vocabularys. 
        Only give ten words in Indonesian and English that related to given category.
        I will give you prompt in any language, and you will respond using this format:-
        Title

        English word : Indonesian word. 

        then the list continues down to ten vocabularies.
        """;

    //Use the previous prompt as context and the user's input as the prompt

    // var program_input = program_rules + "\nSo my prompt is " + user_input + ".";

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
    final avatar = messagesNotifier.avatar;
    Color chatbotbubblecolor = Color(0xFFFFD166);

    String introscript =
        "Welcome to Vocab mode! I will help you learn Indonesia vocabulary. Select which Vocab Category you want to learn: \n\nfood, animals, languages, directions, clothes, school, human body, travel, science, people, jobs, time, survival, colors, weather, places, shopping, etc.";

    if (Provider.of<MessagesNotifier>(context).vocabmessages.isEmpty) {
      _hasSentWelcomeMessage = true;
      Provider.of<MessagesNotifier>(context, listen: false).add_Vocab_Message(
        Messages(response: introscript, type: MessageType.chatbot),
      );
      Provider.of<MessagesNotifier>(context, listen: false).vocabmessages.clear;
      print(_hasSentWelcomeMessage);
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: chatbotbubblecolor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to the previous page
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vocab Mode',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 10),
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFFDF0E6),
              backgroundImage: AssetImage(
                avatar == "Kiki" ? 'assets/images/ed696be3-b0aa-46c8-a566-7004455369fd_removalai_preview.png' : 'assets/images/99694bdb-f493-4935-b34a-266751503d5c_removalai_preview.png',
              ),
            ),
          ],
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      backgroundColor: Color(0xFFFFF8E8),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount:
                    Provider.of<MessagesNotifier>(context).vocabmessages.length,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                itemBuilder: (context, index) {
                  Messages message = Provider.of<MessagesNotifier>(context)
                      .vocabmessages[index];

                  return Column(
                    children: <Widget>[
                      Container(
                        child: Stack(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40.0),
                              child: ChatBubble(
                                  clipper: ChatBubbleClipper1(
                                      type: message.type == MessageType.user
                                          ? BubbleType.sendBubble
                                          : BubbleType.receiverBubble),
                                  alignment: message.type == MessageType.user
                                      ? Alignment.topRight
                                      : Alignment.topLeft,
                                  margin: EdgeInsets.only(top: 25, bottom: 10),
                                  backGroundColor:
                                      message.type == MessageType.user
                                          ? chatbotbubblecolor
                                          : Color(0xffE7E7ED),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.7,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            message.response,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: message.type ==
                                                        MessageType.user
                                                    ? Colors.white
                                                    : Colors.black),
                                          ),
                                          message.type == MessageType.chatbot
                                              ? AudioPlayerWidget(
                                                  text: message.response,
                                                )
                                              : SizedBox(),
                                        ],
                                      ),
                                    ),
                                  )),
                            ),
                            Positioned(
                              top: 20,
                              left: message.type == MessageType.user ? null : 0,
                              right:
                                  message.type == MessageType.user ? 0 : null,
                              child: message.type == MessageType.user
                                  ? CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.green,
                                      backgroundImage: AssetImage('assets/images/user.png')
                                    )
                                  : CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.orange,
                                      backgroundImage: AssetImage(
                                        avatar == "Kiki" ? 'assets/images/ed696be3-b0aa-46c8-a566-7004455369fd_removalai_preview.png' : 'assets/images/99694bdb-f493-4935-b34a-266751503d5c_removalai_preview.png',
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: chatbotbubblecolor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        controller: _textController,
                        decoration: InputDecoration(
                          enabledBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: "Enter your message",
                          hintStyle: TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        minLines: 1,
                        maxLines: null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: IconButton(
                        onPressed: () {
                          _submitMessage();
                          setState(() {
                            _input = _controller.text;
                            _chatbotResponse =
                                _getChatbotResponse(_input).toString();
                            _controller.clear();
                          });
                        },
                        icon: Icon(
                          Icons.send,
                          size: 30,
                          color: Colors.white,
                        )),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
