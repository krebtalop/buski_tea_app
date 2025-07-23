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
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _repeatPasswordVisible = false;
  bool _smsCodeSent = false;
  bool _smsCodeVerified = false;

  Timer? _timer;
  int _start = 0;
  late String _verificationId;
  int? _expandedIndex;
  int _step = 0; // 0: telefon, 1: sms, 2: şifre

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

  Future<void> _requestSmsCode() async {
    final rawPhone = _codeController.text.trim();
    if (rawPhone.length != 11 || !rawPhone.startsWith('0')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir telefon numarası giriniz.'),
        ),
      );
      return;
    }

    // Firestore için yerel format (05XXXXXXXXXX)
    final phoneForFirestore = rawPhone;
    
    // Firebase Auth için uluslararası format (+905XXXXXXXXXX)
    final phoneForAuth = '+90${rawPhone.substring(1)}'; // 0'ı çıkar, +90 ekle

    setState(() {
      _isLoading = true;
      _smsCodeVerified = false;
    });

    try {
      // Firestore'da telefon numarasına göre kullanıcı arama (yerel format ile)
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneCode', isEqualTo: phoneForFirestore)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu numarayla kayıtlı kullanıcı bulunamadı!')),
        );
        return;
      }

      // Firebase Auth için uluslararası format kullan
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneForAuth, // +905XXXXXXXXXX formatı
        timeout: const Duration(seconds: 30),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            setState(() {
              _smsCodeVerified = true;
              _step = 2; // Şifre belirleme adımına geç
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('SMS kodu otomatik doğrulandı!'), backgroundColor: Colors.green),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Otomatik doğrulama başarısız: $e')),
            );
          }
        },
        verificationFailed: (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SMS gönderilemedi: ${e.message}')),
          );
        },
        codeSent: (verificationId, _) {
          _verificationId = verificationId;
          setState(() {
            _smsCodeSent = true;
          });
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS kodu gönderildi')),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifySmsCodeButtonPressed() async {
    final smsCode = _smsCodeController.text.trim();
    if (smsCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli SMS kodu giriniz')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() => _smsCodeVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS kodu doğru!'), backgroundColor: Colors.green),
      );
    } catch (_) {
      setState(() => _smsCodeVerified = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS kodu yanlış!'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_smsCodeVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce SMS kodunu doğrulayınız!')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(_passwordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw 'Kullanıcı oturumu yok';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre güncellenemedi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _smsCodeController.dispose();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Şifre Sıfırla', style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_reset, size: 64, color: Colors.white.withOpacity(0.85)),
                const SizedBox(height: 10),
                const Text(
                  'Şifreni Sıfırla',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Telefon numaranı gir, SMS ile doğrula ve yeni şifreni oluştur.',
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_step == 0) ...[
                            const Text('Telefon Numarası:', style: TextStyle(fontWeight: FontWeight.w600)),
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
                              style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              validator: (v) => (v == null || v.length != 11) ? 'Eksik telefon numarası' : null,
                              enabled: !_smsCodeSent,
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
                                onPressed: _isLoading ? null : () async {
                                  if (_formKey.currentState!.validate()) {
                                    await _requestSmsCode();
                                    if (mounted && _smsCodeSent) {
                                      setState(() { _step = 1; });
                                    }
                                  }
                                },
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('Devam', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                          if (_step == 1) ...[
                            const Text('SMS Kodu:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                TextFormField(
                                  controller: _smsCodeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    labelText: 'SMS Kodu',
                                    border: blueBorder,
                                    focusedBorder: blueBorder,
                                    enabledBorder: blueBorder,
                                    counterText: '',
                                  ),
                                  style: const TextStyle(letterSpacing: 4, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                  enabled: true,
                                ),
                                if (_smsCodeVerified)
                                  Positioned(
                                    right: 12,
                                    top: 12,
                                    child: Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () async {
                                  await _verifySmsCodeButtonPressed();
                                  if (mounted && _smsCodeVerified) {
                                    setState(() { _step = 2; });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: const Text('Devam', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                            if (_start > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '$_start saniye içinde tekrar kod isteyiniz.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                          if (_step == 2) ...[
                            const Text('Yeni Şifre:', style: TextStyle(fontWeight: FontWeight.w600)),
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
                                  icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                                ),
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              validator: _validatePassword,
                              enabled: true,
                            ),
                            const SizedBox(height: 16),
                            const Text('Yeni Şifre (Tekrar):', style: TextStyle(fontWeight: FontWeight.w600)),
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
                                  icon: Icon(_repeatPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                  onPressed: () => setState(() => _repeatPasswordVisible = !_repeatPasswordVisible),
                                ),
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Şifreyi tekrar giriniz.';
                                if (v != _passwordController.text) return 'Şifreler eşleşmiyor';
                                return null;
                              },
                              enabled: true,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[800],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading ? null : _resetPassword,
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('Şifreyi Oluştur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
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