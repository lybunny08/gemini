import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const String apiKey = "AIzaSyBSq6zwXD7nX2xsuZFUOUWzH7Q3ep9ROl8";
  final model = GenerativeModel(model: 'gemini-1.0-pro', apiKey: apiKey);
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  String _text = '';
  bool _isListening = false;
  late Timer _timer = Timer(Duration.zero, () {});
  bool _isSpeaking = false;
// Variable pour suivre l'état de l'animation du modèle 3D

  late ModelViewer modelViewer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration.zero, () {});
    _initSpeech();
    modelViewer = const ModelViewer(
      ar: false,
      src: 'assets/suzanne.glb',
    );
  }

  void _initSpeech() async {
    await speech.initialize(
      onStatus: (status) {
        if (kDebugMode) {
          print('Speech recognition status: $status');
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Speech recognition error: $error');
        }
      },
    );
  }

  void _startModelAnimation() {
    setState(() {
      modelViewer = const ModelViewer(
        autoPlay: true,
        src: 'assets/suzanne.glb',
      );
    });
  }

  void _stopModelAnimation() {
    setState(() {
      modelViewer = const ModelViewer(
        autoPlay: false,
        src: 'assets/suzanne.glb',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/background.jpg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 400,
                  height: 400,
                  child: modelViewer,
                ),
                const SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onLongPress: _startListening,
                  onLongPressEnd: (_) => _stopListening(),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(70),
                    ),
                    child: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.white),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                  ),
                  onPressed: _stopSpeaking,
                  child: const Text(
                    'Stop Speaking',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _text,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _text = 'Listening...';
    });

    bool isAvailable = await speech.listen(
      onResult: (result) async {
        setState(() {
          _text = result.recognizedWords;
        });

        if (kDebugMode) {
          print('Text before cleaning: ${result.recognizedWords}');
        }

        String cleanedText = _cleanText(result.recognizedWords);

        if (kDebugMode) {
          print('Text after cleaning: $cleanedText');
        }

        GenerateContentResponse geminiResponse =
            await getGeminiResponse(cleanedText);

        if (!_isSpeaking) {
          _isSpeaking = true;
          await _speak(geminiResponse.text ?? "");
          _isSpeaking = false;
// Commencer l'animation du modèle lorsque Gemini parle
          _startModelAnimation();
        }

        _timer = Timer(const Duration(seconds: 2), () {
          _stopListening();
        });
      },
    );

    if (!isAvailable) {
      setState(() {
        _isListening = false;
        _text = 'Speech recognition not available';
      });
    }
  }

  String _cleanText(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]+'), '');
  }

  Future<GenerateContentResponse> getGeminiResponse(String question) async {
    try {
      final response = await model.generateContent([Content.text(question)]);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating response from Gemini: $e');
      }
      throw 'An error occurred. Please try again.';
    }
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _stopListening() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    if (speech.isListening) {
      setState(() {
        _isListening = false;
      });
      speech.stop();
    }
  }

  void _stopSpeaking() {
    flutterTts.stop();
    _stopModelAnimation(); // Arrêtez l'animation du modèle lorsque Gemini arrête de parler
// Arrêter l'animation du modèle lorsque Gemini arrête de parler
  }

  @override
  void dispose() {
    super.dispose();
  }
}
