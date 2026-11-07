import 'package:freezed_annotation/freezed_annotation.dart';

part 'proof.freezed.dart';
part 'proof.g.dart';

/// One submission attempt. [imageUrl] is presigned and dies after about ten
/// minutes: show it right away, never store or log it.
@freezed
abstract class Proof with _$Proof {
  const factory Proof({
    required int attemptNo,
    String? imageUrl,
    String? text,
    required DateTime createdAt,
  }) = _Proof;

  factory Proof.fromJson(Map<String, Object?> json) => _$ProofFromJson(json);
}
