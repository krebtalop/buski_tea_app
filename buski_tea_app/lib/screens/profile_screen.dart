import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'package:buski_tea_app/screens/login_screen.dart';
import 'package:buski_tea_app/screens/gecmis_siparisler_screen.dart';
import 'package:buski_tea_app/screens/change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _floorController = TextEditingController();
  final _emailController = TextEditingController();

  bool _hasChanges = false;
  bool _isLoading = false;

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
      await _firestore.collection('users').doc(user.uid).delete();
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
    
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Daha düşük kalite
      maxWidth: 400, // Daha küçük boyut
      maxHeight: 400,
    );
    
    if (picked != null) {
      try {
        // Loading göster
        setState(() {
          _isLoading = true;
        });

        // Resmi Base64'e çevir
        final bytes = await picked.readAsBytes();
        
        // Boyut kontrolü (800KB limit)
        if (bytes.length > 800 * 1024) {
          throw Exception('Resim boyutu çok büyük. Lütfen daha küçük bir resim seçin.');
        }
        
        final base64String = base64Encode(bytes);
        final mimeType = _getMimeType(picked.path);
        final dataUrl = 'data:$mimeType;base64,$base64String';

        // Firestore'a kaydet
        await _firestore.collection('users').doc(user.uid).update({
          'profileImage': dataUrl,
          'profileImageUpdatedAt': FieldValue.serverTimestamp(),
        });

        // UI'yi güncelle
        setState(() {
          _profileImage = File(picked.path);
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil fotoğrafı başarıyla güncellendi!')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Resim yüklenirken hata oluştu: $e')),
          );
        }
      }
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

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

  void _openEditDialog(Map<String, dynamic> userData) {
    _emailController.text = _auth.currentUser?.email ?? '';
    _nameController.text = userData['name'] ?? '';
    _surnameController.text = userData['surname'] ?? '';
    _departmentController.text = userData['department'] ?? '';
    _floorController.text = userData['floor']?.toString() ?? '';
    _hasChanges = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bilgileri Düzenle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'E-posta',
                    _emailController,
                    false,
                    setModalState,
                  ),
                  _buildTextField(
                    'Kullanıcı Adı',
                    _nameController,
                    true,
                    setModalState,
                  ),
                  _buildTextField(
                    'Soyadı',
                    _surnameController,
                    true,
                    setModalState,
                  ),
                  _buildTextField(
                    'Departman',
                    _departmentController,
                    true,
                    setModalState,
                  ),
                  _buildTextField(
                    'Kat',
                    _floorController,
                    false,
                    setModalState,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: !_hasChanges
                        ? null
                        : () async {
                            final uid = _auth.currentUser?.uid;
                            if (uid != null) {
                              await _firestore
                                  .collection('users')
                                  .doc(uid)
                                  .update({
                                    'name': _nameController.text.trim(),
                                    'surname': _surnameController.text.trim(),
                                    'department': _departmentController.text.trim(),
                                    'floor': _floorController.text.trim(),
                                  });
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Kullanıcı bilgileri düzenlendi.',
                                  ),
                                  backgroundColor: Colors.green[400],
                                ),
                              );
                              setState(() {}); // Refresh UI
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      disabledBackgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Düzenle'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool editable,
    void Function(void Function()) setModalState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: editable,
        onChanged: (_) => setModalState(() => _hasChanges = true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
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
                // Profil Fotoğrafı
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: _firestore.collection('users').doc(user?.uid).get(),
                  builder: (context, snapshot) {
                    String? imageData;
                    if (snapshot.hasData) {
                      final data = snapshot.data!.data();
                      imageData = data?['profileImage'] as String?;
                    }
                    return Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (imageData != null && imageData.isNotEmpty && imageData.startsWith('data:image'))
                              ? MemoryImage(base64Decode(imageData.split(',')[1]))
                              : null,
                          child:
                              (_profileImage == null &&
                                  (imageData == null || imageData.isEmpty || !imageData.startsWith('data:image')))
                              ? const Icon(
                                  Icons.account_circle,
                                  size: 70,
                                  color: Color(0xFF1565C0),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _pickProfileImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isLoading ? Colors.grey : Colors.blue[700],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Kullanıcı Bilgileri Kartı
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: _firestore.collection('users').doc(user?.uid).get(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data();
                    return Stack(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          elevation: 10,
                          margin: const EdgeInsets.only(bottom: 28),
                          color: Colors.white.withOpacity(0.96),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 26,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  user?.email ?? 'Kullanıcı',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (data != null && data['name'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 2.0,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      data['surname'] != null && data['surname'].toString().isNotEmpty
                                        ? '${data['name']} ${data['surname']}'
                                        : '${data['name']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                Divider(
                                  height: 22,
                                  thickness: 1,
                                  color: Colors.blue[50],
                                ),
                                if (data != null && data['phoneCode'] != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${data['phoneCode']}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (data != null && data['department'] != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.business,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${data['department']}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (data != null && data['floor'] != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Kat: ${data['floor']}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 44,
                          right: 24,
                          child: GestureDetector(
                            onTap: () {
                              if (data != null) _openEditDialog(data);
                            },
                            child: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 18,
                              child: Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Butonlar
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