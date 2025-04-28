import 'package:flutter/material.dart';
import '../../services/friend_service.dart';
import '../../core/utils/safe_context.dart';

class SentRequestsList extends StatefulWidget {
  final List<Map<String, dynamic>> sentRequests;
  final Function refreshCallback;

  const SentRequestsList({
    Key? key, 
    required this.sentRequests, 
    required this.refreshCallback,
  }) : super(key: key);

  @override
  State<SentRequestsList> createState() => _SentRequestsListState();
}

class _SentRequestsListState extends State<SentRequestsList> {
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
    
    return Container(
      height: widget.sentRequests.length * 80.0, // Hauteur approximative
      constraints: BoxConstraints(maxHeight: 240), // Hauteur maximale
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: widget.sentRequests.length,
        itemBuilder: (context, index) {
          final request = widget.sentRequests[index];
          return Card(
            elevation: 1,
            color: Colors.grey[100],
            margin: EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: CircleAvatar(
                backgroundImage: request['photoURL'] != null
                    ? NetworkImage(request['photoURL'])
                    : AssetImage('assets/profil.png') as ImageProvider,
              ),
              title: Text(
                '${request['prenom']} ${request['nom']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'En attente',
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () => _cancelFriendRequest(request),
                tooltip: 'Annuler',
              ),
            ),
          );
        },
      ),
    );
  }

  void _cancelFriendRequest(Map<String, dynamic> request) async {
    final friendService = FriendService();
    final success = await friendService.cancelFriendRequest(request['requestId']);
    
    if (success) {
      // Utiliser le contexte sécurisé pour afficher le SnackBar
      _safeContext.showSnackBar(
        SnackBar(
          content: Text('Demande d\'ami annulée'),
          backgroundColor: Colors.orange,
        ),
      );
      widget.refreshCallback();
    }
  }
}