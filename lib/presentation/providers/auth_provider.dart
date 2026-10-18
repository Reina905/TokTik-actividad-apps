import 'package:flutter/material.dart';

// TODO: Reemplazar la simulación por Firebase Auth
class AuthProvider extends ChangeNotifier {

  String? userEmail;
  String? userName;

  bool get isLoggedIn => userEmail != null;


  Future<void> login({ required String email, required String password }) async {
    await Future.delayed( const Duration(milliseconds: 600) );

    userEmail = email;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password
  }) async {
    await Future.delayed( const Duration(milliseconds: 600) );

    userName = name;
    userEmail = email;
    notifyListeners();
  }

  void logout() {
    userName = null;
    userEmail = null;
    notifyListeners();
  }

}
