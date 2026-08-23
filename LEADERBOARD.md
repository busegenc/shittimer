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

## Yayına almadan önce zorunlu

1. **App Privacy** beyanı "Data Not Collected" olmaktan çıkacak: kullanıcı kimliği,
   kullanıcı adı ve kullanım verisi toplanıyor olacak.
2. **Gizlilik politikası** yeniden yazılacak (docs/privacy.html + destek deposu).
3. **Kullanıcı içeriği kuralları (1.2)**: kullanıcı adları herkese görünüyorsa
   şikayet etme + kullanıcı engelleme + küfür filtresi gerekiyor.
4. **KVKK/GDPR**: veri sorumlusu olunacak; silme talebi akışı hesap silmeyle karşılanıyor.
5. **Sign in with Apple** capability'si App ID'de açık olmalı (aşağıya bak).

## Apple ile giriş: kalan tek adım

`ShitTimer/ShitTimer.entitlements` eklendi ve projeye bağlandı. Çalışması için:

1. developer.apple.com → Identifiers → `com.busegenc.shittimer` → **Sign In with Apple** işaretle → Save
2. Xcode → hedef → Signing & Capabilities → uyarı çıkarsa "Try Again" (otomatik imzalama profili yeniler)

Simülatörde test ederken cihazın Ayarlar'ında bir Apple hesabıyla oturum açık olmalı.
