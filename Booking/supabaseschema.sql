-- ============================================================
-- HANAHAYAN Monthly Booking — Supabase 스키마
-- Supabase Dashboard → SQL Editor 에 전체를 붙여넣고 [Run] 하세요.
-- ============================================================

-- 1) 예약 (월별 예약장부)
--    data 컬럼에 예약 1건의 전체 JSON을 그대로 저장합니다.
create table if not exists public.bookings (
  id          bigint primary key,          -- 클라이언트 생성 id (Date.now())
  data        jsonb  not null,             -- 예약 객체 전체
  updated_at  timestamptz not null default now()
);

-- 2) 고객 원장 (3회권 코스 + 멤버십 충전/잔액)
create table if not exists public.customers (
  id          bigint primary key,          -- 클라이언트 생성 id (Date.now())
  data        jsonb  not null,             -- 고객 원장 객체 전체 (type: course|membership)
  updated_at  timestamptz not null default now()
);

-- 3) 담당자 (테라피스트 로스터)
create table if not exists public.staff (
  name        text primary key,
  sort_order  int  not null default 0,
  updated_at  timestamptz not null default now()
);

-- 4) 설정 (베드 수, 할인 목록 등 key-value)
create table if not exists public.settings (
  key         text primary key,            -- 'beds' | 'discounts'
  value       jsonb not null,
  updated_at  timestamptz not null default now()
);

-- updated_at 자동 갱신 (last-write-wins 기준 시각)
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_touch_bookings  on public.bookings;
drop trigger if exists trg_touch_customers on public.customers;
drop trigger if exists trg_touch_staff     on public.staff;
drop trigger if exists trg_touch_settings  on public.settings;
create trigger trg_touch_bookings  before insert or update on public.bookings  for each row execute function public.touch_updated_at();
create trigger trg_touch_customers before insert or update on public.customers for each row execute function public.touch_updated_at();
create trigger trg_touch_staff     before insert or update on public.staff     for each row execute function public.touch_updated_at();
create trigger trg_touch_settings  before insert or update on public.settings  for each row execute function public.touch_updated_at();

-- ============================================================
-- RLS: 로그인(공유 비밀번호 계정)한 사용자만 읽기/쓰기 가능.
-- anon key 만으로는 아무것도 못 읽습니다.
-- ============================================================
alter table public.bookings  enable row level security;
alter table public.customers enable row level security;
alter table public.staff     enable row level security;
alter table public.settings  enable row level security;

drop policy if exists "authenticated all" on public.bookings;
drop policy if exists "authenticated all" on public.customers;
drop policy if exists "authenticated all" on public.staff;
drop policy if exists "authenticated all" on public.settings;
create policy "authenticated all" on public.bookings  for all to authenticated using (true) with check (true);
create policy "authenticated all" on public.customers for all to authenticated using (true) with check (true);
create policy "authenticated all" on public.staff     for all to authenticated using (true) with check (true);
create policy "authenticated all" on public.settings  for all to authenticated using (true) with check (true);

-- ============================================================
-- Realtime: 다른 기기 실시간 동기화용 (변경 브로드캐스트)
-- ============================================================
do $$
begin
  begin
    alter publication supabase_realtime add table public.bookings;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.customers;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.staff;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.settings;
  exception when duplicate_object then null;
  end;
end $$;

-- ============================================================
-- 이후 대시보드에서 할 일 (SQL 아님):
-- 1. Authentication → Users → Add user
--    - Email: staff@hanahayan.app  (앱의 LOGIN_EMAIL과 동일해야 함)
--    - Password: 직원용 공유 비밀번호
--    - "Auto Confirm User" 체크
-- 2. Authentication → Sign In / Up → "Allow new users to sign up" 끄기
--    (아무나 가입해서 authenticated 권한을 얻는 것을 차단)
-- ============================================================
