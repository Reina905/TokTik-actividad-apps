import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StreamSubscription<User?> _userSubscription;

  User? _user;

  AuthProvider() {
    // Firebase guarda la sesión: al abrir la app, el usuario sigue conectado
    _user = _auth.currentUser;

    // userChanges también avisa cuando cambia el nombre del perfil
    _userSubscription = _auth.userChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  bool get isLoggedIn => _user != null;
  String? get userEmail => _user?.email;
  String? get userName => _user?.displayName;


  /// Lanza [AuthException] con un mensaje en español si falla.
  Future<void> login({ required String email, required String password }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  /// Lanza [AuthException] con un mensaje en español si falla.
  Future<void> register({
    required String name,
    required String email,
    required String password
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  Future<void> logout() => _auth.signOut();


  String _messageFor(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Correo o contraseña incorrectos';
      case 'invalid-email':
        return 'El correo no es válido';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e inténtalo de nuevo';
      case 'network-request-failed':
        return 'Sin conexión a internet';
      case 'operation-not-allowed':
        return 'El inicio con correo no está habilitado en Firebase';
      default:
        return 'Ocurrió un error. Inténtalo de nuevo';
    }
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

}


class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
