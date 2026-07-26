# App Store'a Çıkış — Adım Adım

ShitTimer V1 için yayın rehberi. Sıra önemli: 0 → 12.

---

## 0. Ön koşullar (bunlar olmadan hiçbir adım ilerlemez)

1. **Apple Developer Program üyeliği** — yıllık 99 USD, [developer.apple.com/programs](https://developer.apple.com/programs/). Bireysel üyelikte onay genelde 24-48 saat, bazen kimlik doğrulaması istenir.
2. **Paid Applications Agreement** — App Store Connect → Business (İş) bölümünden sözleşmeyi kabul et, **banka hesabı ve vergi bilgilerini** gir. Uygulama ücretsiz olsa bile **uygulama içi satın alma için bu şart**; eksikse IAP ürünün "Waiting for Agreement" durumunda takılır ve satış yapılamaz.
3. Bu adım günler alabildiği için **en başta başlat**.

---

## 1. İsim kararı (ilk verilmesi gereken karar)

Mağaza adı `ShitTimer` ile gidersen App Store Review Guidelines **1.1.1 (Objectionable Content)** kapsamında reddedilme veya 17+ yaş sınırı riski var. Spec'teki plan geçerli:

- **Güvenli yol (önerilen):** Mağaza adı **"Sit Happens"**, alt başlık mizahı taşır (ör. "Tuvalet sayacı, dürten türden"). Uygulama içi ton ve sosyal medyada ShitTimer kullanmaya devam edersin.
- **Riskli yol:** `ShitTimer` ile başvur, reddedilirse ada itiraz etmeden "Sit Happens"a çevir. Ret, incelemeyi baştan başlatır ve birkaç gün kaybettirir.

Karar ne olursa olsun **Bundle ID değişmez**: `com.busegenc.shittimer`. Mağaza adı ile bundle ID'nin farklı olması tamamen normaldir.

> Not: Projede görünen ad şu an `ShitTimer`. "Sit Happens" ile gidersen `INFOPLIST_KEY_CFBundleDisplayName` değerini değiştir (ana ekranda telefonun altında yazan isim budur).

---

## 2. Bundle ID'yi kaydet

[developer.apple.com/account](https://developer.apple.com/account) → Certificates, Identifiers & Profiles → **Identifiers** → `+`

- Tür: **App IDs → App**
- Description: `ShitTimer`
- Bundle ID: **Explicit** → `com.busegenc.shittimer`
- Capabilities: ekstra bir şey seçmene gerek yok (In-App Purchase varsayılan olarak açıktır; uygulama push, konum, HealthKit kullanmıyor)

---

## 3. Xcode'da imzalama

`ShitTimer.xcodeproj` → hedefi seç → **Signing & Capabilities**:

- **Automatically manage signing** işaretli
- **Team**: Developer Program hesabın
- Bundle Identifier: `com.busegenc.shittimer`

Sonra üst çubuktan cihaz olarak **Any iOS Device (arm64)** seç. (Simülatör seçiliyken Archive menüsü pasif kalır.)

---

## 4. Sürüm ve derleme numarası

- `MARKETING_VERSION` = **1.0** (kullanıcıya görünen sürüm)
- `CURRENT_PROJECT_VERSION` = **1** (build numarası)

Kural: App Store Connect'e yüklediğin **her** derlemenin build numarası bir öncekinden büyük olmalı. Aynı 1.0 sürümünü tekrar yüklerken build'i 2, 3... diye artır.

---

## 5. App Store Connect'te uygulamayı oluştur

[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → `+` → **New App**

| Alan | Değer |
|---|---|
| Platforms | iOS |
| Name | `Sit Happens` (veya kararın) — mağazada görünen ad, 30 karakter sınırı |
| Primary Language | Turkish (uygulama TR/EN destekliyor; ikisini de yerelleştirebilirsin) |
| Bundle ID | `com.busegenc.shittimer` |
| SKU | serbest, ör. `SHITTIMER001` (kullanıcı görmez) |
| User Access | Full Access |

---

## 6. Uygulama içi satın almayı tanımla

App Store Connect → uygulaman → **Monetization → In-App Purchases** → `+`

| Alan | Değer |
|---|---|
| Type | **Non-Consumable** (tek seferlik, abonelik değil) |
| Reference Name | `Theme Pack` |
| Product ID | **`com.busegenc.shittimer.themepack`** — koddaki değerle birebir aynı olmak zorunda |
| Fiyat | Türkiye ve diğer ülkeler için fiyat kademesini seç |

Ardından zorunlu alanlar:

- **Localization** (TR ve EN): görünen ad "Tema Paketi" / "Theme Pack", açıklama "Arcade ve Pastel temalarının kilidini açar."
- **Review Screenshot**: satın alma ekranının görüntüsü. Depodaki paywall ekran görüntüsünü kullanabilirsin.
- **Review Notes**: "Ücretsiz temaya ek olarak iki görsel tema açar. Abonelik yok."

⚠️ İlk sürümde IAP, uygulamayla **birlikte** incelemeye girer: sürüm sayfasındaki In-App Purchases bölümünden ürünü **bu sürüme ekle**. Eklemezsen uygulama onaylanır ama satın alma çalışmaz.

---

## 7. Ekran görüntüleri ve mağaza metinleri

**Zorunlu boyut: 6.9 inç iPhone** (1290×2796 veya 1320×2868). Elimizdeki görüntüler iPhone 16 (1179×2556, 6.1") — bunlar tek başına yeterli değil. Uygun simülatörle yeniden al:

```bash
xcrun simctl create "iPhone 16 Pro Max" com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro-Max com.apple.CoreSimulator.SimRuntime.iOS-18-2
```

En az 3, en fazla 10 görüntü. Önerilen sıra: ① çalışan sayaç + laf kartı, ② 30+ dakika uyarısı, ③ istatistik ekranı, ④ üç tema, ⑤ paywall.

Doldurulacak metinler:

- **Subtitle** (30 karakter): ör. "Tuvalette geçen süre, sayılı"
- **Promotional Text** (170), **Description** (4000), **Keywords** (100 karakter, virgülle): `tuvalet,sayaç,timer,mizah,sağlık,hatırlatıcı`
- **Support URL** — **zorunlu**. Basit bir GitHub Pages sayfası veya repo README'si yeter.
- **Privacy Policy URL** — **zorunlu**. Uygulama veri toplamıyor; "hiçbir veri toplanmaz, tüm veriler cihazda kalır" diyen tek sayfalık bir metin yeterli.

---

## 8. Gizlilik ve yaş derecelendirmesi

**App Privacy** (App Store Connect → Privacy): "**Data Not Collected**" seç. Uygulama sunucuya hiçbir şey göndermiyor; sayaç ve istatistikler cihazda `UserDefaults` içinde kalıyor. Bu beyan koddaki [PrivacyInfo.xcprivacy](ShitTimer/PrivacyInfo.xcprivacy) ile tutarlı.

**Age Rating** anketi: Kaba mizah/küfür sorusuna dürüst cevap ver.
- Mesajlar mevcut haliyle imalı ama küfürsüz → genelde **12+**
- Mağaza adında "Shit" geçerse veya metinleri sertleştirirsen → **17+**

**Sağlık ifadeleri**: 30+ dakika mesajlarındaki hemoroid/uzun oturma uyarıları genel sağlık tavsiyesi düzeyinde; teşhis/tedavi iddiası yok. Bu haliyle sorun beklenmiyor, ama mesajları sertleştirirsen (ör. "hastalanacaksın") tıbbi iddia kategorisine kayabilir.

---

## 9. Derlemeyi yükle

Xcode → **Product → Archive** (cihaz olarak Any iOS Device seçiliyken) → Organizer açılır → **Distribute App → App Store Connect → Upload**.

Yükleme sonrası App Store Connect'te derlemenin işlenmesi 5-30 dakika sürer; hazır olunca sürüm sayfasındaki **Build** alanından seç.

Şifreleme sorusu projede zaten cevaplı (`ITSAppUsesNonExemptEncryption = false`), her yüklemede tekrar sorulmaz.

---

## 10. TestFlight ile kendi cihazında dene

Sürümü göndermeden önce **TestFlight → Internal Testing** ile kendine dağıt ve şunları gerçek cihazda doğrula:

- Bildirimler gerçekten 5/10/20/30. dakikada geliyor mu (telefonu kilitleyip bekle)
- Satın alma akışı: TestFlight'ta IAP **sandbox** ortamında çalışır, gerçek para çekilmez
- "Satın Alımları Geri Yükle" çalışıyor mu (uygulamayı silip tekrar kur, geri yükle)

---

## 11. İncelemeye gönder

Sürüm sayfasında:

- **App Review Information** → notlara şunu yaz: *"Mizah temelli bir tuvalet sayacıdır. Kullanıcı sayacı elle başlatır, belirli süre eşiklerinde yerel bildirimler gönderilir. Sunucu, hesap veya veri toplama yoktur. Uygulama içi satın alma iki ek görsel temanın kilidini açar."*
- Demo hesap gerekmiyor (giriş yok)
- **Version Release**: "Manually release this version" seçmen, onay çıktığında yayın anını kontrol etmeni sağlar
- **Add for Review → Submit**

İnceleme genelde 24-48 saat sürer.

---

## 12. Sık görülen ret sebepleri ve önlemi

| Risk | Neden | Önlem |
|---|---|---|
| **4.2 Minimum Functionality** | "Tek butonlu basit uygulama" algısı | İstatistikler, üç tema, IAP ve iki dil bu riski azaltıyor; başvuru notunda özellikleri say |
| **1.1.1 Objectionable Content** | Mağaza adındaki küfür | "Sit Happens" ile başvur |
| **2.1 Eksik IAP** | IAP ürünü sürüme eklenmemiş / sözleşme eksik | Adım 0.2 ve 6'yı tamamla |
| **3.1.1** | Satın almanın ne açtığının belirsiz olması | Paywall ekranı ürünü açıkça anlatıyor; ekran görüntüsünü review'a ekle |
| **5.1.1 Gizlilik** | Gizlilik politikası URL'si yok | Adım 7'deki tek sayfalık metni yayınla |

---

## Sonraki sürümler için

1. Kodu değiştir → `CURRENT_PROJECT_VERSION`'ı artır (1 → 2)
2. Kullanıcıya görünen değişiklik varsa `MARKETING_VERSION`'ı artır (1.0 → 1.1)
3. Archive → Upload → App Store Connect'te "+ Version" → What's New metnini yaz → Submit

V1 sonrasına ertelenen özellikler (karakter/ton seçimi, paylaşılabilir kartlar, Watch, otomatik algılama) için bkz. [README](README.md).
