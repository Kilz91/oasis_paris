import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:oasis_paris/services/notification_service.dart';

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
          _buildNotificationsTab(_notificationService.getUnreadNotifications()),
          _buildNotificationsTab(_notificationService.getAllNotifications()),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(Stream<List<CustomNotification>> notificationsStream) {
    return StreamBuilder<List<CustomNotification>>(
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
                    'Erreur: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Aucune notification',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(context, notification);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, CustomNotification notification) {
    final notificationDate = DateFormat('dd/MM HH:mm').format(notification.createdAt);
    
    IconData iconData;
    Color iconColor;
    
    switch (notification.type) {
      case 'rdv_invitation':
        iconData = Icons.calendar_today;
        iconColor = Colors.blue;
        break;
      case 'participant_request':
        iconData = Icons.person_add;
        iconColor = Colors.green;
        break;
      case 'rdv_acceptance':
        iconData = Icons.check_circle;
        iconColor = Colors.teal;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: notification.isRead ? 0 : 2,
      color: notification.isRead ? Colors.white : Colors.blue[50],
      child: InkWell(
        onTap: () => notification.isRead
            ? _showNotificationDetails(context, notification)
            : _markAsReadAndShowDetails(context, notification),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconData, color: iconColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getNotificationTypeTitle(notification.type),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    notificationDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(notification.message),
              SizedBox(height: 8),
              if (_shouldShowActionButtons(notification))
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActionButtons(context, notification),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsReadAndShowDetails(BuildContext context, CustomNotification notification) async {
    await _notificationService.markAsRead(notification.id);
    _showNotificationDetails(context, notification);
  }

  void _showNotificationDetails(BuildContext context, CustomNotification notification) {
    // Pour les invitations aux rendez-vous et les demandes d'ajout de participants, 
    // on affiche déjà les boutons d'action dans la carte.
    // Pour les autres types, on peut ajouter des détails supplémentaires ici.
    if (notification.type != 'rdv_invitation' && notification.type != 'participant_request') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      Text(
                        _getNotificationTypeTitle(notification.type),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(notification.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      Divider(height: 24),
                      Text(notification.message, style: TextStyle(fontSize: 16)),
                      if (notification.type == 'rdv_acceptance' && notification.rdvId != null)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.visibility),
                            label: Text('Voir le rendez-vous'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                            onPressed: () {
                              Navigator.pop(context);
                              // Ici, vous pouvez naviguer vers la page de détails du rendez-vous
                              // Navigator.push(context, MaterialPageRoute(builder: (_) => RendezVousDetailsPage(rdvId: notification.rdvId!)));
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  String _getNotificationTypeTitle(String type) {
    switch (type) {
      case 'rdv_invitation':
        return 'Invitation à un rendez-vous';
      case 'participant_request':
        return 'Demande d\'ajout de participant';
      case 'rdv_acceptance':
        return 'Invitation acceptée';
      default:
        return 'Notification';
    }
  }

  bool _shouldShowActionButtons(CustomNotification notification) {
    // Montrer des boutons d'action seulement pour les invitations et les demandes d'ajout
    // qui ne sont pas encore traitées
    return !notification.isRead &&
           (notification.type == 'rdv_invitation' || notification.type == 'participant_request');
  }

  List<Widget> _buildActionButtons(BuildContext context, CustomNotification notification) {
    if (notification.type == 'rdv_invitation') {
      return [
        OutlinedButton(
          child: Text('Refuser'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          onPressed: () => _handleRdvInvitation(context, notification, false),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          child: Text('Accepter'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () => _handleRdvInvitation(context, notification, true),
        ),
      ];
    } else if (notification.type == 'participant_request') {
      final newParticipantId = notification.data['newParticipantId'];
      final newParticipantName = notification.data['newParticipantName'];
      
      return [
        OutlinedButton(
          child: Text('Refuser'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          onPressed: () => _handleParticipantRequest(
            context, notification, newParticipantId, false),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          child: Text('Approuver'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => _handleParticipantRequest(
            context, notification, newParticipantId, true),
        ),
      ];
    }
    
    return [];
  }

  Future<void> _handleRdvInvitation(
      BuildContext context, CustomNotification notification, bool accepted) async {
    if (notification.rdvId == null) return;
    
    try {
      await _notificationService.respondToRdvInvitation(
        notificationId: notification.id,
        rdvId: notification.rdvId!,
        accepted: accepted,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted
            ? 'Invitation acceptée'
            : 'Invitation refusée'),
          backgroundColor: accepted ? Colors.green : null,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Une erreur est survenue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleParticipantRequest(
      BuildContext context, CustomNotification notification, String newParticipantId, bool approved) async {
    if (notification.rdvId == null) return;
    
    try {
      await _notificationService.respondToParticipantRequest(
        notificationId: notification.id,
        rdvId: notification.rdvId!,
        newParticipantId: newParticipantId,
        approved: approved,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved 
            ? 'Participant ajouté et invité'
            : 'Demande refusée'),
          backgroundColor: approved ? Colors.green : null,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Une erreur est survenue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}