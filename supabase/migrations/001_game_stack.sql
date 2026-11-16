-- GAME STACK. Safe to run after the starter SQL already provided in chat.
-- Paste into Supabase Dashboard > SQL Editor, then Run.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null default 'Player',
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.user_games (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  rawg_game_id bigint not null,
  game_title text not null,
  cover_url text,
  description text,
  release_date date,
  genres text[] default '{}',
  status text not null default 'want_to_play'
      check (status in ('played', 'currently_playing', 'want_to_play')),
  is_horror boolean not null default false,
  personal_rating numeric(3,1) check (personal_rating is null or personal_rating between 0 and 10),
  added_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (user_id, rawg_game_id)
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, nickname)
  values (new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'nickname', ''),
             nullif(new.raw_user_meta_data ->> 'name', ''),
             nullif(new.raw_user_meta_data ->> 'full_name', ''), 'Player'))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill anyone who signed up before the trigger existed.
insert into public.profiles (id, nickname)
select id, coalesce(nullif(raw_user_meta_data ->> 'nickname', ''),
                     nullif(raw_user_meta_data ->> 'name', ''), 'Player')
from auth.users
on conflict (id) do nothing;

alter table public.profiles enable row level security;
alter table public.user_games enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile" on public.profiles for select to authenticated
using ((select auth.uid()) = id);
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

drop policy if exists "Users can view own games" on public.user_games;
create policy "Users can view own games" on public.user_games for select to authenticated
using ((select auth.uid()) = user_id);
drop policy if exists "Users can add own games" on public.user_games;
create policy "Users can add own games" on public.user_games for insert to authenticated
with check ((select auth.uid()) = user_id);
drop policy if exists "Users can update own games" on public.user_games;
create policy "Users can update own games" on public.user_games for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "Users can delete own games" on public.user_games;
create policy "Users can delete own games" on public.user_games for delete to authenticated
using ((select auth.uid()) = user_id);

-- Profile pictures use user-owned folders, with read-only public access for display.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880, array['image/jpeg'])
on conflict (id) do update set public = true, file_size_limit = 5242880,
allowed_mime_types = array['image/jpeg'];

drop policy if exists "Avatar public read" on storage.objects;
create policy "Avatar public read" on storage.objects for select to public
using (bucket_id = 'avatars');

drop policy if exists "Avatar owner insert" on storage.objects;
create policy "Avatar owner insert" on storage.objects for insert to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "Avatar owner update" on storage.objects;
create policy "Avatar owner update" on storage.objects for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists "Avatar owner delete" on storage.objects;
create policy "Avatar owner delete" on storage.objects for delete to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);


create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  delete from public.user_games where user_id = auth.uid();
  delete from public.profiles where id = auth.uid();
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
