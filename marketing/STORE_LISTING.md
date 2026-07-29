# App Store Connect Metinleri

Kopyala-yapıştır için hazır. Karakter sınırları Apple'ın koyduğu üst sınırlardır; aşağıdaki metinlerin hepsi sayılarak sınırların içinde olduğu doğrulandı.

---

## Uygulama adı (30 karakter sınırı)

```
Sit Happens
```

> Alternatif, arama için biraz daha açıklayıcı: `Sit Happens: Tuvalet Sayacı` (28 karakter)

## Alt başlık / Subtitle (30 karakter sınırı)

**Türkçe**
```
Tuvalette ne kadar kaldın?
```

**English**
```
Your bathroom break, timed
```
> `How long have you been in there?` daha iyi ama 32 karakter, sınırı 2 aşıyor.

## Anahtar kelimeler / Keywords (100 karakter, virgülle ayrık, boşluk kullanma)

**Türkçe**
```
tuvalet,sayaç,zamanlayıcı,timer,mizah,komik,sağlık,hatırlatıcı,alışkanlık,banyo,wc,mola
```

**English**
```
toilet,timer,bathroom,funny,humor,health,reminder,habit,break,sit,stopwatch,minutes
```

## Tanıtım metni / Promotional Text (170 karakter, sürüm göndermeden değiştirilebilir)

**Türkçe**
```
Telefonu alıp tuvalete gidiyorsun, yarım saat sonra çıkıyorsun. Sit Happens sayar ve gerektiğinde dürter. Üç tema, iki dil, sıfır veri toplama.
```

**English**
```
You take your phone to the bathroom and emerge half an hour later. Sit Happens times it and nudges you when it's time. Three themes, no data collection.
```

---

## Açıklama / Description (4000 karakter sınırı)

**Türkçe**

```
Telefonu alıp tuvalete giriyorsun. Bir bakıyorsun yirmi dakika olmuş.

Sit Happens tam olarak bunun için var: oturduğunda başlat, kalktığında bitir. Arada belirli süre eşiklerini geçtikçe seni dürten bildirimler gönderir — önce nazikçe, sonra giderek daha az nazikçe.

NASIL ÇALIŞIR
• Tek dokunuşla başlat, tek dokunuşla bitir
• 5, 10, 20 ve 30 dakikada bildirim
• Her seferinde farklı bir laf; aynı mesaj arka arkaya gelmez
• Ekrandaki emoji süre uzadıkça halinden şikâyet etmeye başlar

İSTATİSTİKLER
• Bugün ne kadar sürdü
• Bu haftaki toplam ve oturum başına ortalama
• Kişisel rekorun (evet, gurur duyulacak bir şey değil)

ÜÇ TEMA
Klasik tema ücretsiz gelir. Tema Paketi'ni bir kez satın alarak Arcade (neon retro) ve Pastel (yumuşak ve şirin) temalarını da açabilirsin. Abonelik yok, tek seferlik.

TÜRKÇE VE İNGİLİZCE
Mesajlar çeviri değil. Her iki dilde ayrı ayrı yazıldı, çünkü espri çevrilince espri olmaktan çıkıyor. Uygulama telefonunun diline göre kendini ayarlar.

GİZLİLİK
Hesap yok, sunucu yok, reklam yok, takip yok. Ne kadar oturduğun yalnızca senin telefonunda kalır.

KÜÇÜK BİR NOT
Uzun süre oturmanın sağlık açısından ideal olmadığı doğru. Bu uygulama bir sağlık uygulaması değil, ama 30. dakikadaki mesajlar biraz da bu yüzden var.
```

**English**

```
You take your phone to the bathroom. Twenty minutes later, you're still there.

That's what Sit Happens is for: start it when you sit down, stop it when you get up. In between, it sends notifications as you cross certain time thresholds — politely at first, then progressively less so.

HOW IT WORKS
• One tap to start, one tap to finish
• Nudges at 5, 10, 20 and 30 minutes
• A different quip every time; the same message never repeats back to back
• The emoji on screen gets visibly less comfortable as the minutes pass

STATS
• How long today took
• This week's total and your average per session
• Your personal record (not something to be proud of, but here it is)

THREE THEMES
The Classic theme is free. A one-time Theme Pack purchase unlocks Arcade (retro neon) and Pastel (soft and cute). No subscription.

TURKISH AND ENGLISH
The messages aren't translations. They were written separately in each language, because a joke stops being a joke once it's translated. The app follows your phone's language.

PRIVACY
No account, no server, no ads, no tracking. How long you sit stays on your phone.

ONE SMALL NOTE
Sitting for a long time genuinely isn't great for you. This is not a health app, but that's partly why the 30-minute messages exist.
```

---

## Uygulama içi satın alma metinleri

Ürün: **Non-Consumable** · Product ID: `com.busegenc.shittimer.themepack`

| Alan | Türkçe | English |
|---|---|---|
| Görünen ad | Tema Paketi | Theme Pack |
| Açıklama | Arcade ve Pastel temalarının kilidini açar. Tek seferlik satın alma, abonelik yok. | Unlocks the Arcade and Pastel themes. One-time purchase, no subscription. |

**Review Screenshot:** `marketing/screenshots/iap-review-640x920.png`

> App Store Connect, IAP inceleme görselinde mağaza ekran görüntülerinden farklı boyut istiyor;
> 6.9" görüntü (1320×2868) "dimensions are wrong" hatası veriyor. `iap-review-640x920.png`
> bu iş için üretildi (gerilme yok, yanlarda tema renginde dolgu). Kabul edilmezse yedek:
> `iap-review-1242x2208.png`.

**Review Notes:**
```
Tek seferlik (non-consumable) satın alma. Uygulamanın ücretsiz temasına ek olarak iki görsel temanın kilidini açar. Abonelik veya tekrarlayan ödeme yoktur. Satın alma ekranında "Satın Alımları Geri Yükle" düğmesi bulunmaktadır.
```

---

## URL'ler (App Store Connect'te zorunlu)

| Alan | URL |
|---|---|
| Support URL | https://busegenc.github.io/sit-happens-support/ |
| Privacy Policy URL | https://busegenc.github.io/sit-happens-support/privacy.html |

Sayfalar ayrı bir public depoda: [busegenc/sit-happens-support](https://github.com/busegenc/sit-happens-support)
(kaynak kod deposu private kalsın diye). Yerel kopya: `~/sit-happens-support`, bu depodaki
`docs/` klasörüyle aynı içerik.

---

## Diğer zorunlu alanlar

- **Content Rights**: üçüncü taraf içerik yok → "No"
- **Primary Category**: Utilities · **Secondary**: Entertainment
- **Age Rating**: kaba mizah "Infrequent/Mild", diğer tüm sorular "None" → 12+ bekleniyor

---

## App Review Information (sürüm gönderiminde)

Demo hesap gerekmiyor (giriş yok). Notes alanına:

```
Mizah temelli bir tuvalet sayacıdır. Kullanıcı sayacı elle başlatır; 5, 10, 20 ve 30 dakikada yerel bildirim gönderilir. Sunucu, kullanıcı hesabı ve veri toplama yoktur, tüm veriler cihazda kalır.

Uygulama içi satın alma (com.busegenc.shittimer.themepack) iki ek görsel temanın kilidini açar; tek seferlik, abonelik değildir. Ana ekranın üstündeki kilitli tema simgelerine dokunularak satın alma ekranı açılır. "Satın Alımları Geri Yükle" düğmesi aynı ekrandadır.

30 dakika eşiğindeki mesajlar uzun süre oturmanın rahatsızlık verebileceğine dair genel nitelikte, mizahi hatırlatmalardır; teşhis, tedavi veya tıbbi tavsiye iddiası içermez.
```

---

## Ekran görüntüleri

İki boyut hazır — App Store Connect hangi slotu istiyorsa onu kullan:

- `marketing/screenshots/` — **1320×2868 (6.9")**
- `marketing/screenshots/6.5-inch/` — **1284×2778 (6.5")**

Dosyalar:

1. `01-sayac.png` — çalışan sayaç ve laf kartı
2. `02-saglik-uyarisi.png` — 30+ dakika, sağlık hatırlatması
3. `03-istatistikler.png` — istatistik ekranı
4. `04-tema-arcade.png` — Arcade teması
5. `05-tema-paketi.png` — Tema Paketi satın alma ekranı (IAP review görseli olarak da kullanılır)

> Yeniden üretmek için: [README](../README.md) içindeki DEBUG launch argümanları ve `--marketing` bayrağı.


---

## 1.1 reddi sonrası (27 Temmuz 2026)

İlk gönderim **Guideline 1.1 — Objectionable Content** gerekçesiyle reddedildi:
uygulama ikonu ve tema düğmelerindeki karikatür görseller (💩) sorun edildi.

Yapılan değişiklikler (build 1.0 (3)):

- **İkon** tamamen yeniden çizildi: emoji yok, yalnızca vektörel altın halka + saat ibresi
- **Tema düğmeleri** emoji yerine renk noktası; kilit rozeti SF Symbol
- **Klasik tema** (eski "Kaka") adı ve tüm 💩 / ☠️ görselleri kaldırıldı; eşik emojileri
  yalnızca saat ve yüz ifadeleri: ⏱️ 🙂 😐 😅 😰
- Paywall ve istatistik ekranındaki dekoratif emojiler SF Symbol'e çevrildi
- Anahtar kelimelerden "poop" çıkarıldı, açıklamada "Kaka teması" → "Klasik tema"
- Ekran görüntüleri yeni arayüzle yeniden alındı

**App Review'a yanıt olarak gönderilecek not:**

```
Merhaba,

1.1 kapsamındaki geri bildiriminiz için teşekkürler. Belirtilen içerikleri kaldırdık:

1. Uygulama ikonu tamamen yeniden tasarlandı. Önceki ikondaki karikatür görsel
   kaldırıldı; yeni ikon yalnızca soyut bir zamanlayıcı halkası ve saat ibresinden
   oluşuyor.
2. Ana ekrandaki tema seçim düğmelerindeki karikatür görseller kaldırıldı; düğmeler
   artık yalnızca temanın rengini gösteren renk noktaları.
3. Uygulama genelindeki diğer karikatür görseller de kaldırıldı. Kalan simgeler
   standart saat ve yüz ifadeleridir.
4. Mağaza metinleri ve ekran görüntüleri yeni arayüze göre güncellendi.

Uygulama, kullanıcının kendi başlattığı bir süre sayacıdır ve uzun süre oturmaya
karşı mizahi hatırlatmalar gönderir. Rahatsız edici olabilecek görsel içerik
kalmamıştır.

İyi çalışmalar.
```
