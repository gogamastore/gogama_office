import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    String? email, 
    
    // Menggunakan @Default untuk memberikan nilai string kosong jika field tidak ada
    // Ini mencegah error TypeError jika 'name' null di Firestore.
    @Default('') String name,
    
    // Hal yang sama untuk nomor WhatsApp
    @Default('') String whatsapp,
    
    // Dan untuk URL foto
    @Default('') String photoURL,

  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
