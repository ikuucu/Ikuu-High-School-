-- Ikuu Boys High School Christian Union: messages + admin access
-- Run this whole file once in Supabase: SQL Editor > New query > paste > Run.

-- 1. Who is an admin
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- 2. Messages sent by signed-in members
create table if not exists public.messages (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  sender_name text not null default '' check (char_length(sender_name) <= 120),
  sender_email text not null,
  category text not null default 'Message'
    check (category in ('Message','Prayer request','Testimony','Question','Feedback')),
  subject text not null check (char_length(subject) between 1 and 120),
  body text not null check (char_length(body) between 1 and 2000),
  status text not null default 'new' check (status in ('new','read','done')),
  reply text check (reply is null or char_length(reply) <= 2000),
  replied_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists messages_user_idx   on public.messages (user_id, created_at desc);
create index if not exists messages_status_idx on public.messages (status, created_at desc);

-- 3. Helper used by the security rules below
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- 4. Security rules (Row Level Security). These are what actually protect the data.
alter table public.admins   enable row level security;
alter table public.messages enable row level security;

drop policy if exists "admins can see their own row"      on public.admins;
drop policy if exists "members send their own messages"   on public.messages;
drop policy if exists "members read own, admins read all" on public.messages;
drop policy if exists "admins update messages"            on public.messages;
drop policy if exists "admins delete messages"            on public.messages;

create policy "admins can see their own row"
  on public.admins for select to authenticated
  using (user_id = auth.uid());

create policy "members send their own messages"
  on public.messages for insert to authenticated
  with check (
    user_id = auth.uid()
    and sender_email = (auth.jwt() ->> 'email')
    and status = 'new'
    and reply is null
  );

create policy "members read own, admins read all"
  on public.messages for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy "admins update messages"
  on public.messages for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "admins delete messages"
  on public.messages for delete to authenticated
  using (public.is_admin());

-- 5. Make yourself the admin.
-- FIRST create your account on the website (Create an account page),
-- THEN replace the email below with yours and run ONLY this statement:
--
-- insert into public.admins (user_id)
-- select id from auth.users where email = 'your-admin-email@example.com';
