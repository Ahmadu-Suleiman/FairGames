import 'package:firebase_auth/firebase_auth.dart';

class Authentication {
  static final auth = FirebaseAuth.instance;

  static get user => auth.currentUser;
}
