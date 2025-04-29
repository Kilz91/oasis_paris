import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:oasis_paris/services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../services/rdv_service.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: Text('Vous devez être connecté pour voir vos notifications'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            tooltip: 'Tout marquer comme lu',
            onPressed: () async {
              await _notificationService.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Toutes les notifications ont été marquées comme lues'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Non lues'),
            Tab(text: 'Toutes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(_notificationService.getUserNotifications().map((list) => 
            list.where((notif) => !notif.isRead).toList())),
          _buildNotificationsTab(_notificationService.getUserNotifications()),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(Stream<List<NotificationModel>> notificationsStream) {
    return StreamBuilder<List<NotificationModel>>(
      stream: notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Une erreur est survenue lors du chargement des notifications',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        final notifications = snapshot.data ?? [];
        
        if (notifications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off, color: Colors.grey, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Aucune notification pour le moment',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          padding: EdgeInsets.all(8),
          itemBuilder: (context, index) => _buildNotificationCard(
            context,
            notifications[index],
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification) {
    final notificationDate = notification.createdAt != null 
        ? DateFormat('dd/MM HH:mm').format(notification.createdAt!) 
        : '';
    
    IconData iconData;
    Color iconColor;
    
    switch (notification.type) {
      case NotificationType.friendRequest:
        iconData = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case NotificationType.friendAccepted:
        iconData = Icons.people;
        iconColor = Colors.green;
        break;
      case NotificationType.rendezvousInvitation:
        iconData = Icons.event_available;
        iconColor = Colors.orange;
        break;
      case NotificationType.rendezvousAccepted:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.participantRequest:
        iconData = Icons.person_add;
        iconColor = Colors.purple;
        break;
      case NotificationType.rendezvousReminder:
        iconData = Icons.alarm;
        iconColor = Colors.amber;
        break;
      case NotificationType.rendezvousUpdate:
        iconData = Icons.event_note;
        iconColor = Colors.teal;
        break;
      case NotificationType.message:
        iconData = Icons.message;
        iconColor = Colors.pink;
        break;
      case NotificationType.system:
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
        break;
    }

    return Card(
      elevation: notification.isRead ? 1 : 3,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: notification.isRead ? Colors.grey.shade50 : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(notification.message),
            SizedBox(height: 2),
            Text(
              notificationDate,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (_shouldShowActionButtons(notification)) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(context, notification),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        onTap: () => _markAsReadAndShowDetails(context, notification),
      ),
    );
  }

  Future<void> _markAsReadAndShowDetails(BuildContext context, NotificationModel notification) async {
    await _notificationService.markAsRead(notification.id);
    _showNotificationDetails(context, notification);
  }

  void _showNotificationDetails(BuildContext context, NotificationModel notification) {
    // Pour les invitations aux rendez-vous et les demandes d'ajout de participants, 
    // on affiche déjà les boutons d'action dans la carte.
    // Pour les autres types, on peut ajouter des détails supplémentaires ici.
    if (notification.type != NotificationType.rendezvousInvitation && 
        notification.type != NotificationType.participantRequest) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_getNotificationTypeTitle(notification.type)),
          content: Text(notification.message),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  String _getNotificationTypeTitle(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return 'Demande d\'ami';
      case NotificationType.friendAccepted:
        return 'Ami accepté';
      case NotificationType.rendezvousInvitation:
        return 'Invitation à un rendez-vous';
      case NotificationType.rendezvousAccepted:
        return 'Rendez-vous accepté';
      case NotificationType.participantRequest:
        return 'Proposition de participant';
      case NotificationType.rendezvousReminder:
        return 'Rappel de rendez-vous';
      case NotificationType.rendezvousUpdate:
        return 'Mise à jour d\'un rendez-vous';
      case NotificationType.message:
        return 'Message';
      case NotificationType.system:
      default:
        return 'Notification';
    }
  }

  bool _shouldShowActionButtons(NotificationModel notification) {
    // Montrer des boutons d'action seulement pour les invitations et les demandes d'ajout
    // qui ne sont pas encore traitées
    return !notification.isRead && 
           (notification.type == NotificationType.rendezvousInvitation || 
            notification.type == NotificationType.participantRequest);
  }

  List<Widget> _buildActionButtons(BuildContext context, NotificationModel notification) {
    if (notification.type == NotificationType.rendezvousInvitation) {
      final rdvId = notification.data?['rendezvousId'] as String?;
      if (rdvId != null) {
        return [
          TextButton(
            child: Text('Refuser'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _handleRdvInvitation(context, notification, rdvId, false),
          ),
          TextButton(
            child: Text('Accepter'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            onPressed: () => _handleRdvInvitation(context, notification, rdvId, true),
          ),
        ];
      }
    } else if (notification.type == NotificationType.participantRequest) {
      final rdvId = notification.data?['rendezvousId'] as String?;
      final participantId = notification.data?['newParticipantId'] as String?;
      
      if (rdvId != null && participantId != null) {
        return [
          TextButton(
            child: Text('Refuser'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _handleParticipantRequest(
              context, notification, rdvId, participantId, false),
          ),
          TextButton(
            child: Text('Accepter'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            onPressed: () => _handleParticipantRequest(
              context, notification, rdvId, participantId, true),
          ),
        ];
      }
    }
    
    return [];
  }

  Future<void> _handleRdvInvitation(
    BuildContext context, NotificationModel notification, String rdvId, bool accept) async {
    try {
      final rdvService = RdvService();
      await rdvService.respondToInvitation(rdvId, accept);
      
      // Marquer la notification comme lue
      await _notificationService.markAsRead(notification.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept 
            ? 'Vous avez accepté l\'invitation'
            : 'Vous avez refusé l\'invitation'),
          backgroundColor: accept ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleParticipantRequest(
    BuildContext context, NotificationModel notification, 
    String rdvId, String participantId, bool accept) async {
    try {
      if (accept) {
        // Récupérer les informations nécessaires pour créer l'invitation
        final rdvService = RdvService();
        final rdvDetails = await rdvService.getRendezVousDetails(rdvId);
        
        if (rdvDetails == null) {
          throw Exception("Le rendez-vous n'existe plus");
        }
        
        // Utiliser la nouvelle méthode pour accepter la proposition de participant
        final participantName = notification.data?['newParticipantName'] as String? ?? 'Ami';
        final success = await _notificationService.acceptParticipantRequest(
          notificationId: notification.id,
          rdvId: rdvId,
          newParticipantId: participantId,
          newParticipantName: participantName,
          rdvName: rdvDetails.ilotNom ?? 'Rendez-vous',
          rdvDate: rdvDetails.date,
        );
        
        if (!success) {
          throw Exception("Erreur lors de l'ajout du participant");
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation envoyée à $participantName'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Refuser la proposition
        await _notificationService.rejectParticipantRequest(
          notificationId: notification.id,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proposition refusée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Marquer la notification comme lue même en cas d'erreur
      // pour éviter que l'utilisateur ne puisse pas la traiter à nouveau
      await _notificationService.markAsRead(notification.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}