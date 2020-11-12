import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hello_me/UserRepository.dart';

class Suggestions extends StatefulWidget {
  final UserRepository user;
  Suggestions({this.user});

  @override
  _SuggestionsState createState() => _SuggestionsState();
}

class _SuggestionsState extends State<Suggestions> {
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    UserRepository user;
    String uid = user.user.uid;
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(uid)
              .collection('Saved')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            return ListView(
              children: snapshot.data.docs.map((document) {
                return Center(
                  child: Container(child: Text(document['pair'])),
                );
              }).toList(),
            );
          }),
    );
  }
}
