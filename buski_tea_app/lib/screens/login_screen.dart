import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buski_tea_app/screens/order_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:math';
import 'package:buski_tea_app/screens/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final List<String> _sentences = [
    'Çayınız demli mi olsun, demsiz mi?',
    'Çalışırken bi kahve molası fena mı olur?',
    'Yoğun tempoya küçük bir tebessüm molası.',
    'Mesain en güzel demlikçisi taze demlenmiş bir bardak çay.',
    'Hayat kısa, çaylar demli!',
  ];
  late final String _randomSentence;

  @override
  void initState() {
    super.initState();
    _randomSentence = _sentences[Random().nextInt(_sentences.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 4,
            ), // 28 ve 16 yerine daha az
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start, // üstte başlasın
                children: [
                  const SizedBox(height: 0), // üstte boşluk bırakma
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 160,
                        ), // 120 yerine 160
                        const SizedBox(height: 6), // 12 yerine 6
                        // AnimatedTextKit ile animasyonlu yazı
                        Container(
                          constraints: const BoxConstraints(
                            maxWidth: 320,
                            minHeight: 40,
                          ),
                          alignment: Alignment.center,
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            child: AnimatedTextKit(
                              isRepeatingAnimation: false,
                              totalRepeatCount: 1,
                              animatedTexts: [
                                TyperAnimatedText(
                                  _randomSentence,
                                  speed: const Duration(milliseconds: 90),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              displayFullTextOnTap: true,
                              pause: Duration.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10), // 18 yerine 10
                      ],
                    ),
                  ),
                  // Logo ve animasyonlu yazıdan sonra
                  const SizedBox(
                    height: 40,
                  ), // Logo ve animasyonlu yazıdan sonra daha fazla boşluk
                  Text(
                    'Giriş Yap',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 12,
                  ), // Giriş Yap ile telefon kodu arası daha yakın
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    decoration: const InputDecoration(
                      labelText: 'Telefon numaranızı giriniz.',
                      hintText: 'örn: 05XXXXXXXXX',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    style: const TextStyle(
                      letterSpacing: 4,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    validator: (value) {
                      if (value == null || value.length != 11) {
                        return 'Telefon Numaranızı giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      border: const OutlineInputBorder(),
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
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[800],
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Şifreni mi unuttun?'),
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
