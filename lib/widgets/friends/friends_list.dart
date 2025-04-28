import 'package:flutter/material.dart';
import '../../services/friend_service.dart';
import '../../core/utils/safe_context.dart';

class FriendsList extends StatefulWidget {
  final List<Map<String, dynamic>> friends;
  final Function refreshCallback;

  const FriendsList({
    Key? key, 
    required this.friends,
    required this.refreshCallback,
  }) : super(key: key);

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  final SafeContext _safeContext = SafeContext();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _safeContext.capture(context);
  }

  @override
  void dispose() {
    _safeContext.release();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Mettre à jour le contexte sécurisé
    _safeContext.capture(context);
    
    if (widget.friends.isEmpty) {
      return Center(
        child: Text(
          'Vous n\'avez pas encore d\'amis confirmés',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.friends.length,
      itemBuilder: (context, index) {
        final friend = widget.friends[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: friend['photoURL'] != null
                  ? NetworkImage(friend['photoURL'])
                  : AssetImage('assets/profil.png') as ImageProvider,
            ),
            title: Text(
              '${friend['prenom']} ${friend['nom']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              friend['email'],
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmRemoveFriend(friend),
            ),
          ),
        );
      },
    );
  }

  void _confirmRemoveFriend(Map<String, dynamic> friend) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Supprimer cet ami ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${friend['prenom']} ${friend['nom']} de votre liste d\'amis ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              // Utiliser le contexte du dialogue pour fermer l'alerte
              Navigator.of(dialogContext).pop();
              
              final friendService = FriendService();
              final success = await friendService.removeFriend(friend['id']);
              
              if (success) {
                // Utiliser le contexte sécurisé pour le SnackBar
                _safeContext.showSnackBar(
                  SnackBar(
                    content: Text('Ami supprimé avec succès'),
                    backgroundColor: Colors.orange,
                  ),
                );
                widget.refreshCallback();
              }
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}