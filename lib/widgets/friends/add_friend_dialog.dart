import 'package:flutter/material.dart';
import '../../services/friend_service.dart';

class AddFriendDialog extends StatefulWidget {
  final Function refreshCallback;
  final List<Map<String, dynamic>> friends;

  const AddFriendDialog({
    Key? key,
    required this.refreshCallback,
    required this.friends,
  }) : super(key: key);

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _errorMessage = '';
  bool _isSearchingByEmail = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajouter un ami'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Rechercher par:'),
              ),
              Row(
                children: [
                  Text('Email'),
                  Switch(
                    value: !_isSearchingByEmail,
                    onChanged: (value) {
                      setState(() {
                        _isSearchingByEmail = !value;
                      });
                    },
                  ),
                  Text('Téléphone'),
                ],
              ),
            ],
          ),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: _isSearchingByEmail
                  ? 'Entrez l\'email de votre ami'
                  : 'Entrez le numéro de téléphone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _searchAndAddFriend,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
          ),
          child: Text('Rechercher'),
        ),
      ],
    );
  }

  void _searchAndAddFriend() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un email ou un numéro de téléphone';
      });
      return;
    }

    final friendService = FriendService();
    final result = await friendService.searchUser(
      searchTerm: searchTerm,
      isSearchingByEmail: _isSearchingByEmail,
      currentFriends: widget.friends,
    );

    if (!result['success']) {
      setState(() {
        _errorMessage = result['message'];
      });
      return;
    }

    // Utilisateur trouvé, envoyer la demande d'ami
    final foundUser = result['userData'];
    final receiverId = foundUser['id'];

    final success = await friendService.sendFriendRequest(receiverId);
    
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande d\'ami envoyée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      widget.refreshCallback();
    } else {
      setState(() {
        _errorMessage = 'Une erreur s\'est produite lors de l\'envoi de la demande';
      });
    }
  }
}