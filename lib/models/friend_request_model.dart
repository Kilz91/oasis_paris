import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  rejected
}

class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime? timestamp;
  
  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.timestamp,
  });
  
  factory FriendRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return FriendRequestModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: _stringToStatus(map['status'] ?? 'pending'),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': _statusToString(status),
      'timestamp': timestamp != null 
          ? Timestamp.fromDate(timestamp!) 
          : FieldValue.serverTimestamp(),
    };
  }
  
  static FriendRequestStatus _stringToStatus(String status) {
    switch (status) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'rejected':
        return FriendRequestStatus.rejected;
      case 'pending':
      default:
        return FriendRequestStatus.pending;
    }
  }
  
  static String _statusToString(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.accepted:
        return 'accepted';
      case FriendRequestStatus.rejected:
        return 'rejected';
      case FriendRequestStatus.pending:
        return 'pending';
    }
  }
  
  // Copie avec modifications
  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? timestamp,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}