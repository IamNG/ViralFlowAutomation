import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String fullName,
    @Default('') String avatarUrl,
    @Default('free') String plan, // free, pro, enterprise
    @Default(0) int creditsRemaining,
    @Default(0) int totalContentGenerated,
    @Default([]) List<String> connectedPlatforms,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}