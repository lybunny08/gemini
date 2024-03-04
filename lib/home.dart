// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const apiKey = "AIzaSyCzjSwgYzcjoiVDQO76KbFvKbKJVTtnZjs";
  final model = GenerativeModel(model: 'gemini-1.0-pro', apiKey: apiKey);
  final TextEditingController _userMessage = TextEditingController();
  final List<Message> _messages = [];
  final bool _isMessageEmpty = true;

  Future<void> sendMessage() async {
    final message = _userMessage.text
        .trim(); // Trim pour supprimer les espaces vides au début et à la fin
    if (message.isEmpty) {
      // Si le message est vide, ne rien faire
      return;
    }

    _userMessage.clear();

    setState(() {
      _messages.add(Message(true, message, DateTime.now()));
    });

    final content = [Content.text(message)];
    final response = await model.generateContent(content);

    setState(() {
      _messages.add(Message(false, response.text ?? "", DateTime.now()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Chat Bot'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message.message),
                  subtitle: Text(DateFormat('HH:mm').format(message.date)),
                  trailing: message.isUser
                      ? const Icon(Icons.person)
                      : const Icon(Icons.chat_bubble_outline),
                  tileColor:
                      message.isUser ? Colors.grey[300] : Colors.blue[100],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: TextFormField(
                        controller: _userMessage,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          labelText: 'Enter your message',
                          suffixIcon: IconButton(
                            onPressed: () {
                              // Dissimuler le clavier lors du clic sur le bouton
                              FocusScope.of(context).unfocus();
                            },
                            icon: const Icon(Icons.keyboard_arrow_down),
                          ),
                        ),
                        maxLines:
                            null, // Permet à TextFormField de se mettre à la ligne automatiquement
                        textAlignVertical: TextAlignVertical
                            .top, // Alignement du texte en haut
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Messages extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;
  const Messages(
      {super.key,
      required this.isUser,
      required this.message,
      required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(vertical: 15)
          .copyWith(left: isUser ? 100 : 10, right: isUser ? 10 : 100),
      decoration: BoxDecoration(
          color: isUser
              ? const Color.fromARGB(255, 9, 48, 79)
              : Colors.grey.shade300,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(color: isUser ? Colors.white : Colors.black),
          ),
          Text(
            date,
            style: TextStyle(color: isUser ? Colors.white : Colors.black),
          )
        ],
      ),
    );
  }
}

class Message {
  final bool isUser;
  final String message;
  final DateTime date;

  Message(this.isUser, this.message, this.date);
}
