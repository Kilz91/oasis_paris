import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, dynamic> participantsInfo;
  final Map<String, dynamic> readStatus;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantsInfo,
    required this.readStatus,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.createdAt,
    this.updatedAt,
  });
  
  factory ConversationModel.fromMap(Map<String, dynamic> map, String id) {
    return ConversationModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantsInfo: Map<String, dynamic>.from(map['participants_info'] ?? {}),
      readStatus: Map<String, dynamic>.from(map['read_status'] ?? {}),
      lastMessage: map['last_message'],
      lastMessageTimestamp: (map['last_message_timestamp'] as Timestamp?)?.toDate(),
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participants_info': participantsInfo,
      'read_status': readStatus,
      'last_message': lastMessage,
      'last_message_timestamp': lastMessageTimestamp != null 
          ? Timestamp.fromDate(lastMessageTimestamp!) 
          : null,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
  
  // Obtenir les informations de l'autre participant (pour les chats à deux personnes)
  Map<String, dynamic>? getOtherParticipantInfo(String currentUserId) {
    final otherParticipantId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    
    if (otherParticipantId.isEmpty) return null;
    
    return participantsInfo[otherParticipantId];
  }
  
  // Vérifier si un message n'a pas été lu par un utilisateur spécifique
  bool isUnreadBy(String userId) {
    return readStatus[userId] == false;
  }
}