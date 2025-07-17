import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  int? _selectedFloor;

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Şifre en az 1 özel karakter içermeli';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'İsim',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'İsim giriniz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _surnameController,
                  decoration: const InputDecoration(
                    labelText: 'Soyisim',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Soyisim giriniz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _repeatPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre Tekrar',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedFloor,
                  decoration: const InputDecoration(
                    labelText: 'Bulunduğunuz Kat',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(10, (index) => index + 1)
                      .map(
                        (floor) => DropdownMenuItem(
                          value: floor,
                          child: Text('$floor. Kat'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedFloor = value),
                  validator: (value) => value == null ? 'Kat seçiniz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Departman',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Departman giriniz'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: '4 Haneli Telefon Kodu',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length != 4) {
                      return '4 haneli kod giriniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final firestore = FirebaseFirestore.instance;
                        final code = _codeController.text;
                        final email = '$code@buski.com';
                        final password = _passwordController.text;
                        try {
                          // Firebase Auth ile kullanıcı kaydı
                          final auth = FirebaseAuth.instance;
                          final userCredential = await auth
                              .createUserWithEmailAndPassword(
                                email: email,
                                password: password,
                              );
                          // Firestore'a kullanıcı bilgilerini kaydet
                          final user = UserModel(
                            name: _nameController.text,
                            surname: _surnameController.text,
                            password: password,
                            floor: _selectedFloor!,
                            department: _departmentController.text,
                            phoneCode: code,
                          );
                          await firestore
                              .collection('users')
                              .doc(userCredential.user!.uid)
                              .set(user.toMap());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Kayıt başarılı! Giriş yapabilirsiniz.',
                              ),
                            ),
                          );
                          Navigator.of(context).pop();
                        } on FirebaseAuthException catch (e) {
                          String msg = 'Kayıt başarısız';
                          if (e.code == 'email-already-in-use') {
                            msg =
                                'Bu telefon kodu ile zaten kayıtlı kullanıcı var!';
                          } else if (e.code == 'weak-password') {
                            msg = 'Şifre çok zayıf!';
                          }
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(msg)));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bir hata oluştu!')),
                          );
                        }
                      }
                    },
                    child: const Text('Kayıt Ol'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
