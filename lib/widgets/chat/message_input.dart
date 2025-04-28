import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final String hintText;

  const MessageInput({
    Key? key,
    required this.onSendMessage,
    this.hintText = 'Écrire un message...',
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _messageController = TextEditingController();
  bool _isComposing = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    widget.onSendMessage(text.trim());
    _messageController.clear();
    
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 6,
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (text) {
                setState(() {
                  _isComposing = text.trim().isNotEmpty;
                });
              },
              onSubmitted: _isComposing ? _handleSubmitted : null,
              decoration: InputDecoration(
                hintText: widget.hintText,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: () {
                    // Implémentation future pour les pièces jointes
                  },
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isComposing
                ? () => _handleSubmitted(_messageController.text)
                : null,
            child: Icon(Icons.send),
            backgroundColor: _isComposing ? Colors.teal : Colors.grey[400],
            elevation: _isComposing ? 2 : 0,
            mini: true,
          ),
        ],
      ),
    );
  }
}