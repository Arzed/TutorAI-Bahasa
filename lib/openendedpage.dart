import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:chatbot_tutor/model/message.dart';
import 'package:chatbot_tutor/provider/messagesprovider.dart';
import 'package:chatbot_tutor/texttospeech/TextToSpeechAPI.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:chatbot_tutor/constant.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OpenEndedPage extends StatefulWidget {
  @override
  _OpenEndedPageState createState() => _OpenEndedPageState();
}

class _OpenEndedPageState extends State<OpenEndedPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _sendWelcomeMessage();
  }

  void _sendWelcomeMessage() {
    if (Provider.of<MessagesNotifier>(context, listen: false).openmessages.isEmpty) {
      String introscript = 
        "Welcome to Open Mode! I will help you learn Indonesia. You can ask me anything about Indonesia. "
        "I will explain your question in English and will provide examples in Indonesian.\n\n"
        "Examples:\n"
        "- How to order food in Indonesia\n"
        "- What is the meaning of 'bijaksana'\n\n"
        "I will provide easy-to-understand answers. Let's get started!";
      
      Provider.of<MessagesNotifier>(context, listen: false).add_Open_Message(
        Messages(response: introscript, type: MessageType.chatbot),
      );
      _playAudio(introscript);
    }
  }

  Future<void> _playAudio(String text) async {
    final String audioContent = await TextToSpeechAPI().synthesizeText(
      text,
      context.read<MessagesNotifier>().voicename,
      context.read<MessagesNotifier>().gender,
    );
    
    if (audioContent.isEmpty) return;

    final bytes = Base64Decoder().convert(audioContent);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/wavenet_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await file.writeAsBytes(bytes);
    
    if (file.existsSync()) {
      await _audioPlayer.play(DeviceFileSource(file.path));
    }
  }

  void _submitMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final userInput = _textController.text.trim();
    _textController.clear();
    
    setState(() {
      _isLoading = true;
      Provider.of<MessagesNotifier>(context, listen: false).add_Open_Message(
        Messages(response: userInput, type: MessageType.user),
      );
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    try {
      final response = await _getChatbotResponse(userInput);
      final responseJson = json.decode(response);
      String text = responseJson['choices'][0]['message']['content'];
      
      // List<String> splitText = text.split("\n\nAnswer:");
      // if (splitText.length > 1) {
      //   text = splitText[1].trim();
      // }

      Provider.of<MessagesNotifier>(context, listen: false).add_Open_Message(
        Messages(response: text, type: MessageType.chatbot),
      );
      
      // await _playAudio(text);
    } catch (e) {
      print('Error: $e');
      Provider.of<MessagesNotifier>(context, listen: false).add_Open_Message(
        Messages(response: "Sorry, I encountered an error. Please try again.", type: MessageType.chatbot),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getChatbotResponse(String user_input) async {
    try {
      // Validate input
      if (user_input.isEmpty) {
        throw Exception('Input cannot be empty');
      }

      // API configuration
      // const String model = 'gpt-3.5-turbo-instruct';
      const String url = 'https://api.deepseek.com/chat/completions';

      // Headers
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey'
      };

      // Instruction prompt
      const String program_rules = """
          Act as a Language Tutor chatbot. 
          Answer only Indonesian language related topics, otherwise apologize.
          Respond to teach Bahasa Indonesia language. 
          Explain the meaning/context/usage in English for non-Indonesian speakers.
          Provide 1 example sentence using the Indonesian word/phrase.
          """;

      // Combine rules with user input
      final String program_input = program_rules + "\nPrompt: " + user_input + ".";

      // Request body
      final Map<String, dynamic> body = {
        "model": "deepseek-chat",
        "messages": [
          {"role": "system", "content": program_rules},
          {"role": "user", "content": user_input}
        ],
        "stream": false
        // "prompt": program_input,
      };

      // Make API call
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30)); // Add timeout

      // Check response status
      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Handle different HTTP error codes
        if (response.statusCode == 401) {
          throw Exception('Invalid API key - please check your configuration');
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded - please wait before making more requests');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error - please try again later');
        } else {
          throw Exception('Failed to get response: ${response.statusCode}');
        }
      }
    } on TimeoutException {
      throw Exception('Request timed out - please check your internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Data format error: ${e.message}');
    } on Exception catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesNotifier = Provider.of<MessagesNotifier>(context);
    final avatar = messagesNotifier.avatar;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: isDarkMode ? Colors.grey[900] : Color(0xFFFF9E7D),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Open Mode',
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
        centerTitle: true,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.lightBlue[50],
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(top: 16, bottom: 8),
              itemCount: messagesNotifier.openmessages.length,
              itemBuilder: (context, index) {
                final message = messagesNotifier.openmessages[index];
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
      ),
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

class AudioPlayerMini extends StatefulWidget {
  final String text;

  const AudioPlayerMini({required this.text});

  @override
  _AudioPlayerMiniState createState() => _AudioPlayerMiniState();
}

class _AudioPlayerMiniState extends State<AudioPlayerMini> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    
    try {
      final String audioContent = await TextToSpeechAPI().synthesizeText(
        widget.text,
        context.read<MessagesNotifier>().voicename,
        context.read<MessagesNotifier>().gender,
      );

      if (audioContent.isNotEmpty) {
        final bytes = Base64Decoder().convert(audioContent);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/wavenet_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await file.writeAsBytes(bytes);

        if (file.existsSync()) {
          setState(() => _isPlaying = true);
          await _audioPlayer.play(DeviceFileSource(file.path));
          _audioPlayer.onPlayerComplete.listen((_) {
            setState(() => _isPlaying = false);
          });
        }
      }
    } catch (e) {
      print('Audio error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _playAudio,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.teal[800] 
              : Color(0xff2f8f6a).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Color(0xff2f8f6a),
                      ),
                    ),
                  )
                : Icon(
                    _isPlaying ? LucideIcons.pause : LucideIcons.play,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Color(0xff2f8f6a),
                  ),
            SizedBox(width: 6),
            Text(
              'Listen',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Color(0xff2f8f6a),
              ),
            ),
          ],
        ),
      ),
    );
  }
}