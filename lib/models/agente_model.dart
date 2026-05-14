class AgenteModel {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? ci;
  final String? telefono;
  final String? codigoLicencia;
  final bool isActive;

  AgenteModel({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.ci,
    this.telefono,
    this.codigoLicencia,
    required this.isActive,
  });

  String get nombreCompleto => '$firstName $lastName'.trim();

  factory AgenteModel.fromJson(Map<String, dynamic> json) {
    return AgenteModel(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      ci: json['ci'],
      telefono: json['telefono'],
      codigoLicencia: json['codigo_licencia'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    if (ci != null) 'ci': ci,
    if (telefono != null) 'telefono': telefono,
    if (codigoLicencia != null) 'codigo_licencia': codigoLicencia,
  };
}