import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../mainScreens/chat_screen.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({Key? key}) : super(key: key);

  @override
  _ChatTabState createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('userIds', arrayContains: currentUserId)
            .orderBy('lastMessage.timestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('❌ Algo salió mal: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('🍃 Por ahora, no hay chats.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot chatDocument = snapshot.data!.docs[index];
              Map<String, dynamic> chatData = chatDocument.data() as Map<String, dynamic>;
              Map<String, dynamic> lastMessageData = chatData['lastMessage'] as Map<String, dynamic>;

              String recipientId = chatData['userIds'][0];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(recipientId).get(),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> recipientSnapshot) {
                  if (recipientSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Cargando...'),
                    );
                  }

                  if (!recipientSnapshot.hasData || !recipientSnapshot.data!.exists) {
                    return ListTile(
                      title: Text('Destinatario no encontrado'),
                    );
                  }

                  String recipientName = recipientSnapshot.data!.get('userName') as String;

                  return Card(
                    child: ListTile(
                      title: Text(recipientName),
                      subtitle: Text(lastMessageData['text']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chatDocument.id,
                              userId: currentUserId,
                              recipientId: recipientId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
