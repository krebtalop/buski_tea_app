import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  bool _obscureCurrentPassword = true;

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Şifre en az 1 özel karakter içermeli';
    }
    return null;
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kullanıcı oturumu yok!')));
      return;
    }

    try {
      await currentUser.updatePassword(newPassword);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'password': newPassword});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre başarıyla güncellendi.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Şifre güncellenemedi!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final blueBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Şifremi Değiştir'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFFB3E5FC)],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Şifrenizi Değiştirin',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Mevcut Şifreniz',
                        border: blueBorder,
                        focusedBorder: blueBorder,
                        enabledBorder: blueBorder,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1565C0)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mevcut şifrenizi giriniz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre',
                        border: blueBorder,
                        focusedBorder: blueBorder,
                        enabledBorder: blueBorder,
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF1565C0)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _repeatPasswordController,
                      obscureText: _obscureRepeatPassword,
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre (Tekrar)',
                        border: blueBorder,
                        focusedBorder: blueBorder,
                        enabledBorder: blueBorder,
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF1565C0)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureRepeatPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscureRepeatPassword = !_obscureRepeatPassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifreyi tekrar giriniz';
                        }
                        if (value != _newPasswordController.text) {
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _changePassword();
                          }
                        },
                        child: const Text(
                          'Şifre Değiştir',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
