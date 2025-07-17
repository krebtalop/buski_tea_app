import 'package:flutter/material.dart';
import 'login_page.dart'; // LoginPage'in olduğu dosya bu

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController floorController = TextEditingController(); // kullanılmıyor ama bırakıldı
  final TextEditingController unitController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? selectedFloor;
  bool showError = false;
  bool passwordMismatch = false;

  void validateAndRegister() {
    final allFieldsFilled = nameController.text.isNotEmpty &&
        surnameController.text.isNotEmpty &&
        selectedFloor != null &&
        unitController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty;

    final passwordsMatch = passwordController.text == confirmPasswordController.text;

    setState(() {
      showError = !allFieldsFilled;
      passwordMismatch = allFieldsFilled && !passwordsMatch;
    });

    if (allFieldsFilled && passwordsMatch) {
      // Giriş sayfasına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'İsim:',
                  border: const OutlineInputBorder(),
                  errorText: showError && nameController.text.isEmpty ? 'Zorunlu alan' : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: surnameController,
                decoration: InputDecoration(
                  labelText: 'Soyisim:',
                  border: const OutlineInputBorder(),
                  errorText: showError && surnameController.text.isEmpty ? 'Zorunlu alan' : null,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedFloor,
                items: List.generate(10, (index) {
                  final kat = (index + 1).toString();
                  return DropdownMenuItem(value: kat, child: Text('$kat. Kat'));
                }),
                decoration: InputDecoration(
                  labelText: 'Kat:',
                  border: const OutlineInputBorder(),
                  errorText: showError && selectedFloor == null ? 'Zorunlu alan' : null,
                ),
                onChanged: (value) {
                  setState(() {
                    selectedFloor = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: InputDecoration(
                  labelText: 'Birim:',
                  border: const OutlineInputBorder(),
                  errorText: showError && unitController.text.isEmpty ? 'Zorunlu alan' : null,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası:',
                  border: const OutlineInputBorder(),
                  errorText: showError && phoneController.text.isEmpty ? 'Zorunlu alan' : null,
                ),
                keyboardType: TextInputType.number,
                maxLength: 11,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Şifre:',
                  border: const OutlineInputBorder(),
                  errorText: showError && passwordController.text.isEmpty ? 'Zorunlu alan' : null,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Şifre (Tekrar):',
                  border: const OutlineInputBorder(),
                  errorText: showError && confirmPasswordController.text.isEmpty ? 'Zorunlu alan' : null,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: validateAndRegister,
                child: const Text('Kayıt Ol'),
              ),
              if (showError)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Tüm alanları doldurunuz.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (passwordMismatch)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Şifreler aynı değil.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
