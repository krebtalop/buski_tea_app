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
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _repeatPasswordVisible = false;
  bool _emailSent = false;
  bool _emailVerified = false;

  Timer? _timer;
  int _start = 0;
  late String _verificationId;
  int? _expandedIndex;
  int _step = 0; // 0: e-posta, 1: kod, 2: yeni şifre
  String? _resetCode;

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Şifre en az 1 özel karakter içermeli';
    }
    return null;
  }

  void _startTimer() {
    _start = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _requestEmailCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen e-posta adresinizi giriniz.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _emailVerified = false;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _emailSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre sıfırlama kodu gönderildi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _passwordController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maildeki kodu giriniz.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Kodun geçerli olup olmadığını kontrol et
      await FirebaseAuth.instance.checkActionCode(code);
      setState(() {
        _resetCode = code;
        _step = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kod doğrulandı, yeni şifre belirleyin.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kod geçersiz veya süresi dolmuş: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_resetCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce kodu doğrulayın.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: _resetCode!,
        newPassword: _repeatPasswordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre başarıyla oluşturuldu!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre güncellenemedi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen e-posta adresinizi giriniz.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() { _step = 1; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre sıfırlama e-postası gönderildi! Maildeki kodu giriniz.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
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
                  const Text('E-posta Adresi:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-posta Adresi',
                      hintText: 'ornek@example.com',
                      border: blueBorder,
                      focusedBorder: blueBorder,
                      enabledBorder: blueBorder,
                    ),
                    style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    validator: (v) => (v == null || v.isEmpty) ? 'E-posta adresi giriniz.' : null,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _sendResetEmail,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Devam', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                if (_step == 1) ...[
                  const Text('Maildeki Kod:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Kod',
                      border: blueBorder,
                      focusedBorder: blueBorder,
                      enabledBorder: blueBorder,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    validator: (v) => (v == null || v.isEmpty) ? 'Maildeki kodu giriniz.' : null,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _verifyCode,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Devam', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                if (_step == 2) ...[
                  const Text('Yeni Şifre:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _repeatPasswordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre',
                      border: blueBorder,
                      focusedBorder: blueBorder,
                      enabledBorder: blueBorder,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Şifre en az 6 karakter olmalı';
                      }
                      if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
                        return 'Şifre en az 1 özel karakter içermeli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _resetPassword,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Şifreyi Sıfırla', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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