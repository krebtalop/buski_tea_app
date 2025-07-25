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

  bool _isLoading = false;
  bool _emailVerifiedAndSent = false;
  String? _infoMessage;
  bool _showSuccess = false;

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _infoMessage = 'Lütfen e-posta adresinizi giriniz.');
      return;
    }
    setState(() {
      _isLoading = true;
      _infoMessage = null;
      _emailVerifiedAndSent = false;
      _showSuccess = false;
    });
    try {
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _emailVerifiedAndSent = true;
        _infoMessage =
            'Kod e-posta adresinize gönderildi. Lütfen mailinizi kontrol edin.';
        _showSuccess = true;
      });
      // Otomatik yönlendirme kaldırıldı
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'invalid-email' || e.code == 'user-not-found') {
          _infoMessage = 'E-posta adresi geçersiz.';
        } else {
          _infoMessage = 'Hata: ${e.message}';
        }
        _emailVerifiedAndSent = false;
      });
    } catch (e) {
      setState(() {
        _infoMessage = 'Hata: $e';
        _emailVerifiedAndSent = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
        title: const Text('Şifremi Unuttum',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Text('E-posta Adresi',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    border: blueBorder,
                    focusedBorder: blueBorder,
                    enabledBorder: blueBorder,
                    suffixIcon: _emailVerifiedAndSent
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                if (_showSuccess)
                  Column(
                    children: [
                      AnimatedScale(
                        scale: _showSuccess ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        child: Icon(Icons.check_circle, color: Colors.green, size: 56),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Şifre sıfırlama linki mailinize gönderildi.',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _sendResetEmail,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Kod Gönder',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}