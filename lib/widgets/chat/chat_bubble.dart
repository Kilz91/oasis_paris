import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String senderName;
  final String? senderPhotoUrl;
  final Timestamp timestamp;
  final bool showSender;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.senderName,
    this.senderPhotoUrl,
    required this.timestamp,
    this.showSender = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateTime = timestamp.toDate();
    final formattedTime = DateFormat.Hm().format(dateTime);
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isMe
            ? _buildMyMessage(context, formattedTime)
            : _buildOtherMessage(context, formattedTime),
      ),
    );
  }

  List<Widget> _buildMyMessage(BuildContext context, String formattedTime) {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildOtherMessage(BuildContext context, String formattedTime) {
    return [
      if (showSender)
        CircleAvatar(
          radius: 16,
          backgroundImage: senderPhotoUrl != null
              ? NetworkImage(senderPhotoUrl!)
              : AssetImage('assets/profil.png') as ImageProvider,
        ),
      if (showSender) SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSender)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }
}