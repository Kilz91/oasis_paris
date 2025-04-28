import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir l'ID de l'utilisateur actuel
  String? get currentUserId => _auth.currentUser?.uid;

  // Créer ou obtenir une conversation entre deux utilisateurs
  Future<String> getOrCreateConversation(String otherUserId) async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Créer un ID de conversation triée (pour garantir l'unicité)
    final List<String> participantIds = [currentUserId!, otherUserId]..sort();
    final String conversationId = participantIds.join('_');

    // Vérifier si la conversation existe déjà
    DocumentSnapshot conversationDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!conversationDoc.exists) {
      // Récupérer les infos des utilisateurs
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      final otherUserDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!currentUserDoc.exists || !otherUserDoc.exists) {
        throw Exception("L'un des utilisateurs n'existe pas");
      }

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final otherUserData = otherUserDoc.data() as Map<String, dynamic>;

      // Créer la conversation
      final conversation = ConversationModel(
        id: conversationId,
        participants: participantIds,
        participantsInfo: {
          currentUserId!: {
            'name': '${currentUserData['prenom']} ${currentUserData['nom']}',
            'profile_picture': currentUserData['photoURL'] ?? '',
          },
          otherUserId: {
            'name': '${otherUserData['prenom']} ${otherUserData['nom']}',
            'profile_picture': otherUserData['photoURL'] ?? '',
          },
        },
        readStatus: {
          currentUserId!: true,
          otherUserId: true,
        },
      );
      
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .set(conversation.toMap());
    }

    return conversationId;
  }

  // Envoyer un message
  Future<void> sendMessage(String conversationId, String content, {String? imageUrl}) async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Créer le message
    final message = MessageModel(
      id: '', // ID sera attribué par Firestore
      senderId: currentUserId!,
      content: content,
      read: false,
      imageUrl: imageUrl,
    );

    // Ajouter le message à la collection
    final docRef = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toMap());

    // Mettre à jour les informations de la conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'last_message': content,
      'last_message_timestamp': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'read_status': {
        currentUserId!: true,
      },
    });
  }

  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String conversationId) async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Mettre à jour le statut de lecture pour l'utilisateur actuel
    await _firestore.collection('conversations').doc(conversationId).update({
      'read_status.${currentUserId}': true,
    });

    // Trouver tous les messages non lus et les marquer comme lus
    final unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('sender_id', isNotEqualTo: currentUserId)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    
    await batch.commit();
  }

  // Obtenir les conversations de l'utilisateur
  Stream<List<ConversationModel>> getUserConversations() {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ConversationModel.fromMap(
              doc.data(), 
              doc.id
            );
          }).toList();
        });
  }

  // Obtenir les messages d'une conversation
  Stream<List<MessageModel>> getConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromMap(
              doc.data(), 
              doc.id
            );
          }).toList();
        });
  }

  // Supprimer une conversation
  Future<void> deleteConversation(String conversationId) async {
    // Obtenir tous les messages de la conversation
    final messages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();

    // Supprimer tous les messages en utilisant batch pour de meilleures performances
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Supprimer la conversation elle-même
    batch.delete(_firestore.collection('conversations').doc(conversationId));

    await batch.commit();
  }

  // Supprimer un message spécifique
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();

    // Mettre à jour la dernière activité de la conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Vérifier s'il s'agissait du dernier message et mettre à jour les informations
    final lastMessage = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastMessage.docs.isNotEmpty) {
      final newLastMessage = lastMessage.docs.first;
      await _firestore.collection('conversations').doc(conversationId).update({
        'last_message': newLastMessage['content'],
        'last_message_timestamp': newLastMessage['timestamp'],
      });
    } else {
      // Si plus aucun message, réinitialiser les informations
      await _firestore.collection('conversations').doc(conversationId).update({
        'last_message': null,
        'last_message_timestamp': null,
      });
    }
  }

  // Obtenir le nombre de messages non lus
  Future<int> getUnreadMessagesCount() async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    final conversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    int unreadCount = 0;
    for (final doc in conversations.docs) {
      final data = doc.data();
      final readStatus = data['read_status'] as Map<String, dynamic>?;
      
      if (readStatus != null) {
        final isRead = readStatus[currentUserId] ?? false;
        if (!isRead) {
          unreadCount++;
        }
      }
    }

    return unreadCount;
  }

  // Stream pour observer le nombre de messages non lus en temps réel
  Stream<int> unreadMessagesCountStream() {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final readStatus = data['read_status'] as Map<String, dynamic>?;
        
        if (readStatus != null) {
          final isRead = readStatus[currentUserId] ?? false;
          if (!isRead) {
            count++;
          }
        }
      }
      return count;
    });
  }
}