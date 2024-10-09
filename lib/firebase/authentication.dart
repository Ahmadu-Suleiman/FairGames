import 'package:firebase_auth/firebase_auth.dart';

class Authentication {
  static final auth = FirebaseAuth.instance;

  static User? get user => auth.currentUser;
}
