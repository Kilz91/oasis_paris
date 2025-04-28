import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final DateTime? timestamp;
  final bool read;
  final String? imageUrl;
  
  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.timestamp,
    required this.read,
    this.imageUrl,
  });
  
  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['sender_id'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      read: map['read'] ?? false,
      imageUrl: map['image_url'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'content': content,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'read': read,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}