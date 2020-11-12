import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/painting.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hello_me/UserRepository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hello_me/login.dart';
import 'package:hello_me/suggestions.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class loginSnappingSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MyApp extends StatelessWidget {
  GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final List<WordPair> _suggestions = <WordPair>[];
  final _saved = Set<WordPair>();
  final TextStyle _biggerFont = const TextStyle(fontSize: 18);
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserRepository user;
  double snapValue = 0.0;
  double blurValue = 0.0;
  ImagePicker imagePicker = ImagePicker();
  PickedFile _imageFile;
  String photoUrl;
  String profileURL;
  SnappingSheetController controller = SnappingSheetController();
  FirebaseFirestore suggestionsInst = FirebaseFirestore.instance;
  CollectionReference suggestionsColl =
      FirebaseFirestore.instance.collection('Users');
  @override
  void initState() {
    super.initState();
    profileURL = "";
    //loading = false;
  }

  Future<void> uploadImage(String filePath, User user) async {
    File file = File(filePath);

    try {
      await firebase_storage.FirebaseStorage.instance
          .ref('${user.uid}/file-to-upload.png')
          .putFile(file);
    } on FirebaseException catch (e) {
      print("there was an exception uploading the image: $e");
      // e.g, e.code == 'canceled'
    }
  }

  Future<void> downloadImage(User user) async {
    //Directory appDocDir = await getApplicationDocumentsDirectory();
    //File downloadToFile = File('${appDocDir.path}/download-logo.png');

    try {
      await firebase_storage.FirebaseStorage.instance
          .ref('${user.uid}/file-to-upload.png')
          .getDownloadURL()
          .then((value) {
        setState(() {
          profileURL = value;
        });
      });
      //.writeToFile(downloadToFile);
    } on FirebaseException catch (e) {
      print("there was a problen getting the image: $e");
      setState(() {
        profileURL = "";
      });
      // e.g, e.code == 'canceled'
    }
  }

  void _pushLogin(UserRepository user) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => login(user: user)));
    if (user.status == Status.Authenticated) {
      CollectionReference user_saved =
          suggestionsColl.doc(user.user.uid).collection('Saved');
      addPairToUI(user_saved);
      downloadImage(user.user);
    }
  }

  double blueFunction(double snapVal) {
    if (snapValue != 0) {
      blurValue = 5.0;
    }
  }

  _imgFromGallery() async {
    PickedFile image = await imagePicker.getImage(source: ImageSource.gallery);

    setState(() {
      _imageFile = image;
    });
  }

  void _pushSavedAuth(UserRepository user) {
    CollectionReference user_saved =
        suggestionsColl.doc(user.user.uid).collection('Saved');
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return StreamBuilder(
        stream: user_saved.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return Scaffold(
            appBar:
                AppBar(title: Text("My Saved"), backgroundColor: Colors.red),
            body: ListView(
              children: snapshot.data.docs.map((document) {
                return Center(
                  child: ListTile(
                    title: Text(document['pair']),
                    trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          var doc = document['pair']
                              .toString()
                              .split(RegExp(r"(?=[A-Z])"));
                          WordPair wp = WordPair(doc[0], doc[1]);
                          setState(() {
                            _saved.remove(wp.toLowerCase());
                          });
                          removeSaved(user_saved, document['pair']);
                          // _scaffoldKey.currentState.showSnackBar(SnackBar(
                          // content: Text('Deletion is not implemented yet')));
                        }),
                  ),
                );
              }).toList(),
            ),
          );
        },
      );
    }));
  }

  void addPairToUI(CollectionReference user_fav) async {
    await user_fav.get().then((QuerySnapshot querySnapshot) => {
          querySnapshot.docs.forEach((doc) {
            //var v = doc['pair'];
            //print("pair in doc: $v");
            //print("pair got: $p");
            var d = doc['pair'].toString().split(RegExp(r"(?=[A-Z])"));
            //print("d is: $d");
            WordPair w = WordPair(d[0], d[1]);
            print("w is: $w");
            //var a = _saved[0];
            //print("_saved[0]: $a");
            if (!_saved.contains(w)) {
              print("$w is not in set");
              //print("true");
              setState(() {
                _saved.add(w.toLowerCase());
              });
              print(_saved);
              //print("id in if is: $id");
            }
          })
        });
  }

  void _pushSaved() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        final tiles = _saved.map(
          (WordPair pair) {
            return ListTile(
              title: Text(
                pair.asPascalCase,
                style: _biggerFont,
              ),
              trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _saved.remove(pair);
                      (context as Element).reassemble();
                    });
                    // _scaffoldKey.currentState.showSnackBar(SnackBar(
                    // content: Text('Deletion is not implemented yet')));
                  }),
            );
          },
        );
        final divided = ListTile.divideTiles(
          context: context,
          tiles: tiles,
        ).toList();

        return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              backgroundColor: Colors.red,
              title: Text('Saved Suggestions'),
            ),
            body: ListView(children: divided));
      },
    ));
  }

  void snappingFunction(SnappingSheetController s) {
    if (s.currentSnapPosition != 0) {
      blurValue = 4.0;
    }
  }

  Future<void> addSaved(CollectionReference user_saved, WordPair pair) {
    String p = pair.asPascalCase;
    return user_saved
        .add({"pair": p})
        .then((value) => print("fav add"))
        .catchError((error) => print("Failed to add pair: $error"));
  }

  Future<void> removeSaved(CollectionReference user_saved, String pair) async {
    //String p = pair.toString();
    String id;
    await user_saved.get().then((QuerySnapshot querySnapshot) => {
          querySnapshot.docs.forEach((doc) {
            if (doc['pair'] == pair) {
              id = doc.id;
            }
          })
        });
    //print("id is: $id");
    user_saved
        .doc(id.toString())
        .delete()
        .then((value) => print("Pair Deleted"))
        .catchError((error) => print("Failed to delete user: $error"));
  }

  Future<void> getSavedWords(CollectionReference user_saved, Set s) async {
    await user_saved.get().then((QuerySnapshot querySnapshot) => {
          querySnapshot.docs.forEach((doc) {
            var d = doc['pair'].toString().split(RegExp(r"(?=[A-Z])"));
            print(d);
            WordPair w = WordPair(d[0], d[1]);
            s.add(w);
          })
        });
  }

  void addPairInDB(CollectionReference user_fav, WordPair pair) async {
    String p = pair.asPascalCase;
    bool found = false;
    await user_fav.get().then((QuerySnapshot querySnapshot) => {
          querySnapshot.docs.forEach((doc) {
            //var v = doc['pair'];
            //print("pair in doc: $v");
            //print("pair got: $p");
            if (doc['pair'] == p) {
              //print("true");
              found = true;
              //print("id in if is: $id");
            }
          })
        });
    //print("id is: $id");
    if (!found) addSaved(user_fav, pair);
  }

  // final wordPair = WordPair.random();
  // return Text(wordPair.asPascalCase);
  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ChangeNotifierProvider<UserRepository>(
        builder: (_) => UserRepository.instance(),
        child: Consumer<UserRepository>(builder: (context, user, _) {
          return ListTile(
              title: Text(
                pair.asPascalCase,
                style: _biggerFont,
              ),
              trailing: Icon(
                alreadySaved ? Icons.favorite : Icons.favorite_border,
                color: alreadySaved ? Colors.red : null,
              ),
              onTap: () {
                ////////
                User current_user = user.user;
                CollectionReference user_saved;
                if (user.status == Status.Authenticated) {
                  user_saved =
                      suggestionsColl.doc(current_user.uid).collection('Saved');
                  if (!alreadySaved) {
                    addSaved(user_saved, pair);
                  } else {
                    removeSaved(user_saved, pair.asPascalCase);
                  }
                }
                setState(() {
                  if (alreadySaved) {
                    _saved.remove(pair);
                  } else {
                    _saved.add(pair);
                  }
                });
              });
        }));
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        // The itemBuilder callback is called once per suggested
        // word pairing, and places each suggestion into a ListTile
        // row. For even rows, the function adds a ListTile row for
        // the word pairing. For odd rows, the function adds a
        // Divider widget to visually separate the entries. Note that
        // the divider may be difficult to see on smaller devices.
        itemBuilder: (BuildContext _context, int i) {
          // Add a one-pixel-high divider widget before each row
          // in the ListView.
          if (i.isOdd) {
            return Divider();
          }

          // The syntax "i ~/ 2" divides i by 2 and returns an
          // integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings
          // in the ListView,minus the divider widgets.
          final int index = i ~/ 2;
          // If you've reached the end of the available word
          // pairings...
          if (index >= _suggestions.length) {
            // ...then generate 10 more and add them to the
            // suggestions list.
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserRepository>(
      builder: (_) => UserRepository.instance(),
      child: Consumer<UserRepository>(builder: (context, user, _) {
        // String uid = user.user.uid;
        // CollectionReference user_saved =
        //     suggestionsColl.doc(uid).collection('Saved');
        // Set<WordPair> savedPairs = Set<WordPair>();
        // if (user.status == Status.Authenticated) {
        //   getSavedWords(user_saved, savedPairs);
        // } else {
        //   savedPairs = _saved;
        // }
        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            backgroundColor: Colors.red,
            title: Text('Startup Name Generator'),
            actions: [
              IconButton(
                  icon: Icon(Icons.list),
                  onPressed: () {
                    if (user.status == Status.Authenticated) {
                      CollectionReference user_saved = suggestionsColl
                          .doc(user.user.uid)
                          .collection('Saved');
                      if (_saved.isNotEmpty) {
                        for (var pair in _saved) {
                          addPairInDB(user_saved, pair);
                        }
                      }

                      _pushSavedAuth(user);
                    } else {
                      _pushSaved();
                    }
                  }),
              if (user.status == Status.Authenticated)
                IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () {
                      print("sign out");
                      user.signOut();
                      setState(() {
                        _saved.clear();
                      });
                    })
              else
                IconButton(
                  icon: Icon(Icons.login),
                  onPressed: () {
                    _pushLogin(user);
                    print(user.status);
                  },
                )
            ],
          ),
          body: (user.status != Status.Authenticated
              ? _buildSuggestions()
              : Stack(children: [
                  Container(
                    child: _buildSuggestions(),
                  ),
                  BackdropFilter(
                    filter:
                        ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
                    child: SnappingSheet(
                      snapPositions: [
                        SnapPosition(
                            positionPixel: 0,
                            snappingCurve: Curves.ease,
                            snappingDuration: Duration(milliseconds: 500)),
                        SnapPosition(
                            positionPixel: 100,
                            snappingCurve: Curves.ease,
                            snappingDuration: Duration(milliseconds: 500)),
                        SnapPosition(
                            positionFactor: 0.5,
                            snappingCurve: Curves.ease,
                            snappingDuration: Duration(milliseconds: 500)),
                      ],
                      onSnapBegin: () {
                        setState(() {
                          SnapPosition x = controller.snapPositions[0];
                          if (controller.currentSnapPosition ==
                              controller.snapPositions[0]) {
                            blurValue = 0;
                          } else {
                            blurValue = 4.0;
                          }
                        });
                      },
                      initSnapPosition: SnapPosition(positionPixel: 0),
                      sheetBelow: SnappingSheetContent(
                        child: Container(
                          // padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                          child: Row(children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                              child: Material(
                                elevation: 5,
                                shape: CircleBorder(),
                                child: profileURL == ""
                                    ? CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        radius: 40,
                                      )
                                    : CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(profileURL.toString()),
                                        radius: 40),
                              ),
                            ),
                            Wrap(children: [
                              Container(
                                  padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                                  child: Column(
                                    children: [
                                      Text('    ' + user.user.email,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      Container(
                                        padding:
                                            EdgeInsets.fromLTRB(15, 0, 0, 0),
                                        child: MaterialButton(
                                            height: 25,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20.0)),
                                            elevation: 5,
                                            color: Colors.redAccent,
                                            child: Center(
                                                child: Text('Change Avatar',
                                                    style: TextStyle(
                                                        color: Colors.white))),
                                            onPressed: () async {
                                              await _imgFromGallery();
                                              if (_imageFile == null) {
                                                _scaffoldKey.currentState
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            'No image selected')));
                                              } else {
                                                await uploadImage(
                                                    _imageFile.path, user.user);
                                                await downloadImage(user.user);
                                              }
                                            }),
                                      )
                                    ],
                                  )),
                            ]),
                          ]),
                          //child: _buildSuggestions(),
                          color: Colors.white,
                        ),
                        heightBehavior: SnappingSheetHeight.fit(),
                      ),
                      snappingSheetController: controller,
                      grabbing: InkWell(
                        onTap: () {
                          setState(() {
                            if (controller.currentSnapPosition ==
                                controller.snapPositions[0]) {
                              controller
                                  .snapToPosition(controller.snapPositions[1]);
                              blurValue = 4;
                            } else {
                              controller
                                  .snapToPosition(controller.snapPositions[0]);
                              blurValue = 0;
                            }
                          });
                        },
                        child: Container(
                          child: Stack(children: [
                            Container(
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                                child: Icon(
                                    snapValue == 0
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_up_rounded,
                                    color: Colors.white60)),
                            Wrap(
                              direction: Axis.vertical,
                              children: [
                                Center(
                                    child: Text(
                                  '   Welcome Back ' + user.user.email,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )),
                              ],
                            ),
                          ]),
                          color: Colors.black87,
                        ),
                      ),
                      grabbingHeight: 25,
                    ),
                  ),
                ])),
        );
      }),
    );
  }
}
