# HANAHAYAN 예약 관리 — Supabase 동기화 버전 설정 가이드

기존 `HANAHAYAN_Monthly_Booking.html`(localStorage 저장)을 **Supabase 실시간 동기화** 버전으로 교체한 것입니다.
카운터 태블릿·폰·PC 어디서든 같은 데이터를 보고, 저장 즉시 다른 기기 화면이 자동 갱신됩니다.

## 파일 구성

| 파일 | 설명 |
|---|---|
| `index.html` | 예약 관리 앱 (정적 HTML 1개, 빌드 도구 없음) |
| `supabase-schema.sql` | Supabase 테이블 생성 SQL |
| `SETUP.md` | 이 문서 |

기존 기능은 전부 그대로입니다: 월별 예약장부 · 전화번호 조회(phoneLookup) · 고객 원장(3회권 차감/멤버십 충전·잔액) · 담당자 로스터 · 백업/복원(JSON) · CSV/엑셀 내보내기 · 직원 모드 · 체크인 리스트 · 인쇄 시트.

---

## 1단계 — Supabase 프로젝트 만들기 (약 5분)

1. https://supabase.com → 로그인 → **New Project**
   - Region은 **Southeast Asia (Singapore)** 추천 (방콕에서 가장 빠름)
2. 프로젝트가 생성되면 **SQL Editor** 를 열고, `supabase-schema.sql` 파일 내용 **전체를 붙여넣고 [Run]**
   - 테이블 4개(bookings / customers / staff / settings) + RLS 정책 + Realtime 설정이 한 번에 만들어집니다.
3. **공유 로그인 계정 만들기** — Authentication → Users → **Add user**
   - Email: `staff@hanahayan.app`
   - Password: 직원들과 공유할 비밀번호
   - ✅ **Auto Confirm User** 반드시 체크
4. **가입 차단** — Authentication → Sign In / Providers(또는 Settings) →
   **"Allow new users to sign up" 끄기**
   - 이걸 꺼야 모르는 사람이 스스로 가입해서 데이터에 접근하는 것을 막을 수 있습니다.

## 2단계 — 앱에 연결 정보 넣기 (✅ 이미 완료됨)

이 저장소의 `index.html`에는 아래 값이 이미 입력되어 있습니다:

```js
const SUPABASE_URL='https://fxybjauokblmwhpupwzd.supabase.co';
const SUPABASE_ANON_KEY='sb_publishable_53Wb77EKeX5pJMMPLKiiIg_QuRT_8HX';
const LOGIN_EMAIL='staff@hanahayan.app';   // 1단계에서 만든 계정 이메일과 동일해야 함
```

> publishable(anon) key는 코드에 노출되어도 괜찮습니다. RLS가 켜져 있어서
> **로그인(공유 비밀번호) 없이는 아무 데이터도 읽거나 쓸 수 없습니다.**
> 나중에 Supabase 프로젝트를 바꾸면 이 세 값만 수정하면 됩니다.

## 3단계 — Vercel 배포

### 방법 A: GitHub 연동 (추천 — 이후 수정 시 자동 재배포)

1. https://vercel.com → **Add New → Project** → 이 GitHub 저장소(`witan-thailand`) import
2. **Root Directory** 를 `booking` 으로 지정 → Deploy
3. 나오는 주소(예: `https://hanahayan-booking.vercel.app`)를 태블릿·폰에 즐겨찾기/홈 화면 추가

### 방법 B: Vercel CLI (내 컴퓨터에서)

```bash
npm i -g vercel          # CLI 설치 (안 깔려 있으면)
cd booking
vercel login             # 브라우저로 로그인
vercel --prod            # 배포
```

> 이 저장소를 만든 원격 작업 환경에는 Vercel 로그인 정보가 없어서 배포 명령까지만 준비해 두었습니다.
> 위 두 방법 중 하나로 본인 Vercel 계정에서 실행하면 바로 배포됩니다.

## 4단계 — 기존 데이터 이전 (한 번만)

1. **예전 파일**(localStorage 버전 `HANAHAYAN_Monthly_Booking.html`)을 지금까지 쓰던 그 기기·그 브라우저에서 열기
2. `💾 백업` 버튼 → `HANAHAYAN_backup_YYYY-MM-DD.json` 파일 다운로드
   - 파일 다운로드가 안 되는 환경이면 `📋 텍스트 백업/복원` → 텍스트 복사도 가능
3. **새 사이트**(Vercel 주소)를 열고 공유 비밀번호로 로그인
4. `📂 복원` 버튼 → 방금 받은 JSON 파일 선택 → "덮어쓰기(교체)" 선택
   - 복원 즉시 **Supabase 서버로 자동 업로드**됩니다. 상단에 ⚠️ 경고가 없으면 완료.
5. 다른 기기(태블릿·폰)에서도 새 사이트를 열어 같은 데이터가 보이는지 확인
6. 확인되면 예전 HTML 파일은 더 이상 쓰지 않기 (헷갈림 방지를 위해 이름을 `_OLD.html`로 바꿔두기 추천)

## 동작 방식 요약

- **저장 즉시 업로드**: 예약/고객/담당자/설정을 수정하면 0.4초 뒤 변경분만 서버로 전송 (last-write-wins)
- **실시간 동기화**: Supabase Realtime 구독 → 다른 기기가 저장하면 내 화면이 자동 갱신
- **오프라인 경고**: 서버 전송 실패 시 화면 상단에 빨간 경고 배너 + 15초마다 자동 재시도.
  localStorage에 캐시가 남아 있어 화면은 계속 쓸 수 있지만, 경고가 떠 있는 동안의 변경은 서버에 반영이 보장되지 않습니다.
- **로그인 세션 유지**: 한 번 로그인하면 기기에 세션이 저장되어 다시 물어보지 않습니다. (`🚪 로그아웃` 버튼으로 해제)
- **기기별 설정**: 언어(한/ไทย/EN), 직원 모드, 사장 모드 PIN은 기기마다 따로 저장됩니다(동기화 안 됨 — 의도된 동작).

## localStorage → Supabase 매핑 (참고)

| 기존 localStorage 키 | 내용 | Supabase 테이블 |
|---|---|---|
| `hanahayan_bookings_v1` | 예약 배열 | `bookings` (행당 1건, jsonb) |
| `hanahayan_customers_v1` | 고객 원장(코스·멤버십) | `customers` (행당 1명, jsonb) |
| `hanahayan_staff_v1` | 담당자 이름 배열 | `staff` (name, sort_order) |
| `hanahayan_discounts_v1` | 할인 목록 | `settings` (key=`discounts`) |
| `hanahayan_beds` | 베드 수 | `settings` (key=`beds`) |
| `hanahayan_lang` / `hanahayan_viewmode` / `hanahayan_ownerpin` | 기기별 UI 설정 | (동기화 안 함 — localStorage 유지) |
