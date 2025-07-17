class UserModel {
  final String name;
  final String surname;
  final String password;
  final int floor;
  final String department;
  final String phoneCode;

  UserModel({
    required this.name,
    required this.surname,
    required this.password,
    required this.floor,
    required this.department,
    required this.phoneCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'surname': surname,
      'password': password,
      'floor': floor,
      'department': department,
      'phoneCode': phoneCode,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      password: map['password'] ?? '',
      floor: map['floor'] ?? 1,
      department: map['department'] ?? '',
      phoneCode: map['phoneCode'] ?? '',
    );
  }
}
