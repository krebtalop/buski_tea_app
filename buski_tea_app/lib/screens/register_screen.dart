import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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
  final TextEditingController _phoneController = TextEditingController();
  int? _selectedFloor;

  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  bool _isLoading = false;

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
    final blueBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Kayıt Ol',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'İsim',
                    border: blueBorder,
                    focusedBorder: blueBorder,
                    enabledBorder: blueBorder,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'İsim giriniz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _surnameController,
                  decoration: InputDecoration(
                    labelText: 'Soyisim',
                    border: blueBorder,
                    focusedBorder: blueBorder,
                    enabledBorder: blueBorder,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Soyisim giriniz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  decoration: InputDecoration(
                    labelText: '11 haneli cep telefonu numaranızı giriniz',
                    hintText: 'örn: 05XXXXXXXXX',
                    border: blueBorder,
                    focusedBorder: blueBorder,
                    enabledBorder: blueBorder,
                    counterText: '',
                  ),
                  style: const TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  validator: (value) {
                    if (value == null || value.length != 11) {
                      return 'Eksik telefon numarası';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedFloor,
                  decoration: InputDecoration(
                    labelText: 'Bulunduğunuz Kat',
                    border: blueBorder,
                    focusedBorder: blueBorder,
                    enabledBorder: blueBorder,
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
                  decoration: InputDecoration(
                    labelText: 'Departman',
                    border: blueBorder,
                    focusedBorder: blueBorder,
                    enabledBorder: blueBorder,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Departman giriniz'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    border: blueBorder,
                    focusedBorder: blueBorder,
                    enabledBorder: blueBorder,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _repeatPasswordController,
                  obscureText: _obscureRepeatPassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre Tekrar',
                    border: blueBorder,
                    focusedBorder: blueBorder,
                    enabledBorder: blueBorder,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureRepeatPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureRepeatPassword = !_obscureRepeatPassword;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifreyi tekrar giriniz.';
                    }
                    if (value != _passwordController.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final firestore = FirebaseFirestore.instance;
                        final phone = _phoneController.text;
                        final password = _passwordController.text;
                        try {
                          // Telefon numarasının daha önce kayıtlı olup olmadığını kontrol et
                          final query = await firestore.collection('users').where('phoneCode', isEqualTo: phone).get();
                          if (query.docs.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bu telefon numarası ile zaten kayıtlı kullanıcı var!')),
                            );
                            return;
                          }
                          final user = UserModel(
                            name: _nameController.text,
                            surname: _surnameController.text,
                            password: password,
                            floor: _selectedFloor!,
                            department: _departmentController.text,
                            phoneCode: phone,
                          );
                          await firestore.collection('users').add(user.toMap());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kayıt başarılı! Giriş yapabilirsiniz.'),
                            ),
                          );
                          Navigator.of(context).pop();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bir hata oluştu!')),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
