class User {
  final int id;
  final String nombre;
  final String email;
  final String rol;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user']['id'],
      nombre: json['user']['nombre_completo'],
      email: json['user']['email'],
      rol: json['rol'],
    );
  }
}