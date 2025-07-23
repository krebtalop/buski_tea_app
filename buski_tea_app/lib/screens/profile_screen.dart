import 'package:buski_tea_app/screens/login_screen.dart';
import 'package:buski_tea_app/screens/change_password_screen.dart'; // ✅ Şifremi değiştir sayfası eklendi
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Çıkış yapma fonksiyonu
  Future<void> _logout() async {
    bool? confirmed = await _showConfirmationDialog(
      title: 'Çıkış Onayı',
      content: 'Çıkış yapmak istediğinizden emin misiniz?',
    );

    if (confirmed == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  // Hesap silme fonksiyonu
  Future<void> _deleteAccount() async {
    bool? confirmed = await _showConfirmationDialog(
      title: 'Hesap Silme Onayı',
      content:
          'Hesabınızı kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
    );

    if (confirmed != true) return;

    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Önce Firestore'dan kullanıcı verilerini sil
      await _firestore.collection('users').doc(user.uid).delete();

      // Sonra Firebase Authentication'dan kullanıcıyı sil
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesabınız başarıyla silindi.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showErrorDialog(
          'Bu işlem için yeniden giriş yapmanız gerekiyor. Lütfen çıkış yapıp tekrar giriş yaptıktan sonra tekrar deneyin.',
        );
      } else {
        _showErrorDialog('Hesap silinirken bir hata oluştu: ${e.message}');
      }
    } catch (e) {
      _showErrorDialog('Beklenmedik bir hata oluştu: $e');
    }
  }

  // Onay dialogu gösterme
  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }

  // Hata dialogu gösterme
  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hata'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFFB3E5FC)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: MediaQuery.of(context).size.width * 0.4,
                ),
                const SizedBox(height: 50),
                _buildProfileButton(
                  text: 'Geçmiş Siparişlerim',
                  icon: Icons.history,
                  onPressed: () {
                    // TODO: Geçmiş siparişler sayfasına yönlendirme eklenecek
                  },
                ),
                const SizedBox(height: 16),
                _buildProfileButton(
                  text: 'Şifremi Değiştir',
                  icon: Icons.lock_outline,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildProfileButton(
                  text: 'Çıkış Yap',
                  icon: Icons.exit_to_app,
                  onPressed: _logout,
                ),
                const SizedBox(height: 16),
                _buildProfileButton(
                  text: 'Hesabı Sil',
                  icon: Icons.delete_forever,
                  onPressed: _deleteAccount,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: isDestructive ? Colors.red[700] : Colors.white,
      foregroundColor: isDestructive ? Colors.white : Colors.blue[800],
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.2),
    );

    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(text),
      onPressed: onPressed,
      style: style,
    );
  }
}
