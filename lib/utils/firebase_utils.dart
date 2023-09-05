import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendMessage(String tripId, String message, String userId, bool isDriver) async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference chatDocRef = _firestore.collection('chats').doc(tripId);

  DocumentSnapshot chatDocSnap = await chatDocRef.get();

  if (!chatDocSnap.exists) {
    await chatDocRef.set({
      'userIds': [userId],
    });
  } else {
    Map<String, dynamic> chatData = chatDocSnap.data() as Map<String, dynamic>;
    if (!chatData['userIds'].contains(userId)) {
      await chatDocRef.update({
        'userIds': FieldValue.arrayUnion([userId]),
      });
    }
  }

  await chatDocRef.collection('messages').add({
    'text': message,
    'senderId': userId,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

