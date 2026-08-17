# İnci Gıda - Depo / Ürün / Kasa Takip Uygulaması

Tamamen **yerel** çalışan bir Flutter uygulaması. İnternet, sunucu veya başka bir
kullanıcı yok — tüm veriler telefonun kendi dosya sisteminde tek bir SQLite
dosyasında (`inci_gida.db`) tutulur. Uygulama silinirse veya "uygulama verilerini
temizle" yapılırsa bu veri de silinir; başka bir yedekleme yoktur.

## Modüller (Excel'deki karşılığı)

| Ekran | Excel'deki karşılığı |
|---|---|
| **Ürünler** | "Ürünler" sayfası — kod, ad, alış/satış fiyatı, kâr TL / kâr % (otomatik hesaplanır) |
| **Depolar** | "Kavakdibi Depo", "Amasya Depo", "28 TB 509" sayfaları — istediğiniz kadar depo ekleyebilirsiniz |
| **Genel Toplam** | "Genel Toplam" sayfası — tüm depolardaki stokların ürün bazında toplamı |
| **Kasa** | "Ağustos Kasa" sayfası — tarih, kalem adı (Yakıt, Yemek Gideri, Nakit, Visa vb.), gelir/gider |

Bir depo, içine eklediğiniz ürünleri gösterir — henüz eklenmemiş ürünler o
depo listesinde görünmez. Depo ekranındaki **"+"** butonuyla Ürünler
kataloğundan seçim yapıp miktar girerek ürünleri o depoya eklersiniz (sayım
yaparken pratik olması içindir). Bir ürünün miktarını "0" yapmak/`Depodan
Çıkar` demek, o ürünü depo listesinden kaldırır — ürün kataloğundan silmez.

## Excel'e Aktar / Yedek Al-Geri Yükle (yeni)

Uygulamanın 5. sekmesi olan **Ayarlar**'da dört işlem var:

- **Excel'e Aktar** — tüm ürün/depo/kasa verisini, orijinal Excel dosyanızdaki gibi
  her depo kendi sayfasında olacak şekilde bir `.xlsx` dosyasına yazar, ardından
  telefonun paylaşım menüsünü açar (Drive'a kaydet, WhatsApp/e-posta ile gönder vb.)
- **Excel'den İçe Aktar** — bu uygulamanın ürettiği (veya aynı sayfa/sütun
  düzenindeki) bir `.xlsx` dosyasından ürün, depo-stok ve kasa verisi okuyup
  mevcut veriyle birleştirir (ürünler kod/isimle eşleştirilip güncellenir)
- **Yedek Al** — tüm veritabanını tek bir `.json` dosyasına birebir yedekler ve
  paylaşım menüsünü açar
- **Yedekten Geri Yükle** — seçtiğiniz `.json` yedek dosyasıyla mevcut tüm veriyi
  değiştirir (onay ister, geri alınamaz)

**Fark:** JSON yedek dosyası veriyi birebir/kayıpsız saklar (asıl yedekleme
yöntemi budur); Excel dışa aktarımı ise veriyi Excel'de görüntülemek/düzenlemek
içindir, biçimlendirme taşımaz.

### Ürün listenizin uygulamayla birlikte gelmesi

126 ürününüz ve 3 depo isminiz (`28TB509`, `AMASYA`, `OFİS`) artık uygulamanın
içine **önceden yüklenmiş** olarak gömülü — kurulumdan hemen sonra Ürünler ve
Depolar sekmelerinde hazır göreceksiniz, elle içe aktarma yapmanıza gerek yok.

**Önemli — eğer telefonunuzda bu uygulamanın eski bir sürümü zaten kuruluysa:**
Bu "hazır yükleme" sadece uygulama **ilk kez** açıldığında, telefonda henüz
`inci_gida.db` dosyası yokken çalışır. Eski sürümü kaldırıp yenisini kurarsanız
sorun olmaz (eski verileriyle birlikte dosya da silinir, yenisi ilk açılışta
hazır verilerle oluşur). Ama **yeni APK'yı eskisinin üzerine kurarsanız**
(kaldırmadan), telefonda zaten bir `inci_gida.db` dosyası bulunduğu için hazır
veri kopyalanmaz, eski/boş veriniz öylece kalır. Bu durumda:
- Temiz kurulum istiyorsanız: eski uygulamayı **kaldırıp** yeni APK'yı kurun
  (o ana kadar girdiğiniz veri varsa önce Ayarlar > Yedek Al ile yedekleyin)
- Veya elinizdeki veriyi korumak istiyorsanız: Ayarlar > Excel'den İçe Aktar
  ile aynı Excel dosyasını içe aktarın (üzerine yazmaz, kod eşleşenleri günceller)

### Ek Excel içe aktarımı (fiyatlar girildikten sonra)



## Gereksinimler

- Flutter SDK (3.x) kurulu bir bilgisayar — https://docs.flutter.dev/get-started/install
- Android Studio veya bağlı bir Android telefon / emülatör (iOS için Mac + Xcode gerekir)

## Çalıştırma

```bash
cd inci_gida_app
flutter create .   # eksik android/ios platform klasörlerini oluşturur, lib/ ve pubspec.yaml'a dokunmaz
flutter pub get
flutter run
```

`flutter create .` adımı **şart** — bu proje bana sadece Dart/pubspec dosyaları
olarak teslim edildi (bu ortamda `flutter create` çalıştıracak Flutter SDK'sı
yoktu), Android/iOS'un kendi platform klasörleri (Gradle dosyaları,
AndroidManifest.xml vb.) eksik. `flutter create .` var olan bir klasörde
çalıştırıldığında sadece eksik dosyaları ekler, `lib/` içeriğinizi SİLMEZ.

Telefonu USB ile bağlayıp "Geliştirici Seçenekleri > USB Hata Ayıklama"yı açtıysanız
`flutter run` doğrudan telefonunuzda çalıştırır.

## APK'yı bilgisayarınızda üretmek

```bash
flutter build apk --release
```

Oluşan dosya: `build/app/outputs/flutter-apk/app-release.apk`. Bu dosyayı telefona
kopyalayıp kurduğunuzda "bilinmeyen kaynaklardan yükleme" izni istenebilir —
Play Store'a yüklemediğiniz için bu normaldir, sadece kendi telefonunuzda çalışır.

## APK'yı Flutter kurmadan, bulutta üretmek (GitHub Actions)

Bilgisayarınıza Flutter kurmak istemiyorsanız, projeye eklediğim
`.github/workflows/build_apk.yml` dosyası bunu sizin için bulutta yapar:

1. https://github.com adresinde ücretsiz bir hesap açın (yoksa)
2. Yeni bir repo oluşturun (private/gizli olabilir)
3. Bu klasörün tüm içeriğini o repoya yükleyin (GitHub web arayüzünden
   "Add file > Upload files" ile sürükle-bırak da yeterli)
4. Repo sayfasında **Actions** sekmesine girin, "APK Oluştur" iş akışını görün,
   gerekirse **Run workflow** butonuna basıp elle başlatın
   (branch adınız `main` ise dosya push edildiğinde zaten otomatik başlar)
5. İşlem bitince (birkaç dakika sürer) o çalıştırmanın sayfasında
   **Artifacts** bölümünden `inci-gida-apk` dosyasını indirin — içinde
   `app-release.apk` var, onu telefonunuza kopyalayıp kurabilirsiniz

## Önemli not — bu ortamda test edilemedi

Bu kod, Anthropic'in bu konuşmayı yürüttüğü sunucuda **Flutter SDK kurulu
olmadığı ve flutter.dev/pub.dev/GitHub Actions gibi adreslere ağ erişimi
olmadığı için** derlenip çalıştırılarak doğrulanamadı. Kod mantığı ve
Flutter/Dart söz dizimi dikkatlice yazıldı, ama şu iki nokta en riskli yerler:

1. `excel` paketinin hücre okuma/yazma API'si sürümden sürüme değişiyor
   (`lib/services/excel_service.dart` içinde bunu esnek tutmaya çalıştım
   ama garanti edemem)
2. `pubspec.yaml`'daki paket sürüm numaraları (`excel: ^4.0.6`,
   `file_picker: ^8.1.2`, `share_plus: ^10.0.0`) güncel olmayabilir

`flutter pub get` ya da derleme sırasında hata alırsanız, hata mesajını
bana yapıştırın — dakikalar içinde düzeltirim.

## Veritabanı dosyasının konumu (Android)

`/data/data/<paket_adi>/databases/inci_gida.db` — root olmayan bir telefonda
bu dosyaya normal şartlarda erişemezsiniz, veri taşımak için yukarıdaki
"Yedek Al" özelliğini kullanın.
