import 'package:buski_tea_app/screens/login_screen.dart';
import 'package:buski_tea_app/screens/change_password_screen.dart'; // ✅ Şifremi değiştir sayfası eklendi
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:buski_tea_app/screens/gecmis_siparisler_screen.dart'; // GecmisSiparislerScreen eklendi

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
      // Firebase Storage entegrasyonu yoksa sadece local göster, varsa yükle ve url kaydet
      // Şimdilik Firestore'a path kaydedelim
      await _firestore.collection('users').doc(user.uid).update({'profileImage': picked.path});
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
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                // Profil Fotoğrafı + Ekle Butonu
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: _firestore.collection('users').doc(user?.uid).get(),
                  builder: (context, snapshot) {
                    String? imagePath;
                    if (snapshot.hasData) {
                      final data = snapshot.data!.data();
                      imagePath = data?['profileImage'] as String?;
                    }
                    return Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (imagePath != null && imagePath.isNotEmpty)
                                  ? FileImage(File(imagePath))
                                  : null,
                          child: (_profileImage == null && (imagePath == null || imagePath.isEmpty))
                              ? const Icon(Icons.account_circle, size: 70, color: Color(0xFF1565C0))
                              : null,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.add, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                // Kullanıcı Bilgileri Kartı (modern ve yumuşak)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  elevation: 10,
                  margin: const EdgeInsets.only(bottom: 28),
                  color: Colors.white.withOpacity(0.96),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                    child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: _firestore.collection('users').doc(user?.uid).get(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              user?.email ?? 'Kullanıcı',
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                              textAlign: TextAlign.center,
                            ),
                            if (data != null && data['name'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0, bottom: 8),
                                child: Text('${data['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                            Divider(height: 22, thickness: 1, color: Colors.blue[50]),
                            if (data != null && data['phoneCode'] != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.phone, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('${data['phoneCode']}', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                                ],
                              ),
                            if (data != null && data['department'] != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.business, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('${data['department']}', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                                ],
                              ),
                            if (data != null && data['floor'] != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('Kat: ${data['floor']}', style: const TextStyle(fontSize: 15, color: Colors.black87)),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // Butonlar
                Column(
                  children: [
                    _buildProfileButton(
                      text: 'Geçmiş Siparişlerim',
                      icon: Icons.history,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GecmisSiparislerScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
                    _buildProfileButton(
                      text: 'Çıkış Yap',
                      icon: Icons.exit_to_app,
                      onPressed: _logout,
                    ),
                    const SizedBox(height: 14),
                    _buildProfileButton(
                      text: 'Hesabı Sil',
                      icon: Icons.delete_forever,
                      onPressed: _deleteAccount,
                      isDestructive: true,
                    ),
                  ],
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
