import 'package:equatable/equatable.dart';

class Speaker extends Equatable {
  const Speaker({
    required this.id,
    required this.fullName,
    this.bio,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? bio;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, fullName, bio, avatarUrl];
}
