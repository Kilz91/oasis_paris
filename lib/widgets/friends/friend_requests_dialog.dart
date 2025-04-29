import 'package:flutter/material.dart';
import '../../services/friend_service.dart';
import '../../core/utils/safe_context.dart';

class FriendRequestsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> friendRequests;
  final Function refreshCallback;

  const FriendRequestsDialog({
    Key? key,
    required this.friendRequests,
    required this.refreshCallback,
  }) : super(key: key);

  @override
  State<FriendRequestsDialog> createState() => _FriendRequestsDialogState();
}

class _FriendRequestsDialogState extends State<FriendRequestsDialog> {
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
    // Assurez-vous que le SafeContext a toujours le contexte le plus récent
    _safeContext.capture(context);
    
    return AlertDialog(
      title: Text('Demandes d\'amis'),
      content: Container(
        width: double.maxFinite,
        child: widget.friendRequests.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_search,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Vous n\'avez aucune demande d\'ami',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.friendRequests.length,
                itemBuilder: (context, index) {
                  final request = widget.friendRequests[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: request['sender'].photoURL != null
                            ? NetworkImage(request['sender'].photoURL)
                            : AssetImage('assets/profil.png') as ImageProvider,
                      ),
                      title: Text(
                        '${request['sender'].firstName} ${request['sender'].lastName}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(request['sender'].email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.green),
                            onPressed: () => _acceptFriendRequest(request),
                            tooltip: 'Accepter',
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rejectFriendRequest(request),
                            tooltip: 'Refuser',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Fermer'),
        ),
      ],
    );
  }

  void _acceptFriendRequest(Map<String, dynamic> request) async {
    // Fermer le dialogue avant d'effectuer les opérations asynchrones
    Navigator.of(context).pop();
    
    final friendService = FriendService();
    // Accéder correctement à l'ID de la demande et à l'ID de l'ami
    final requestId = request['request'].id;
    final friendId = request['sender'].uid;
    
    final success = await friendService.acceptFriendRequest(requestId, friendId);
    
    if (success) {
      // Utiliser le contexte sécurisé
      _safeContext.showSnackBar(
        SnackBar(
          content: Text('Demande d\'ami acceptée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      widget.refreshCallback();
    }
  }

  void _rejectFriendRequest(Map<String, dynamic> request) async {
    // Fermer le dialogue avant d'effectuer les opérations asynchrones
    Navigator.of(context).pop();
    
    final friendService = FriendService();
    // Accéder correctement à l'ID de la demande
    final requestId = request['request'].id;
    
    final success = await friendService.rejectFriendRequest(requestId);
    
    if (success) {
      // Utiliser le contexte sécurisé
      _safeContext.showSnackBar(
        SnackBar(
          content: Text('Demande d\'ami refusée'),
          backgroundColor: Colors.orange,
        ),
      );
      widget.refreshCallback();
    }
  }
}