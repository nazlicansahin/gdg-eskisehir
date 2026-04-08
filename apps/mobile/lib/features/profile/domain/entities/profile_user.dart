import 'package:equatable/equatable.dart';

class ProfileUser extends Equatable {
  const ProfileUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.roles,
  });

  final String id;
  final String email;
  final String displayName;
  final List<String> roles;

  bool get canScanTickets {
    const staff = {
      'team_member',
      'crew',
      'organizer',
      'super_admin',
    };
    return roles.any(staff.contains);
  }

  bool get canEditEvents {
    const editors = {'organizer', 'super_admin'};
    return roles.any(editors.contains);
  }

  @override
  List<Object?> get props => [id, email, displayName, roles];
}
