import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/order_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/order_panel_screen.dart';
import 'screens/forgot_password_screen.dart';
// TODO: Ana sayfa için HomeScreen eklenince import edilecek

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Çay Ocağı',
      debugShowCheckedModeBanner: false,
      initialRoute: '/uygulama', // '/panel' veya '/uygulama' olarak değiştir
      routes: {
        '/uygulama': (context) => const OrderScreen(),
        '/panel': (context) => OrderPanelScreen(),
        '/register': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/profile': (context) => ProfileScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
      },

      home: const AuthGate(),
      theme: ThemeData(fontFamily: 'SourceSansPro'),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // Kullanıcı giriş yapmışsa ana ekrana yönlendir
          return const OrderScreen();
        } else {
          // Giriş yoksa login ekranına yönlendir
          return const LoginScreen();
        }
      },
    );
  }
}

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  Future<void> sendOrder() async {
    try {
      print("SİPARİŞ GÖNDERİLİYOR...");
      await FirebaseFirestore.instance.collection('siparisler').add({
        'icecek': 'Çay',
        'adet': 2,
        'tarih': Timestamp.now(),
      });
      print("✅ SİPARİŞ BAŞARIYLA GÖNDERİLDİ!");
    } catch (e) {
      print("🔥 HATA: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Sipariş Gönder')),
      body: Center(
        child: ElevatedButton(
          onPressed: sendOrder,
          child: const Text("Test Siparişi Gönder"),
        ),
      ),
    );
  }
}
