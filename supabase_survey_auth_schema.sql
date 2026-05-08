-- Payble Survey Auth schema
-- 실행 위치: Supabase Dashboard → SQL Editor → New query → Run
-- 작성자는 로그인 후 자기 설문만 관리하고, 응답자는 로그인 없이 제출할 수 있는 구조입니다.

create extension if not exists pgcrypto;

create table if not exists public.payble_public_surveys (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) on delete set null,
  title text not null,
  description text default '',
  form_schema jsonb not null default '{}'::jsonb,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.payble_public_surveys add column if not exists owner_id uuid references auth.users(id) on delete set null;
alter table public.payble_public_surveys add column if not exists title text;
alter table public.payble_public_surveys add column if not exists description text default '';
alter table public.payble_public_surveys add column if not exists form_schema jsonb not null default '{}'::jsonb;
alter table public.payble_public_surveys add column if not exists is_published boolean not null default true;
alter table public.payble_public_surveys add column if not exists created_at timestamptz not null default now();
alter table public.payble_public_surveys add column if not exists updated_at timestamptz not null default now();

create table if not exists public.payble_survey_responses (
  id uuid primary key default gen_random_uuid(),
  survey_id uuid not null references public.payble_public_surveys(id) on delete cascade,
  answers jsonb not null default '{}'::jsonb,
  raw_answers jsonb not null default '{}'::jsonb,
  respondent_meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.payble_survey_responses add column if not exists survey_id uuid references public.payble_public_surveys(id) on delete cascade;
alter table public.payble_survey_responses add column if not exists answers jsonb not null default '{}'::jsonb;
alter table public.payble_survey_responses add column if not exists raw_answers jsonb not null default '{}'::jsonb;
alter table public.payble_survey_responses add column if not exists respondent_meta jsonb not null default '{}'::jsonb;
alter table public.payble_survey_responses add column if not exists created_at timestamptz not null default now();

create or replace function public.set_payble_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_payble_public_surveys_updated_at on public.payble_public_surveys;
create trigger trg_payble_public_surveys_updated_at
before update on public.payble_public_surveys
for each row execute function public.set_payble_updated_at();

alter table public.payble_public_surveys enable row level security;
alter table public.payble_survey_responses enable row level security;

drop policy if exists "public can read published surveys" on public.payble_public_surveys;
drop policy if exists "owners can read own surveys" on public.payble_public_surveys;
drop policy if exists "authenticated can create own surveys" on public.payble_public_surveys;
drop policy if exists "owners can update own surveys" on public.payble_public_surveys;
drop policy if exists "owners can delete own surveys" on public.payble_public_surveys;
drop policy if exists "anyone can submit responses to published surveys" on public.payble_survey_responses;
drop policy if exists "owners can read responses" on public.payble_survey_responses;
drop policy if exists "owners can delete responses" on public.payble_survey_responses;

-- 응답자는 공개 설문 링크로 설문 구조를 읽을 수 있습니다.
create policy "public can read published surveys"
on public.payble_public_surveys
for select
to anon, authenticated
using (is_published = true or owner_id = auth.uid());

-- 작성자는 로그인 후 자기 설문만 만들 수 있습니다.
create policy "authenticated can create own surveys"
on public.payble_public_surveys
for insert
to authenticated
with check (owner_id = auth.uid());

-- 작성자는 자기 설문만 수정/삭제할 수 있습니다.
create policy "owners can update own surveys"
on public.payble_public_surveys
for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy "owners can delete own surveys"
on public.payble_public_surveys
for delete
to authenticated
using (owner_id = auth.uid());

-- 응답자는 로그인 없이 공개 설문에 응답할 수 있습니다.
create policy "anyone can submit responses to published surveys"
on public.payble_survey_responses
for insert
to anon, authenticated
with check (
  exists (
    select 1 from public.payble_public_surveys s
    where s.id = survey_id and s.is_published = true
  )
);

-- 응답 조회는 해당 설문 작성자만 가능합니다.
create policy "owners can read responses"
on public.payble_survey_responses
for select
to authenticated
using (
  exists (
    select 1 from public.payble_public_surveys s
    where s.id = survey_id and s.owner_id = auth.uid()
  )
);

create policy "owners can delete responses"
on public.payble_survey_responses
for delete
to authenticated
using (
  exists (
    select 1 from public.payble_public_surveys s
    where s.id = survey_id and s.owner_id = auth.uid()
  )
);

create index if not exists idx_payble_public_surveys_owner on public.payble_public_surveys(owner_id);
create index if not exists idx_payble_survey_responses_survey on public.payble_survey_responses(survey_id, created_at desc);
