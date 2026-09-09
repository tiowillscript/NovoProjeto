import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  bool firebaseReady = false;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
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
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Não foi possível entrar.';
    }
  }

  Future<String?> register(String email, String password) async {
    if (!firebaseReady) return 'Configure o Firebase antes de criar uma conta.';
    if (email.isEmpty || password.length < 6) {
      return 'Informe um e-mail válido e uma senha com pelo menos 6 caracteres.';
    }
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Não foi possível criar a conta.';
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

  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!firebaseReady) return 'Firebase ainda não está configurado.';
    final currentUser = FirebaseAuth.instance.currentUser;
    final email = currentUser?.email;
    if (currentUser == null || email == null) return 'Usuário não autenticado.';
    if (currentPassword.isEmpty) return 'Informe a senha atual.';
    if (newPassword.length < 6) {
      return 'A nova senha deve possuir pelo menos 6 caracteres.';
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
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
