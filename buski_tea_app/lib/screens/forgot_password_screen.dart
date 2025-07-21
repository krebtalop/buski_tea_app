import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  bool _isLoading = false;

  bool _passwordVisible = false;
  bool _repeatPasswordVisible = false;

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Şifre en az 1 özel karakter içermeli';
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text;
    final email = '$code@buski.com';
    final newPassword = _passwordController.text;

    try {
      setState(() {
        _isLoading = true;
      });
      final auth = FirebaseAuth.instance;
      final userList = await auth.fetchSignInMethodsForEmail(email);
      if (userList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu kodla kayıtlı kullanıcı bulunamadı!'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      await auth.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'E-posta gönderildi! Şifrenizi e-postanızdan sıfırlayabilirsiniz.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          'Şifre Değiştir',
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
                const Text(
                  'Telefon Numarası:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  decoration: InputDecoration(
                    labelText: 'Telefon Numarası',
                    hintText: 'örn: 05XXXXXXXXX',
                    helperText: '11 haneli cep telefonu numaranızı giriniz',
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
                const Text(
                  'Yeni Şifre:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    border: blueBorder,
                    focusedBorder: blueBorder,
                    enabledBorder: blueBorder,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
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
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Yeni Şifre (Tekrar):',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _repeatPasswordController,
                  obscureText: !_repeatPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre (Tekrar)',
                    border: blueBorder,
                    focusedBorder: blueBorder,
                    enabledBorder: blueBorder,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _repeatPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _repeatPasswordVisible = !_repeatPasswordVisible;
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
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Şifreyi Oluştur',
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
    );
  }
}
