// ignore_for_file: library_private_types_in_public_api

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
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const String apiKey = "AIzaSyBSq6zwXD7nX2xsuZFUOUWzH7Q3ep9ROl8";
  final model = GenerativeModel(model: 'gemini-1.0-pro', apiKey: apiKey);
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  String _text = '';
  bool _isListening = false;
  late Timer _timer;
  bool _isSpeaking = false;

  // Contrôleur pour l'animation du modèle 3D
  late ModelViewer modelViewer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    modelViewer = const ModelViewer(
      autoPlay: false,
      src: 'assets/angelica.glb',
    );
  }

  void _initSpeech() async {
    // Demande d'autorisation d'accès au microphone
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

    //bool isAvailable = await speech.requestPermission();

    // if (!isAvailable) {
    //   if (kDebugMode) {
    //     print('Speech recognition not available');
    //   }
    // }
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
                    backgroundColor:
                        MaterialStateProperty.all(Colors.white), // Fond blanc
                    foregroundColor:
                        MaterialStateProperty.all(Colors.black), // Texte noir
                  ),
                  onPressed: _stopSpeaking,
                  child: const Text(
                    'Stop Speaking',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ), // Couleur du texte noire
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

        // Log pour afficher le texte reconnu avant nettoyage
        if (kDebugMode) {
          print('Text before cleaning: ${result.recognizedWords}');
        }

        // Supprimer les caractères spéciaux des réponses vocales
        String cleanedText = _cleanText(result.recognizedWords);

        // Log pour afficher le texte après nettoyage
        if (kDebugMode) {
          print('Text after cleaning: $cleanedText');
        }

        // Envoyer la question à l'API de Gemini et obtenir la réponse
        GenerateContentResponse geminiResponse =
            await getGeminiResponse(cleanedText);

        // Reproduire la réponse vocalement seulement si elle n'est pas en cours de lecture
        if (!_isSpeaking) {
          _isSpeaking = true;
          await _speak(geminiResponse.text ?? "");
          _isSpeaking = false;
        }

        // Arrêter d'écouter après quelques secondes
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

  // String _cleanText(String text) {
  //   // Utiliser une expression régulière pour supprimer les caractères spéciaux
  //   return text.replaceAll(RegExp(r'[^\w\s]+'), '');
  // }
  String _cleanText(String text) {
    // Convertir le texte en minuscules et supprimer les caractères non alphanumériques
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]+'), '');
  }

  Future<GenerateContentResponse> getGeminiResponse(String question) async {
    // Generate content using the model
    try {
      final response = await model.generateContent([Content.text(question)]);
      return response;
    } catch (e) {
      // Handle error
      if (kDebugMode) {
        print('Error generating response from Gemini: $e');
      }
      throw 'An error occurred. Please try again.';
    }
  }

  Future<void> _speak(String text) async {
    // Utilisez FlutterTts pour reproduire le texte vocalement
    await flutterTts.speak(text);
  }

  void _stopListening() {
    if (speech.isListening) {
      setState(() {
        _isListening = false;
      });
      speech.stop();
      _timer.cancel(); // Annuler le timer si l'arrêt est manuel
    }
  }

  void _stopSpeaking() {
    flutterTts.stop();
  }
}
