import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/friend_service.dart';
import '../../core/utils/ui_helpers.dart';

class FriendsList extends StatelessWidget {
  final List<UserModel> friends;
  final VoidCallback refreshCallback;
  final FriendService _friendService = FriendService();

  FriendsList({
    required this.friends,
    required this.refreshCallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.teal.shade100,
              backgroundImage: friend.photoURL != null 
                ? NetworkImage(friend.photoURL!) 
                : null,
              child: friend.photoURL == null
                ? Text(
                    '${friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : "?"}',
                    style: TextStyle(fontSize: 22, color: Colors.teal),
                  )
                : null,
            ),
            title: Text(
              friend.displayName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(friend.email),
            trailing: IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () {
                _showFriendOptions(context, friend);
              },
            ),
            onTap: () {
              // Naviguer vers le profil de l'ami ou démarrer une conversation
            },
          ),
        );
      },
    );
  }

  void _showFriendOptions(BuildContext context, UserModel friend) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Options',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.chat_bubble_outline),
              title: Text('Envoyer un message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers la page de chat
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Proposer un rendez-vous'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers la création de rendez-vous
              },
            ),
            ListTile(
              leading: Icon(Icons.person_remove_outlined, color: Colors.red),
              title: Text(
                'Supprimer de mes amis', 
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveFriend(context, friend);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveFriend(BuildContext context, UserModel friend) {
    UIHelpers.showConfirmationDialog(
      context: context, 
      title: 'Supprimer cet ami ?',
      message: 'Voulez-vous vraiment supprimer ${friend.displayName} de vos amis ?',
      confirmText: 'Supprimer',
      cancelText: 'Annuler',
    ).then((confirmed) {
      if (confirmed == true) {
        _removeFriend(context, friend);
      }
    });
  }

  Future<void> _removeFriend(BuildContext context, UserModel friend) async {
    try {
      bool success = await _friendService.removeFriend(friend.uid);
      
      if (success) {
        UIHelpers.showSnackBar(
          context: context,
          message: '${friend.displayName} a été retiré de vos amis',
          isSuccess: true,
        );
        refreshCallback();
      } else {
        UIHelpers.showSnackBar(
          context: context,
          message: 'Erreur lors de la suppression de cet ami',
          isError: true,
        );
      }
    } catch (e) {
      UIHelpers.showSnackBar(
        context: context,
        message: 'Erreur: ${e.toString()}',
        isError: true,
      );
    }
  }
}