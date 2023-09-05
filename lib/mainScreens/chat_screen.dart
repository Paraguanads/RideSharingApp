import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String recipientId;

  ChatScreen({required this.chatId, required this.userId, required this.recipientId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                List<DocumentSnapshot> docs = snapshot.data!.docs;

                List<Widget> messages = docs
                    .map((doc) => Message(
                  text: doc['text'],
                  isMe: widget.userId == doc['userId'],
                ))
                    .toList();

                return ListView(
                  reverse: true,
                  children: <Widget>[
                    ...messages,
                  ],
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            height: 70,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "🗨 Envíale un mensaje a tu contraparte...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      DocumentReference chatDocRef =
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

      var messageData = {
        'text': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': widget.userId,
      };

      await chatDocRef.collection('messages').add(messageData);

      DocumentSnapshot chatDocSnapshot = await chatDocRef.get();

      if (chatDocSnapshot.exists) {
        await chatDocRef.update({'lastMessage': messageData});
      } else {
        await chatDocRef.set({
          'lastMessage': messageData,
          'userIds': [widget.userId, widget.recipientId]
        });
      }

      _messageController.clear();
    }
  }
}

class Message extends StatelessWidget {
  final String text;
  final bool isMe;

  Message({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Align(
        alignment: isMe ? Alignment.topRight : Alignment.topLeft,
        child: ChatBubble(
          clipper: ChatBubbleClipper1(
              type: isMe ? BubbleType.sendBubble : BubbleType.receiverBubble),
          alignment: isMe ? Alignment.topRight : Alignment.topLeft,
          margin: EdgeInsets.only(top: 20),
          backGroundColor: isMe ? Colors.blue : Color(0xffE7E7ED),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
