import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationItem extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> notification;
  final Function(String) onNotificationTap;
  final Function(String) onNotificationDismiss;

  const NotificationItem({
    Key? key,
    required this.notificationId,
    required this.notification,
    required this.onNotificationTap,
    required this.onNotificationDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String type = notification['type'] ?? 'info';
    final String message = notification['message'] ?? 'Nouvelle notification';
    final bool isRead = notification['isRead'] ?? false;
    final Timestamp createdAt = notification['createdAt'] ?? Timestamp.now();
    
    // Formate la date de la notification
    final DateTime dateTime = createdAt.toDate();
    final String formattedDate = _formatDateTime(dateTime);
    
    return Dismissible(
      key: Key(notificationId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onNotificationDismiss(notificationId),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: isRead ? null : Colors.blue[50],
        elevation: isRead ? 1 : 2,
        child: ListTile(
          leading: _getNotificationIcon(type),
          title: Text(
            message,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(formattedDate),
          trailing: !isRead 
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
          onTap: () => onNotificationTap(notificationId),
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      // Aujourd'hui, afficher l'heure
      return 'Aujourd\'hui à ${DateFormat.Hm().format(dateTime)}';
    } else if (difference.inDays == 1) {
      // Hier
      return 'Hier à ${DateFormat.Hm().format(dateTime)}';
    } else if (difference.inDays < 7) {
      // Cette semaine
      return DateFormat('EEEE', 'fr_FR').format(dateTime) + ' à ${DateFormat.Hm().format(dateTime)}';
    } else {
      // Plus ancien
      return DateFormat('dd/MM/yyyy à HH:mm').format(dateTime);
    }
  }
  
  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'friend_request':
        return CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.person_add, color: Colors.white, size: 20),
        );
      case 'friend_accepted':
        return CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.people, color: Colors.white, size: 20),
        );
      case 'rdv_invitation':
        return CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.calendar_today, color: Colors.white, size: 20),
        );
      case 'rdv_accepted':
        return CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(Icons.event_available, color: Colors.white, size: 20),
        );
      case 'participant_request':
        return CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.person_add_alt, color: Colors.white, size: 20),
        );
      default:
        return CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.notifications, color: Colors.white, size: 20),
        );
    }
  }
}