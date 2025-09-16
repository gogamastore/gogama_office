// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException {
      rethrow; // Biarkan UI yang menangani kesalahan
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // DITAMBAHKAN: Metode untuk mengubah password pengguna
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _firebaseAuth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Pengguna tidak ditemukan atau tidak memiliki email. Silakan login ulang.',
      );
    }

    // Buat kredensial dengan password lama untuk autentikasi ulang
    final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);

    try {
      // 1. Lakukan autentikasi ulang pengguna untuk keamanan
      await user.reauthenticateWithCredential(cred);

      // 2. Jika autentikasi ulang berhasil, perbarui password
      await user.updatePassword(newPassword);

    } on FirebaseAuthException catch (e) {
      // DIPERBARUI: Tangani 'invalid-credential' dan 'wrong-password' sebagai kesalahan password yang sama
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Password lama yang Anda masukkan salah.',
        );
      }
      // Lemparkan kembali galat lain untuk ditangani oleh UI
      rethrow;
    }
  }
}
