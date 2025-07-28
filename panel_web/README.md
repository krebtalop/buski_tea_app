# Buski Çay Ocağı Sipariş Paneli

Bu Flutter uygulaması, Buski Çay Ocağı için sipariş takip ve yönetim panelidir. Orijinal HTML/JavaScript uygulaması Flutter'a çevrilmiştir.

## Özellikler

- **Gerçek Zamanlı Sipariş Takibi**: Firebase Firestore ile gerçek zamanlı sipariş güncellemeleri
- **Kat Bazlı Organizasyon**: 10 kat için ayrı ayrı sipariş kartları
- **Durum Yönetimi**: Siparişleri hazırlanıyor → hazırlandı → teslim edildi durumları arasında geçiş
- **Menü Yönetimi**: Ürün ekleme, düzenleme ve silme
- **Bildirim Sistemi**: Yeni sipariş geldiğinde ses bildirimi
- **Responsive Tasarım**: Mobil ve masaüstü uyumlu arayüz

## Kurulum

### Gereksinimler

- Flutter SDK (3.8.1 veya üzeri)
- Dart SDK
- Firebase projesi

### Adımlar

1. **Projeyi klonlayın:**
   ```bash
   git clone <repository-url>
   cd panel_web
   ```

2. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

3. **Firebase yapılandırması:**
   - Firebase Console'da yeni bir proje oluşturun
   - Firestore Database'i etkinleştirin
   - Web uygulaması ekleyin ve yapılandırma bilgilerini alın
   - `lib/main.dart` dosyasındaki Firebase yapılandırmasını güncelleyin

4. **Uygulamayı çalıştırın:**
   ```bash
   # Web için
   flutter run -d chrome
   
   # Mobil için
   flutter run
   ```

## Kullanım

### Ana Ekran
- **Hazırlananlar Sekmesi**: Henüz teslim edilmemiş siparişleri gösterir
- **Teslim Edilenler Sekmesi**: Tamamlanmış siparişleri gösterir
- **Kat Kartları**: Her kat için ayrı sipariş listesi

### Sipariş Yönetimi
1. Sipariş durumunu değiştirmek için butona tıklayın
2. Durumlar: Hazırlanıyor → Hazırlandı → Teslim Edildi
3. Teslim edilen siparişleri silebilirsiniz

### Menü Yönetimi
- Sağ alt köşedeki menü butonuna tıklayın
- Ürünleri görüntüleyin, düzenleyin veya silin
- Yeni ürün ekleyin

## Firebase Yapısı

### Collections

#### `siparisler`
```json
{
  "id": "auto-generated",
  "ad": "Müşteri Adı",
  "departman": "Departman Adı",
  "floor": "3",
  "tarih": "timestamp",
  "items": [
    {
      "name": "Çay",
      "option": "Şekersiz",
      "adet": 2
    }
  ],
  "toplamFiyat": 4.0,
  "status": "hazırlanıyor"
}
```

#### `menu`
```json
{
  "items": [
    {
      "name": "Çay",
      "price": 2.0,
      "options": ["Şekersiz", "Şekerli"],
      "defaultOption": "Şekersiz"
    }
  ]
}
```

## Teknolojiler

- **Flutter**: UI framework
- **Firebase Firestore**: Veritabanı
- **AudioPlayers**: Ses bildirimleri
- **Intl**: Tarih formatlaması

## Geliştirme

### Proje Yapısı
```
lib/
├── main.dart              # Ana uygulama dosyası
web/
├── index.html             # Web yapılandırması
├── manifest.json          # PWA manifest
└── icons/                 # Uygulama ikonları
```

### Özelleştirme

#### Renkler
Ana renkler `lib/main.dart` dosyasında tanımlanmıştır:
- Primary: `#2563EB` (Mavi)
- Success: `#16A34A` (Yeşil)
- Warning: `#F59E0B` (Turuncu)
- Danger: `#DC2626` (Kırmızı)

#### Menü Öğeleri
Varsayılan menü öğeleri `defaultMenu` listesinde tanımlanmıştır.

## Dağıtım

### Web
```bash
flutter build web
```

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## İletişim

Sorularınız için: [email@example.com]
