-- User profile, one row per auth.users row. Created automatically by a
-- trigger on auth.users insert, so it exists for every sign-up method
-- (email/password and OAuth/Google alike).
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null default '',
  display_name text not null default 'Athlete',
  photo_url text,
  created_at timestamptz not null default now(),

  -- Onboarding survey fields, null until completed.
  age integer,
  gender text,
  height_cm double precision,
  current_weight_kg double precision,
  goal text,
  target_weight_kg double precision,
  goal_duration_weeks integer,
  survey_completed boolean not null default false
);

alter table public.profiles enable row level security;

create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create a bare-bones profile row whenever a new auth user is
-- created, using whatever the sign-up method provided (display_name from
-- email/password sign-up's metadata, or Google's name/avatar via OAuth).
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, photo_url)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      'Athlete'
    ),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
