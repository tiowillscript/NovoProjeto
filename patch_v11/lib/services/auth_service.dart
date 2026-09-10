import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class AuthService {
  bool firebaseReady = false;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        final options = AulaFacilFirebaseOptions.current;
        if (options != null) {
          await Firebase.initializeApp(options: options);
        } else {
          await Firebase.initializeApp();
        }
      }
      firebaseReady = true;
    } catch (_) {
      firebaseReady = false;
    }
  }

  User? get user => firebaseReady ? FirebaseAuth.instance.currentUser : null;

  Future<String?> signIn(String email, String password) async {
    if (!firebaseReady) return 'Firebase ainda não está configurado.';
    if (email.isEmpty || password.isEmpty) return 'Informe e-mail e senha.';
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureLegacyTeacherProfile();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Não foi possível entrar.';
    } catch (e) {
      return 'Não foi possível entrar: $e';
    }
  }

  Future<String?> register(
    String email,
    String password, {
    String name = 'Professor',
    String role = 'teacher',
  }) async {
    if (!firebaseReady) return 'Configure o Firebase antes de criar uma conta.';
    if (email.isEmpty || password.length < 6) {
      return 'Informe um e-mail válido e uma senha com pelo menos 6 caracteres.';
    }
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) return 'Não foi possível concluir o cadastro.';
      final cleanName = name.trim().isEmpty ? (role == 'student' ? 'Aluno' : 'Professor') : name.trim();
      await user.updateDisplayName(cleanName);
      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).set({
        'name': cleanName,
        'email': email.trim().toLowerCase(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Não foi possível criar a conta.';
    } catch (e) {
      return 'Não foi possível criar a conta: $e';
    }
  }

  Future<Map<String, dynamic>?> profile() async {
    final currentUser = user;
    if (!firebaseReady || currentUser == null) return null;
    final doc = await FirebaseFirestore.instance.collection('profiles').doc(currentUser.uid).get();
    return doc.data();
  }

  Future<String> currentRole() async {
    if (!firebaseReady || user == null) return 'local';
    await _ensureLegacyTeacherProfile();
    final data = await profile();
    return '${data?['role'] ?? 'teacher'}';
  }

  Future<String> currentName() async {
    final data = await profile();
    return '${data?['name'] ?? user?.displayName ?? user?.email ?? 'Usuário'}';
  }

  Future<void> _ensureLegacyTeacherProfile() async {
    final currentUser = user;
    if (!firebaseReady || currentUser == null) return;
    final ref = FirebaseFirestore.instance.collection('profiles').doc(currentUser.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'name': currentUser.displayName ?? 'Professor',
        'email': (currentUser.email ?? '').toLowerCase(),
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String?> reset(String email) async {
    if (!firebaseReady) return 'Firebase ainda não está configurado.';
    if (email.isEmpty) return 'Informe o e-mail primeiro.';
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Não foi possível enviar o e-mail de recuperação.';
    }
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    if (!firebaseReady) return 'Firebase ainda não está configurado.';
    final currentUser = FirebaseAuth.instance.currentUser;
    final email = currentUser?.email;
    if (currentUser == null || email == null) return 'Usuário não autenticado.';
    if (currentPassword.isEmpty) return 'Informe a senha atual.';
    if (newPassword.length < 6) return 'A nova senha deve possuir pelo menos 6 caracteres.';
    try {
      final credential = EmailAuthProvider.credential(email: email, password: currentPassword);
      await currentUser.reauthenticateWithCredential(credential);
      await currentUser.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Não foi possível alterar a senha.';
    }
  }

  Future<void> signOut() async {
    if (firebaseReady) await FirebaseAuth.instance.signOut();
  }
}
