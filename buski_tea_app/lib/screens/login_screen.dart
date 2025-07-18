import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buski_tea_app/screens/order_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Image.asset('assets/images/logo.png', width: 180),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 300,
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            child: AnimatedTextKit(
                              repeatForever: true,
                              animatedTexts: [
                                TyperAnimatedText(
                                  'Çayınız demli mi olsun, demsiz mi?',
                                ),
                                TyperAnimatedText(
                                  'Çalışırken bi kahve molası fena mı olur?',
                                ),
                                TyperAnimatedText(
                                  'Yoğun tempoya küçük bir tebessüm molası.',
                                ),
                                TyperAnimatedText(
                                  'Mesain en güzel demlikçisi taze demlenmiş bir bardak çay.',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  Text(
                    'Giriş Yap',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'BUSKİ telefon kodu',
                      hintText: 'örn: 1234',
                      helperText: '4 haneli BUSKİ telefon kodunuzu giriniz',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    style: const TextStyle(
                      letterSpacing: 4,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    validator: (value) {
                      if (value == null || value.length != 4) {
                        return '4 haneli kod giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Şifre',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre giriniz';
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
                          final code = _codeController.text;
                          final email = '$code@buski.com';
                          final password = _passwordController.text;
                          try {
                            final auth = FirebaseAuth.instance;
                            await auth.signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Giriş başarılı!')),
                            );
                            // TODO: Ana sayfaya yönlendirme burada yapılacak
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const OrderScreen(),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            String msg = 'Giriş başarısız';
                            if (e.code == 'user-not-found' ||
                                e.code == 'wrong-password') {
                              msg = 'Telefon kodu veya şifre hatalı!';
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
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[800],
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Üye değil misiniz? Kayıt olun'),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
