# Leaderboard — durum ve yapılacaklar

## Şu an ne var

- **Apple ile giriş** (`LoginView`) — `AuthenticationServices`, entitlement bağlı
- **Kullanıcı adı** (`UsernameView`) — 3-16 karakter, benzersizlik kontrolü
- **Tablo** (`LeaderboardView`) — yalnızca kendi satırın
- **Hesap silme** — App Store 5.1.1(v) gereği

Hepsi `Features.accountsEnabled` bayrağı arkasında. Veri **cihazda** duruyor:
`LocalAccountBackend` yalnızca geliştirme içindir.

## "Tüm kullanıcılar tabloda görünsün" için gereken

Cihazlar birbirini göremez; ortak bir veritabanı şart. `AccountBackend`
protokolünün gerçek bir uygulaması yazılacak, arayüz değişmeyecek.

### Önerilen: Supabase (Postgres + hazır Apple/Google auth)

Asgari şema:

```sql
-- Kullanıcılar
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (username ~ '^[a-z0-9_]{3,16}$'),
  created_at timestamptz default now()
);

-- Haftalık skor (her kullanıcı için tek satır, her hafta güncellenir)
create table weekly_scores (
  user_id uuid references profiles(id) on delete cascade,
  week_start date not null,
  avg_seconds int not null check (avg_seconds >= 0),
  session_count int not null check (session_count > 0),
  updated_at timestamptz default now(),
  primary key (user_id, week_start)
);

-- Arkadaşlık (tek yönlü istek + karşılıklı kabul)
create table friendships (
  requester uuid references profiles(id) on delete cascade,
  addressee uuid references profiles(id) on delete cascade,
  status text not null check (status in ('pending','accepted','blocked')),
  created_at timestamptz default now(),
  primary key (requester, addressee)
);
```

Row Level Security: herkes `profiles.username` ve `weekly_scores` okuyabilir;
yalnızca kendi satırını yazabilir. Böylece küresel tablo mümkün olur.

### Kararlar

- **Küresel tablo mu, sadece arkadaşlar mı?** Küresel tabloda binlerce kullanıcı
  arasında 3000. sırada olmak motive etmez; ayrıca tüm kullanıcı adları herkese
  açık olur (aşağıdaki moderasyon yükümlülüğü). Arkadaş listesi + "bu hafta
  Türkiye ortalaması" gibi bir karşılaştırma çoğu zaman daha iyi çalışır.
- **Hile**: sayaç cihazda, skor uydurulabilir. Ödül yoksa sorun değil.

## App Privacy beyanı — hangi kutular

**Şimdiki sürüm (hesap kapalı): "Data Not Collected".** Uygulama hiçbir şeyi
cihaz dışına göndermiyor. Apple'ın tanımında "toplamak" = veriyi cihazdan
dışarı iletmek; yalnızca cihazda saklamak toplama sayılmaz.

**Leaderboard'lu sürümde işaretlenecekler (yalnızca bunlar):**

| Kategori | Veri türü | Amaç | Kimliğe bağlı mı | Takip |
|---|---|---|---|---|
| Identifiers | User ID | App Functionality | Evet | Hayır |
| Usage Data | Product Interaction | App Functionality | Evet | Hayır |

- **Name işaretlenmeyecek**: gerçek ad toplamıyoruz. Kullanıcının kendi seçtiği
  takma ad Apple'ın sınıflandırmasında **User ID** altına girer.
- **Email Address işaretlenmeyecek**: Apple girişinde e-posta kapsamı hiç
  istenmiyor (`requestedScopes = []`) ve hiçbir yerde saklanmıyor.
- **Analytics / Advertising / Personalization işaretlenmeyecek**: hiçbiri yok.

## Yayına almadan önce zorunlu

1. **App Privacy** beyanı "Data Not Collected" olmaktan çıkacak: kullanıcı kimliği,
   kullanıcı adı ve kullanım verisi toplanıyor olacak.
2. **Gizlilik politikası** yeniden yazılacak (docs/privacy.html + destek deposu).
3. **Kullanıcı içeriği kuralları (1.2)**: kullanıcı adları herkese görünüyorsa
   şikayet etme + kullanıcı engelleme + küfür filtresi gerekiyor.
4. **KVKK/GDPR**: veri sorumlusu olunacak; silme talebi akışı hesap silmeyle karşılanıyor.
5. **Sign in with Apple** capability'si App ID'de açık olmalı (aşağıya bak).

## Supabase — yapılan ve kalan

**Bağlandı:** `SupabaseConfig` proje URL'si ve anon anahtarıyla dolu.
`SupabaseBackend` kimlik, profil, skor, arkadaşlık, engelleme ve şikayet
çağrılarını yapıyor (URLSession ile, ek paket yok). Oturum jetonları Keychain'de.

**Doğrulandı (REST üzerinden):**
- `profiles`, `weekly_scores`, `friendships` var
- RLS açık ve anonim yazmayı engelliyor

**Kalan — senin çalıştırman gereken:** [supabase/schema.sql](supabase/schema.sql)
Şu an hiç RLS politikası yok, dolayısıyla giriş yapmış kullanıcılar da yazamıyor.
Bu dosya politikaları, `reports` tablosunu ve iki görünümü (`friends_leaderboard`,
`pending_requests`) oluşturuyor. Supabase → SQL Editor'da bir kez çalıştır.

**Kalan — Supabase panelinde:** Authentication → Providers → **Apple**'ı aç,
"Client IDs" alanına `com.busegenc.shittimer` yaz. Native giriş bu kimlikle
doğrulanıyor; bu olmadan jeton takası reddedilir.

## Apple ile giriş: kalan tek adım

`ShitTimer/ShitTimer.entitlements` eklendi ve projeye bağlandı. Çalışması için:

1. developer.apple.com → Identifiers → `com.busegenc.shittimer` → **Sign In with Apple** işaretle → Save
2. Xcode → hedef → Signing & Capabilities → uyarı çıkarsa "Try Again" (otomatik imzalama profili yeniler)

Simülatörde test ederken cihazın Ayarlar'ında bir Apple hesabıyla oturum açık olmalı.
