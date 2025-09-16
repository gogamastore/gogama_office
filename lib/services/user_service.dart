import 'dart:io';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // DITINGKATKAN: Konverter yang lebih aman untuk menangani kasus data tidak lengkap
  CollectionReference<UserModel> get _userRef =>
      _firestore.collection('user').withConverter<UserModel>(
            fromFirestore: (snapshot, _) {
              final data = snapshot.data();
              if (data == null) {
                // Jika tidak ada data sama sekali, kembalikan model default atau lemparkan galat
                // Dalam kasus ini, kita asumsikan uid harus selalu ada
                throw Exception("Dokumen pengguna tidak ada atau kosong.");
              }
              // SECURE: Secara eksplisit menambahkan/menimpa UID dari ID dokumen
              // Ini menjamin bahwa field 'uid' di UserModel tidak akan pernah null.
              data['uid'] = snapshot.id;
              return UserModel.fromJson(data);
            },
            toFirestore: (user, _) => user.toJson(),
          );

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _userRef.doc(uid).get();
      return doc.data();
    } catch (e, s) {
      developer.log(
        'Gagal mengambil data pengguna.',
        name: 'UserService.getUser',
        error: e,
        stackTrace: s,
      );
      // Mengembalikan null jika ada galat saat deserialisasi (misalnya dari 'fromJson')
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    await _userRef.doc(user.uid).set(user, SetOptions(merge: true));
  }

  Future<String> uploadProfilePicture(String uid, File imageFile) async {
    try {
      final fileExtension = imageFile.path.split('.').last;
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final ref = _storage.ref('profile_pictures/$uid/$fileName');

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e, s) {
      developer.log('Firebase Storage Error', name: 'UserService', error: e, stackTrace: s);
      rethrow;
    } catch (e, s) {
      developer.log('Terjadi kesalahan tak terduga', name: 'UserService', error: e, stackTrace: s);
      rethrow;
    }
  }
}

final userServiceProvider = Provider((ref) => UserService());

// TIDAK ADA PERUBAHAN: Provider ini sudah benar
final currentUserProvider = FutureProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userService = ref.watch(userServiceProvider);

  final user = authState.asData?.value;
  if (user != null) {
    return userService.getUser(user.uid);
  }
  return Future.value(null); // Mengembalikan Future yang sudah selesai dengan nilai null
});
