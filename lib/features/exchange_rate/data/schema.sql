-- 1. 최신 환율 테이블 (Latest Rates)
create table if not exists public.fx_latest_cache (
  base text not null, -- 기준 통화 (예: 'KRW')
  rates jsonb not null, -- 환율 정보 (예: {"USD": 0.00075, ...})
  last_updated_at timestamptz not null default now(), -- 마지막 업데이트 시간
  primary key (base)
);

-- 2. 환율 히스토리 테이블 (Historical Rates)
create table if not exists public.fx_history (
  date date not null, -- 날짜 (예: '2024-01-01')
  base text not null default 'KRW', -- 기준 통화
  rates jsonb not null, -- 환율 정보
  created_at timestamptz not null default now(),
  primary key (date, base)
);

-- 3. 인덱스 생성 (검색 속도 향상)
create index if not exists idx_fx_history_date on public.fx_history(date);

-- 4. RLS (Row Level Security) 설정 - 누구나 읽기 가능 (앱에서 조회용)
alter table public.fx_latest_cache enable row level security;
alter table public.fx_history enable row level security;

create policy "Enable read access for all users" on public.fx_latest_cache for select using (true);
create policy "Enable read access for all users" on public.fx_history for select using (true);

-- 쓰기 권한은 Service Role (백엔드 스크립트)만 가능하도록 기본 제한됨
