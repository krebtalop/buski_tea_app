import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
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
      title: 'BUSKİ Çay Sipariş',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // '/home': (context) => HomeScreen(), // Ana sayfa eklenince açılacak
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
