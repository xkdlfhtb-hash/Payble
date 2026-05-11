-- Payble Survey: 관리 코드 기반 설문/응답 스키마
-- 회원가입 없이 설문 작성자가 직접 정한 관리 코드로 본인 설문을 관리합니다.
-- Supabase SQL Editor에서 한 번 실행하세요.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.payble_code_surveys (
  id uuid primary key default extensions.gen_random_uuid(),
  title text not null,
  description text default '',
  form_schema jsonb not null,
  manage_code_hash text not null,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payble_code_survey_responses (
  id uuid primary key default extensions.gen_random_uuid(),
  survey_id uuid not null references public.payble_code_surveys(id) on delete cascade,
  answers jsonb not null default '{}'::jsonb,
  raw_answers jsonb not null default '{}'::jsonb,
  respondent_meta jsonb not null default '{}'::jsonb,
  is_hidden boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_payble_code_surveys_created_at
  on public.payble_code_surveys(created_at desc);

create index if not exists idx_payble_code_responses_survey_created
  on public.payble_code_survey_responses(survey_id, created_at desc);

alter table public.payble_code_surveys enable row level security;
alter table public.payble_code_survey_responses enable row level security;

-- 테이블 직접 접근은 RLS로 막고, 아래 RPC 함수로만 생성/조회/수정/삭제합니다.
drop policy if exists "no direct survey read" on public.payble_code_surveys;
drop policy if exists "no direct response read" on public.payble_code_survey_responses;

create or replace function public.payble_hash_manage_code(p_survey_id uuid, p_manage_code text)
returns text
language sql
stable
set search_path = public, extensions
as $$
  select encode(extensions.digest(coalesce(p_survey_id::text,'') || ':' || coalesce(p_manage_code,''), 'sha256'), 'hex')
$$;

create or replace function public.payble_create_survey_code(
  p_title text,
  p_description text,
  p_form_schema jsonb,
  p_manage_code text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_id uuid := extensions.gen_random_uuid();
begin
  if length(trim(coalesce(p_title,''))) = 0 then
    raise exception '설문 제목을 입력해주세요.';
  end if;

  if length(trim(coalesce(p_manage_code,''))) < 4 then
    raise exception '관리 코드는 4자 이상이어야 합니다.';
  end if;

  insert into public.payble_code_surveys (
    id, title, description, form_schema, manage_code_hash
  ) values (
    v_id,
    trim(p_title),
    coalesce(p_description,''),
    coalesce(p_form_schema,'{}'::jsonb),
    public.payble_hash_manage_code(v_id, p_manage_code)
  );

  return v_id;
end;
$$;

create or replace function public.payble_get_public_survey_code(p_survey_id uuid)
returns table (
  id uuid,
  title text,
  description text,
  form_schema jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select s.id, s.title, s.description, s.form_schema, s.created_at, s.updated_at
  from public.payble_code_surveys s
  where s.id = p_survey_id
    and s.is_deleted = false
  limit 1;
end;
$$;

create or replace function public.payble_get_manage_survey_code(
  p_survey_id uuid,
  p_manage_code text
)
returns table (
  id uuid,
  title text,
  description text,
  form_schema jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select s.id, s.title, s.description, s.form_schema, s.created_at, s.updated_at
  from public.payble_code_surveys s
  where s.id = p_survey_id
    and s.is_deleted = false
    and s.manage_code_hash = public.payble_hash_manage_code(s.id, p_manage_code)
  limit 1;
end;
$$;

create or replace function public.payble_update_survey_code(
  p_survey_id uuid,
  p_manage_code text,
  p_title text,
  p_description text,
  p_form_schema jsonb
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.payble_code_surveys s
  set title = trim(p_title),
      description = coalesce(p_description,''),
      form_schema = coalesce(p_form_schema,'{}'::jsonb),
      updated_at = now()
  where s.id = p_survey_id
    and s.is_deleted = false
    and s.manage_code_hash = public.payble_hash_manage_code(s.id, p_manage_code);

  return found;
end;
$$;

create or replace function public.payble_delete_survey_code(
  p_survey_id uuid,
  p_manage_code text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.payble_code_surveys s
  set is_deleted = true,
      updated_at = now()
  where s.id = p_survey_id
    and s.is_deleted = false
    and s.manage_code_hash = public.payble_hash_manage_code(s.id, p_manage_code);

  return found;
end;
$$;

create or replace function public.payble_submit_survey_response_code(
  p_survey_id uuid,
  p_answers jsonb,
  p_raw_answers jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_response_id uuid := extensions.gen_random_uuid();
begin
  if not exists (
    select 1 from public.payble_code_surveys s
    where s.id = p_survey_id and s.is_deleted = false
  ) then
    raise exception '존재하지 않거나 삭제된 설문입니다.';
  end if;

  insert into public.payble_code_survey_responses (
    id, survey_id, answers, raw_answers, respondent_meta
  ) values (
    v_response_id,
    p_survey_id,
    coalesce(p_answers,'{}'::jsonb),
    coalesce(p_raw_answers,'{}'::jsonb),
    jsonb_build_object('createdFrom','payble-survey')
  );

  return v_response_id;
end;
$$;

create or replace function public.payble_get_survey_responses_code(
  p_survey_id uuid,
  p_manage_code text
)
returns table (
  id uuid,
  answers jsonb,
  raw_answers jsonb,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.payble_code_surveys s
    where s.id = p_survey_id
      and s.is_deleted = false
      and s.manage_code_hash = public.payble_hash_manage_code(s.id, p_manage_code)
  ) then
    raise exception '설문 ID 또는 관리 코드가 올바르지 않습니다.';
  end if;

  return query
  select r.id, r.answers, r.raw_answers, r.created_at
  from public.payble_code_survey_responses r
  where r.survey_id = p_survey_id
    and r.is_hidden = false
  order by r.created_at desc;
end;
$$;

grant execute on function public.payble_hash_manage_code(uuid, text) to anon, authenticated;
grant execute on function public.payble_create_survey_code(text, text, jsonb, text) to anon, authenticated;
grant execute on function public.payble_get_public_survey_code(uuid) to anon, authenticated;
grant execute on function public.payble_get_manage_survey_code(uuid, text) to anon, authenticated;
grant execute on function public.payble_update_survey_code(uuid, text, text, text, jsonb) to anon, authenticated;
grant execute on function public.payble_delete_survey_code(uuid, text) to anon, authenticated;
grant execute on function public.payble_submit_survey_response_code(uuid, jsonb, jsonb) to anon, authenticated;
grant execute on function public.payble_get_survey_responses_code(uuid, text) to anon, authenticated;
