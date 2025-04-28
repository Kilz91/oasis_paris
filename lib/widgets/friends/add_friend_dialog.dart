import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/friend_service.dart';
import '../../core/utils/ui_helpers.dart';

class AddFriendDialog extends StatefulWidget {
  final VoidCallback refreshCallback;
  final List<UserModel> friends;

  AddFriendDialog({
    required this.refreshCallback,
    required this.friends,
  });

  @override
  _AddFriendDialogState createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showSearchResults = false;
  Map<String, dynamic> _searchResult = {};
  bool _isSearchingByEmail = true;
  final FriendService _friendService = FriendService();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ajouter un ami',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _isSearchingByEmail
                          ? 'Rechercher par email'
                          : 'Rechercher par téléphone',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: _isSearchingByEmail
                        ? TextInputType.emailAddress
                        : TextInputType.phone,
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<bool>(
                  value: _isSearchingByEmail,
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Email'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Téléphone'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _isSearchingByEmail = value;
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSearching ? null : _searchUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSearching
                  ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : Text('Rechercher'),
            ),
            if (_showSearchResults) ...[
              SizedBox(height: 16),
              Divider(),
              if (_searchResult['success'] == true) ...[
                _buildUserCard(),
              ] else ...[
                Text(
                  _searchResult['message'] ?? 'Une erreur s\'est produite',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    final userData = _searchResult['userData'] as UserModel;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.teal.shade100,
                backgroundImage: userData.photoURL != null 
                  ? NetworkImage(userData.photoURL!) 
                  : null,
                child: userData.photoURL == null
                  ? Text(
                      '${userData.displayName.isNotEmpty ? userData.displayName[0].toUpperCase() : "?"}',
                      style: TextStyle(fontSize: 24, color: Colors.teal),
                    )
                  : null,
              ),
              title: Text(
                userData.displayName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(userData.email),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSearching ? null : () => _sendFriendRequest(userData.uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSearching
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text('Envoyer une demande d\'ami'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchUser() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) {
      UIHelpers.showSnackBar(
        context: context,
        message: 'Veuillez entrer un email ou un numéro de téléphone',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = false;
    });

    try {
      final result = await _friendService.searchUser(
        searchTerm: searchTerm,
        isSearchingByEmail: _isSearchingByEmail,
        currentFriends: widget.friends,
      );

      setState(() {
        _isSearching = false;
        _showSearchResults = true;
        _searchResult = result;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _showSearchResults = true;
        _searchResult = {
          'success': false,
          'message': 'Une erreur s\'est produite: ${e.toString()}',
        };
      });
    }
  }

  Future<void> _sendFriendRequest(String receiverId) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final success = await _friendService.sendFriendRequest(receiverId);

      setState(() {
        _isSearching = false;
      });

      if (success) {
        UIHelpers.showSnackBar(
          context: context,
          message: 'Demande d\'ami envoyée avec succès',
          isSuccess: true,
        );
        widget.refreshCallback();
        Navigator.pop(context);
      } else {
        UIHelpers.showSnackBar(
          context: context,
          message: 'Erreur lors de l\'envoi de la demande d\'ami',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      UIHelpers.showSnackBar(
        context: context,
        message: 'Erreur: ${e.toString()}',
        isError: true,
      );
    }
  }
}