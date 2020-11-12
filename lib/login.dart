import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:hello_me/UserRepository.dart';

class login extends StatefulWidget {
  final UserRepository user;

  login({this.user});

  @override
  _loginState createState() => _loginState();
}

class _loginState extends State<login> {
  bool isLoading = false;
  TextEditingController _email;
  TextEditingController _password;
  TextEditingController _passwordValidation;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _email = TextEditingController(text: "");
    _password = TextEditingController(text: "");
    _passwordValidation = TextEditingController(text:"");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: Text('Login Screen'),
        ),
        body: Builder(
            builder: (context) => Center(
                    child: ListView(children: <Widget>[
                  Container(
                      alignment: Alignment.bottomCenter,
                      padding: EdgeInsets.all(100),
                      child: Text(
                        'LOG IN',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 50),
                      )),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: TextField(
                      controller: _email,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: TextField(
                      obscureText: true,
                      controller: _password,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //forgot password screen
                    },
                    textColor: Colors.red,
                    child: Text('Forgot Password'),
                  ),
                  Container(
                      alignment: Alignment.bottomCenter,
                      height: 35,
                      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: isLoading
                          ? CircularProgressIndicator()
                          : MaterialButton(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                              elevation: 5,
                              textColor: Colors.white,
                              color: Colors.red,
                              child: Text('Login'),
                              onPressed: () async {
                                setState(() {
                                  isLoading = true;
                                });
                                if (!await widget.user.signIn(_email.text, _password.text)) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                      content: Text('There was an error logging '
                                          'into the app')));
                                } else {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  Navigator.pop(context);
                                }
                              },
                            )),
                  Container(
                      alignment: Alignment.bottomCenter,
                      height: 60,
                      child: MaterialButton(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                        elevation: 5,
                        child: Text(
                          'New user? Click to sign up!',
                          style: TextStyle(color: Colors.white),
                        ),
                        height: 35,
                        minWidth: 200,
                        color: Colors.blueGrey,
                        onPressed: () {
                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                String PasswordHint = 'Password';
                                return Wrap(children: [
                                  Form(
                                    key: _formKey,
                                    child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                                        child: Column(children: [
                                          Text('Please confirm your password', style: TextStyle(fontSize: 16)),
                                          TextFormField(
                                              controller: _passwordValidation,
                                              validator: (val) => val != _password.text ? 'Passwords do not match!' :
                                              null,
                                              obscureText: true,
                                              decoration: InputDecoration(hintText: PasswordHint)),
                                          MaterialButton(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                                            elevation: 5,
                                            child: Text('Confirm'),
                                            color: Colors.red,
                                            onPressed: () async {
                                              if (_formKey.currentState.validate()) {
                                                if (!await widget.user.signUp(_email.text, _password.text)) {
                                                } else {
                                                  Navigator.pop(context); Navigator.pop(context);
                                                }

                                              }
                                            },
                                          ),
                                        ])),
                                  ),
                                ]);
                              });
                        },
                      ))
                ]))));
    ;
  }
}
