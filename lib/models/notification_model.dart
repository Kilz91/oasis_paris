import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  friendRequest,
  friendAccepted,
  rendezvousInvitation,
  rendezvousAccepted,
  participantRequest,
  rendezvousReminder,
  rendezvousUpdate,
  message,
  system
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime? createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;
  
  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.createdAt,
    required this.isRead,
    this.data,
  });
  
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: _stringToNotificationType(map['type'] ?? 'system'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      isRead: map['isRead'] ?? false,
      data: map['data'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': _notificationTypeToString(type),
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
      'isRead': isRead,
      'data': data,
    };
  }
  
  static NotificationType _stringToNotificationType(String value) {
    switch (value) {
      case 'friendRequest':
        return NotificationType.friendRequest;
      case 'friendAccepted':
        return NotificationType.friendAccepted;
      case 'rendezvousInvitation':
        return NotificationType.rendezvousInvitation;
      case 'rendezvousAccepted':
        return NotificationType.rendezvousAccepted;
      case 'participantRequest':
        return NotificationType.participantRequest;
      case 'rendezvousReminder':
        return NotificationType.rendezvousReminder;
      case 'rendezvousUpdate':
        return NotificationType.rendezvousUpdate;
      case 'message':
        return NotificationType.message;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
  
  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return 'friendRequest';
      case NotificationType.friendAccepted:
        return 'friendAccepted';
      case NotificationType.rendezvousInvitation:
        return 'rendezvousInvitation';
      case NotificationType.rendezvousAccepted:
        return 'rendezvousAccepted';
      case NotificationType.participantRequest:
        return 'participantRequest';
      case NotificationType.rendezvousReminder:
        return 'rendezvousReminder';
      case NotificationType.rendezvousUpdate:
        return 'rendezvousUpdate';
      case NotificationType.message:
        return 'message';
      case NotificationType.system:
        return 'system';
    }
  }
}