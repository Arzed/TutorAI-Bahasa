import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:chatbot_tutor/provider/messagesprovider.dart';
import 'package:chatbot_tutor/texttospeech/TextToSpeechAPI.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:animated_button/animated_button.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  String? _path;
  AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  Future<void> synthesizeText(String text) async {
    final String audioContent = await TextToSpeechAPI().synthesizeText(
      text,
      context.read<MessagesNotifier>().voicename,
      context.read<MessagesNotifier>().gender,
    );
    if (audioContent.isEmpty) return;

    final bytes = Base64Decoder().convert(audioContent);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/wavenet_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await file.writeAsBytes(bytes);
    if (file.existsSync()) {
      setState(() {
        _path = file.path;
        _audioPlayer.play(DeviceFileSource(_path!));
      });
    } else {
      print("File not found: ${file.path}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final CarouselController _controller = CarouselController();
    int _current = 0;

    final List<Widget> imageSliders = [
      Image.asset('assets/images/ed696be3-b0aa-46c8-a566-7004455369fd_removalai_preview.png', height: 500),
      Image.asset('assets/images/99694bdb-f493-4935-b34a-266751503d5c_removalai_preview.png', height: 500),
    ];

    // Daftar menu
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Open Mode',
        'icon': LucideIcons.messageSquare,
        'route': '/firstmode',
        'color': Color(0xFFFF9E7D), // Peach
        'description': 'Chat bebas dengan tutor AI'
      },
      {
        'title': 'Verb Mode',
        'icon': LucideIcons.activity,
        'route': '/secondmode',
        'color': Color(0xFF4ECDC4), // Mint Teal
        'description': 'Pelajari kata kerja bahasa Indonesia'
      },
      {
        'title': 'Vocab Mode',
        'icon': LucideIcons.bookOpen,
        'route': '/thirdmode',
        'color': Color(0xFFFFD166), // Sunshine Yellow
        'description': 'Perbanyak kosakata bahasa Indonesia'
      },
      {
        'title': 'Dialogue Mode',
        'icon': LucideIcons.users,
        'route': '/fourthmode',
        'color': Color(0xFFA8E6CF), // Soft Mint
        'description': 'Latihan percakapan sehari-hari'
      },
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFD3B6), // Light Peach
              Color(0xFFA8E6CF), // Soft Mint
              Color(0xFFDCE2C8), // Light Green
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar dengan logo dan ikon
              Container(
                height: kToolbarHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Icon(LucideIcons.menu, size: 30),
                          ),
                          Spacer(),
                          Image.asset(
                            'assets/images/logo.png',
                            height: 40,
                          ),
                          Spacer(),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Icon(LucideIcons.settings, size: 30),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Avatar Carousel
              Expanded(
                flex: 2,
                child: CarouselSlider(
                  items: imageSliders,
                  options: CarouselOptions(
                    autoPlay: false,
                    enlargeCenterPage: true,
                    aspectRatio: 1.5,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _current = index;
                        context.read<MessagesNotifier>().selectvoice(
                              _current == 0
                                  ? "ms-MY-Wavenet-D"
                                  : "ms-MY-Wavenet-C",
                              _current == 0 ? "MALE" : "FEMALE",
                              _current == 0 ? "Kiki" : "Ayu",
                            );
                      });
                      synthesizeText(
                          "Assalamualaikum, Hi! Saya ${context.read<MessagesNotifier>().avatar}! Salam Kenal!");
                    },
                  ),
                ),
              ),

              // Tombol Animated
              AnimatedButton(
                width: 300,
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: AnimatedTextKit(
                      repeatForever: true,
                      animatedTexts: [
                        TypewriterAnimatedText(
                          "Perkenalkan nama Saya ${context.watch<MessagesNotifier>().avatar}!",
                          textAlign: TextAlign.center,
                          textStyle: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TypewriterAnimatedText(
                          "Lets learn to speak Indonesia!",
                          textAlign: TextAlign.center,
                          textStyle: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                onPressed: () {},
                shadowDegree: ShadowDegree.light,
                color: Color(0xFFFF9E7D),
              ),

              // Grid Menu
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: menuItems.map((menu) {
                      return _buildMenuCard(
                        context,
                        icon: menu['icon'],
                        title: menu['title'],
                        color: menu['color'],
                        description: menu['description'],
                        onTap: () => Navigator.pushNamed(context, menu['route']),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required String description,
    required Function() onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: color.withOpacity(0.8),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.white),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    super.dispose();
  }
}