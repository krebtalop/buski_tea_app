import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();

  bool _isLoading = false;
  int _step = 0; // 0: email, 1: kod, 2: yeni şifre
  String? _resetCode;
  String? _infoMessage;

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _infoMessage = 'Lütfen e-posta adresinizi giriniz.');
      return;
    }
    setState(() { _isLoading = true; _infoMessage = null; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _step = 1;
        _infoMessage = 'Kod e-posta adresinize gönderildi. Lütfen mailinizi kontrol edin.';
      });
    } catch (e) {
      setState(() { _infoMessage = 'Hata: $e'; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _infoMessage = 'Maildeki kodu giriniz.');
      return;
    }
    setState(() { _isLoading = true; _infoMessage = null; });
    try {
      await FirebaseAuth.instance.checkActionCode(code);
      setState(() {
        _resetCode = code;
        _step = 2;
        _infoMessage = 'Kod doğrulandı, yeni şifre belirleyin.';
      });
    } catch (e) {
      setState(() { _infoMessage = 'Kod geçersiz veya süresi dolmuş: $e'; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_resetCode == null) {
      setState(() => _infoMessage = 'Önce kodu doğrulayın.');
      return;
    }
    if (_newPasswordController.text != _repeatPasswordController.text) {
      setState(() => _infoMessage = 'Şifreler eşleşmiyor.');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      setState(() => _infoMessage = 'Şifre en az 6 karakter olmalı.');
      return;
    }
    setState(() { _isLoading = true; _infoMessage = null; });
    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: _resetCode!,
        newPassword: _newPasswordController.text,
      );
      setState(() {
        _infoMessage = 'Şifre başarıyla değiştirildi!';
      });
      Navigator.of(context).pop();
    } catch (e) {
      setState(() { _infoMessage = 'Şifre güncellenemedi: $e'; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blueBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Şifremi Unuttum', style: TextStyle(fontWeight: FontWeight.bold)),
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
                if (_step == 0) ...[
                  const Text('E-posta Adresi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      border: blueBorder,
                      focusedBorder: blueBorder,
                      enabledBorder: blueBorder,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isLoading ? null : _sendResetEmail,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Kod Gönder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
                if (_step == 1) ...[
                  const Text('Maildeki Kod', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Kod',
                      border: blueBorder,
                      focusedBorder: blueBorder,
                      enabledBorder: blueBorder,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isLoading ? null : _verifyCode,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Kodu Doğrula', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
                if (_step == 2) ...[
                  const Text('Yeni Şifre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre',
                      border: blueBorder,
                      focusedBorder: blueBorder,
                      enabledBorder: blueBorder,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _repeatPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre (Tekrar)',
                      border: blueBorder,
                      focusedBorder: blueBorder,
                      enabledBorder: blueBorder,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Şifreyi Değiştir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
                if (_infoMessage != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _infoMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}