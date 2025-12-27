import 'package:flutter/material.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'type': 'user',
        'text': _messageController.text,
      });
      
      // Placeholder AI response
      _messages.add({
        'type': 'ai',
        'text': 'This is a placeholder for the AI assistant. Integration with AI services will be added soon!',
      });
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() => _messages.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickActionChip(
                    icon: Icons.wb_twilight,
                    label: 'Tonight\'s Sky',
                    onTap: () {
                      setState(() {
                        _messages.add({
                          'type': 'user',
                          'text': 'What can I observe tonight?',
                        });
                        _messages.add({
                          'type': 'ai',
                          'text': 'AI integration coming soon! This will show objects visible tonight based on your location.',
                        });
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickActionChip(
                    icon: Icons.camera_alt,
                    label: 'Identify Object',
                    onTap: () {
                      setState(() {
                        _messages.add({
                          'type': 'user',
                          'text': 'Help me identify a celestial object',
                        });
                        _messages.add({
                          'type': 'ai',
                          'text': 'Upload an image and I\'ll help identify it! (Feature coming soon)',
                        });
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickActionChip(
                    icon: Icons.book,
                    label: 'Recommend Books',
                    onTap: () {
                      setState(() {
                        _messages.add({
                          'type': 'user',
                          'text': 'Recommend astronomy books',
                        });
                        _messages.add({
                          'type': 'ai',
                          'text': 'AI book recommendations coming soon!',
                        });
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickActionChip(
                    icon: Icons.quiz,
                    label: 'Ask Question',
                    onTap: () {
                      setState(() {
                        _messages.add({
                          'type': 'user',
                          'text': 'I have a question about astronomy',
                        });
                        _messages.add({
                          'type': 'ai',
                          'text': 'Go ahead! Ask me anything about astronomy.',
                        });
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 80,
                          color: Colors.purpleAccent.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AI Assistant',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ask me anything about astronomy!',
                          style: TextStyle(color: Colors.white38),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Try the quick actions above\nor type a message below',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['type'] == 'user';
                      
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.purpleAccent
                                : const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message['text']!,
                            style: TextStyle(
                              color: isUser ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF0F0E17),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.purpleAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.purpleAccent),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
