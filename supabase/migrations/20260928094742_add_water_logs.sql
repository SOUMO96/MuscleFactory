-- Water intake tracking (Home's "Water" quick action, Nutrition's water row).
create table public.water_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  entry_date date not null default current_date,
  amount_ml integer not null,
  logged_at timestamptz not null default now()
);

create index water_logs_user_id_date_idx on public.water_logs (user_id, entry_date);

alter table public.water_logs enable row level security;

create policy "Users can view their own water logs"
  on public.water_logs for select
  using (auth.uid() = user_id);

create policy "Users can create their own water logs"
  on public.water_logs for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own water logs"
  on public.water_logs for delete
  using (auth.uid() = user_id);
