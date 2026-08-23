-- Sit Happens — Supabase şeması (çalıştırılacak kalan kısım)
--
-- profiles / weekly_scores / friendships tabloları zaten oluşturuldu ve RLS açık.
-- Ancak hiç politika tanımlı olmadığı için şu an giriş yapmış kullanıcılar da
-- yazamıyor. Aşağıdakini Supabase → SQL Editor'da bir kez çalıştır.

-- ---------------------------------------------------------------- şikayet tablosu
create table if not exists reports (
  id bigserial primary key,
  reporter uuid not null references profiles(id) on delete cascade,
  reported uuid not null references profiles(id) on delete cascade,
  reason text not null,
  created_at timestamptz default now()
);

alter table profiles      enable row level security;
alter table weekly_scores enable row level security;
alter table friendships   enable row level security;
alter table reports       enable row level security;

-- ---------------------------------------------------------------- profiles
-- Kullanıcı adı arama ve arkadaş ekleme için giriş yapmış herkes okuyabilir;
-- yalnızca kendi satırını yazabilir.
drop policy if exists "profiles_read"        on profiles;
drop policy if exists "profiles_insert_own"  on profiles;
drop policy if exists "profiles_update_own"  on profiles;
drop policy if exists "profiles_delete_own"  on profiles;

create policy "profiles_read"       on profiles for select to authenticated using (true);
create policy "profiles_insert_own" on profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles_update_own" on profiles for update to authenticated using (auth.uid() = id);
create policy "profiles_delete_own" on profiles for delete to authenticated using (auth.uid() = id);

-- ---------------------------------------------------------------- weekly_scores
-- Kendi skorunu yazar; kendi ve arkadaşlarının skorunu okur.
drop policy if exists "scores_insert_own"     on weekly_scores;
drop policy if exists "scores_update_own"     on weekly_scores;
drop policy if exists "scores_read_or_friend" on weekly_scores;

create policy "scores_insert_own" on weekly_scores for insert to authenticated
  with check (auth.uid() = user_id);
create policy "scores_update_own" on weekly_scores for update to authenticated
  using (auth.uid() = user_id);
create policy "scores_read_or_friend" on weekly_scores for select to authenticated using (
  user_id = auth.uid()
  or exists (
    select 1 from friendships f
    where f.status = 'accepted'
      and ( (f.requester = auth.uid() and f.addressee = weekly_scores.user_id)
         or (f.addressee = auth.uid() and f.requester = weekly_scores.user_id) )
  )
);

-- ---------------------------------------------------------------- friendships
-- Yalnızca taraf olduğun satırlar. İsteği gönderen açar, alan kabul eder.
drop policy if exists "friend_read_own"    on friendships;
drop policy if exists "friend_insert_own"  on friendships;
drop policy if exists "friend_update_addr" on friendships;
drop policy if exists "friend_delete_own"  on friendships;

create policy "friend_read_own"    on friendships for select to authenticated
  using (auth.uid() in (requester, addressee));
create policy "friend_insert_own"  on friendships for insert to authenticated
  with check (auth.uid() = requester and requester <> addressee);
create policy "friend_update_addr" on friendships for update to authenticated
  using (auth.uid() = addressee);
create policy "friend_delete_own"  on friendships for delete to authenticated
  using (auth.uid() in (requester, addressee));

-- ---------------------------------------------------------------- reports
drop policy if exists "reports_insert_own" on reports;
create policy "reports_insert_own" on reports for insert to authenticated
  with check (auth.uid() = reporter);

-- ---------------------------------------------------------------- görünümler
-- security_invoker: görünümü sorgulayan kullanıcının RLS kuralları uygulanır,
-- yani kimse arkadaşı olmayan birinin skorunu göremez.

drop view if exists friends_leaderboard;
create view friends_leaderboard with (security_invoker = on) as
  select p.id as user_id, p.username, w.avg_seconds, w.session_count, w.week_start
  from profiles p
  join weekly_scores w on w.user_id = p.id;

drop view if exists pending_requests;
create view pending_requests with (security_invoker = on) as
  select p.id as user_id, p.username, 0 as avg_seconds, 0 as session_count
  from friendships f
  join profiles p on p.id = f.requester
  where f.status = 'pending' and f.addressee = auth.uid();

grant select on friends_leaderboard, pending_requests to authenticated;
