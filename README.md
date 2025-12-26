# Flutter Alarm Uygulaması

Kullanıcıyı tek seferde uyandırmak için tasarlanmış, modern ve görev odaklı bir alarm uygulaması. **Erteleme tuşu içermeyen** yapısı ve uyanma görevleriyle klasik alarm uygulamalarından ayrılır. Uygulamanın amacı sadece uyandırmak değil; aynı zamanda güne zihinsel olarak hazır başlamanızı sağlamaktır.

## Özellikler

- **Alarm Yönetimi:** Tek seferlik veya haftanın belirli günleri için tekrar eden alarmlar oluşturun, düzenleyin ve silin.
- **Özelleştirilebilir Ses:** Cihaz hafızasından kendi alarm sesinizi seçin.
- **Uyanma Görevleri:** Alarmı kapatmak için kullanıcıyı zihinsel olarak aktif hâle getiren zorunlu mini görevler:
  - **Hafıza Oyunu:** Belirlenen süre içinde yanan kareleri ezberleyip doğru şekilde bulun.
  - **Yazı Yazma Görevi:** Ekranda çıkan motivasyon cümlelerini hatasız bir şekilde yeniden yazın.
- **Flutter - Native Entegrasyonu:** Android alarm yöneticisi, doğrudan native (Kotlin) kod ile entegre çalışarak güvenilir bir şekilde alarmı tetikler.
- **Tam Ekran Alarm ve Kilit Ekranı Desteği:** Alarm çaldığında, uygulama kapalı veya kilitli olsa bile ekranı uyandırır ve tam ekran olarak alarm görevini başlatır.
- **Firebase Authentication:** Kullanıcıların e-posta ve şifre ile güvenli bir şekilde kaydolmasını ve giriş yapmasını sağlar.
- **Motivasyon Modülü:** Uygulama içinden görüntülenebilen ve eklenebilen kişisel motivasyon cümleleri.
- **Uyku Farkındalığı Modülü:** Uyku kalitesini artırmaya yönelik bilimsel bilgiler, biyolojik döngüler (REM, derin uyku) ve pratik öneriler içerir.
- **İzin Yönetimi:** Alarmın sorunsuz çalışabilmesi için gerekli olan Android izinlerini (bildirim, tam ekran gösterme vb.) başlangıçta kontrol eder ve kullanıcıyı yönlendirir.

## Kullanılan Teknolojiler

- **Flutter & Dart** -UI ve iş mantığı
- **Kotlin** -Native Android alarm servisi, broadcast receiver ve tam ekran activity için
- **Firebase Authentication**
- **Provider**
- **Shared Preferences**
- **Flutter Local Notifications**
- **Permission Handler**
- **MethodChannel** -Kotlin ile iletişim için

## Proje Yapısı

Proje, yeniden kullanılabilirlik ve sürdürülebilirlik için modüler bir mimariyle tasarlandı. Ana dizinler ve sorumlulukları:

- **`lib/`**: Dart kodlarının bulunduğu ana dizin.
  - **`main.dart`**: Uygulamanın başlangıç noktası. Tema, yollar (routes) ve native kanal dinleyicisi burada yapılandırılır.
  - **`auth/`**: Firebase Authentication ile ilgili tüm mantığı (kayıt, giriş, durum yönetimi) içerir.
  - **`data/`**: Uygulamanın veri katmanıdır. `alarm_model.dart` (veri modeli), `alarm_repository.dart` (veri işlemleri) ve `alarm_storage.dart` (lokal depolama) dosyalarını barındırır.
  - **`games/`**: Alarmı kapatmak için kullanılan görev/oyun ekranlarını içerir (`grid_memory_game_page.dart`, `motivation_typing_page.dart`).
  - **`presentation/`**: Kullanıcı arayüzü katmanıdır.
    - `screens/`: Uygulamanın ana ekranlarını (`alarm_home_page.dart`, `main_shell.dart`) içerir.
    - `widgets/`: Birden fazla ekranda kullanılan ortak widget'ları (`alarm_edit_dialog.dart`) barındırır.
  - **`screens/`**: Farkındalık, izinler gibi daha statik veya tekil ekranları içerir.
  - **`services/`**: Native kod (Kotlin) ile iletişimi sağlayan `native_channel_service.dart` gibi servisleri içerir.
  - **`theme/`**: Uygulamanın renk paleti (`app_colors.dart`) ve genel teması gibi stil dosyalarını barındırır.

## Ekran Görüntüleri

### Ana Sayfa
![Ana Sayfa](screenshots/1_home.jpg)

### Motivasyon Ekleme
![Motivasyon Ekleme](screenshots/2_add_motivations.jpg)

### Farkındalık Listesi
![Farkındalıklar](screenshots/3_awarenesses.jpg)

### Farkındalık Detayı
![Farkındalık Detay](screenshots/4_awareness_details.jpg)

### Hafıza Oyunu
![Hafıza Oyunu](screenshots/5_memory_game.jpg)

### Motivasyon Yazma Görevi
![Yazı Görevi](screenshots/6_motivation_typing.jpg)

## Kurulum

1.  Yeni bir Firebase projesi oluşturun ve projenize Android uygulamasını ekleyin.
2.  Firebase konsolundan `google-services.json` dosyasını indirin ve projenizin `android/app/` dizinine kopyalayın.
3.  Bir terminalde `flutter pub get` komutunu çalıştırarak bağımlılıkları yükleyin.
4.  Uygulamayı bir Android cihaz veya emülatör üzerinde `flutter run` komutu ile başlatın.

---

## Hazırlayan: Hüseyin Erekmen
- https://github.com/husoelrey
- https://www.linkedin.com/in/huseyinerekmen/