-- Replaces the one-shot class seed with weekly templates plus a function that
-- tops up the next 14 days on every Classes load. The old seed inserted a fixed
-- window of dates, so the schedule went empty once they had passed.

create table public.class_templates (
  id uuid primary key default gen_random_uuid(),
  dow integer not null check (dow between 1 and 7),
  start_time time not null,
  name text not null,
  category text not null,
  coach_name text not null,
  location text not null,
  duration_minutes integer not null,
  capacity integer not null
);

alter table public.class_templates enable row level security;

create policy "Anyone can view class templates"
  on public.class_templates for select
  using (true);

insert into public.class_templates (dow, start_time, name, category, coach_name, location, duration_minutes, capacity) values
  (1, time '07:00', 'Strength Circuit', 'Strength', 'Coach Marco', 'Factory East', 45, 16),
  (1, time '12:15', 'Core Express', 'Mobility', 'Coach Lina', 'Factory East', 30, 14),
  (1, time '18:30', 'HIIT 45', 'HIIT', 'Coach Dana', 'Factory East', 45, 20),
  (1, time '19:30', 'Olympic Lifting', 'Strength', 'Coach Marco', 'Factory East', 60, 10),
  (1, time '20:45', 'Mobility Flow', 'Mobility', 'Coach Lina', 'Factory East', 40, 16),
  (3, time '07:00', 'Strength Circuit', 'Strength', 'Coach Marco', 'Factory East', 45, 16),
  (3, time '18:00', 'HIIT 45', 'HIIT', 'Coach Dana', 'Factory East', 45, 20),
  (3, time '19:15', 'Core Express', 'Mobility', 'Coach Lina', 'Factory East', 30, 14),
  (5, time '07:00', 'Olympic Lifting', 'Strength', 'Coach Marco', 'Factory East', 60, 10),
  (5, time '17:30', 'HIIT 45', 'HIIT', 'Coach Dana', 'Factory East', 45, 20),
  (5, time '18:45', 'Mobility Flow', 'Mobility', 'Coach Lina', 'Factory East', 40, 16),
  (6, time '09:00', 'Strength Circuit', 'Strength', 'Coach Marco', 'Factory East', 45, 16),
  (6, time '10:15', 'Core Express', 'Mobility', 'Coach Lina', 'Factory East', 30, 14);

alter table public.classes add column template_id uuid references public.class_templates (id);

-- One occurrence per (template, date), so ensure_classes_through can run on
-- every Classes load without duplicating rows.
create unique index classes_template_starts_at_idx on public.classes (template_id, starts_at) where template_id is not null;

-- security definer so it can insert into `classes`, which clients can't write to
-- (same pattern as handle_new_user() for profiles).
create or replace function public.ensure_classes_through(target_date date)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.classes (name, category, coach_name, location, starts_at, duration_minutes, capacity, template_id)
  select t.name, t.category, t.coach_name, t.location, (d.day + t.start_time) at time zone 'utc', t.duration_minutes, t.capacity, t.id
  from generate_series(current_date, target_date, interval '1 day') as d(day)
  join public.class_templates t on extract(isodow from d.day) = t.dow
  on conflict (template_id, starts_at) where template_id is not null do nothing;
end;
$$;

grant execute on function public.ensure_classes_through(date) to authenticated;
