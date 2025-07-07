import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // To access the API key
import 'package:google_generative_ai/google_generative_ai.dart'; // Gemini API package
import 'package:intl/intl.dart'; // For date formatting

// Define a simple message class
class Message {
  final String text;
  final bool isUser; // true if sent by user, false if by AI

  Message({required this.text, required this.isUser});
}

class GeminiChatScreen extends StatefulWidget {
  final String? userName; // Receive username

  const GeminiChatScreen({Key? key, this.userName}) : super(key: key);

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  late final GenerativeModel _model;
  late final ChatSession _chat; // Use ChatSession for conversational memory

  @override
  void initState() {
    super.initState();
    // Initialize the Gemini model
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
    if (geminiApiKey == null || geminiApiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: geminiApiKey);
    _chat = _model.startChat(); // Start a new chat session

    _sendInitialGreeting(); // Send the greeting when the screen initializes
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Method to send the initial greeting
  Future<void> _sendInitialGreeting() async {
    debugPrint('[_sendInitialGreeting] Method entered.'); // Debug 1

    final DateTime now = DateTime.now(); // Gets current time in local timezone
    // Format for Caracas time (UTC-4)
    // Note: DateTime.now() gives local time. To ensure UTC-4, you might adjust based on system timezone or use specific timezone package
    // For simplicity, we'll format local time and mention UTC-4.
    final String formattedDate = DateFormat('EEEE, dd/MM/yyyy', 'es').format(now); // Full weekday, day/month/year
    final String formattedTime = DateFormat('hh:mm a', 'es').format(now); // 12-hour time with AM/PM

    final String userName = widget.userName ?? "usuario"; // Use "usuario" if name is null

    final String greetingPrompt =
        "Hola,eres un chatbot integrado en una app llamada Pathfinder. Es $formattedDate, $formattedTime (UTC-4). "
        "el usuario que te habla se llama $userName,necesita ayuda para usar Pathfinder?";

    debugPrint('[_sendInitialGreeting] Generated prompt: $greetingPrompt'); // Debug 2

    setState(() {
      _isLoading = true; // Show loading indicator while Gemini generates greeting
    });

    try {
      final response = await _chat.sendMessage(Content.text(greetingPrompt));
      final aiResponse = response.text;

      debugPrint('[_sendInitialGreeting] Gemini raw response: ${response.text}'); // Debug 3
      debugPrint('[_sendInitialGreeting] Gemini aiResponse (extracted): $aiResponse'); // Debug 4


      if (aiResponse != null && aiResponse.isNotEmpty) { // Check if response is not null AND not empty
        setState(() {
          _messages.add(Message(text: aiResponse, isUser: false));
          debugPrint('[_sendInitialGreeting] Message added to _messages. Current count: ${_messages.length}'); // Debug 5
        });
      } else {
        // Fallback if Gemini returns null or an empty string for the greeting
        debugPrint('[_sendInitialGreeting] Gemini returned null or empty response for greeting.'); // Debug 6
        setState(() {
          _messages.add(Message(
            text: 'Hola, soy tu asistente. Parece que el asistente no pudo generar un saludo inicial. ¿Cómo puedo ayudarte con Pathfinder?',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      // Catch any API errors during the greeting generation
      debugPrint('[_sendInitialGreeting] Error generating initial greeting from Gemini: $e'); // Debug 7
      setState(() {
        _messages.add(Message(
          text: 'Hola, soy tu asistente. Parece que tengo problemas para conectar con el asistente para el saludo inicial. ¿Cómo puedo ayudarte con Pathfinder?',
          isUser: false,
        ));
      });
    } finally {
      // Always stop loading and scroll to bottom
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
      debugPrint('[_sendInitialGreeting] Method finished.'); // Debug 8
    }
  }

  // Method to send a message to Gemini
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _textController.clear();
      _isLoading = true; // Show loading indicator
    });

    // Scroll to the bottom after adding user message
    _scrollToBottom();

    try {
      // Send message to the chat session
      final response = await _chat.sendMessage(Content.text(text));

      // Extract the response text
      final aiResponse = response.text;
      if (aiResponse != null) {
        setState(() {
          _messages.add(Message(text: aiResponse, isUser: false));
        });
      }
    } catch (e) {
      debugPrint('Error sending message to Gemini: $e');
      setState(() {
        _messages.add(Message(
          text: 'Error: No pude conectar con el asistente. Intenta de nuevo más tarde.',
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      // Scroll to the bottom after AI response
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente AI'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: message.isUser ? colorScheme.primary.withOpacity(0.1) : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                        bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7, // Limit bubble width
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                color: colorScheme.primary,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    ),
                    onSubmitted: (text) => _sendMessage(), // Send on Enter key
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage, // Disable when loading
                  mini: true,
                  backgroundColor: _isLoading ? colorScheme.surfaceVariant : colorScheme.primary,
                  foregroundColor: _isLoading ? colorScheme.onSurfaceVariant : colorScheme.onPrimary,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}