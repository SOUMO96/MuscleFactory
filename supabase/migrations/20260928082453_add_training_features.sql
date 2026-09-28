-- Phase 2 of the Modernist redesign: schema for the new Train / Classes /
-- Progress / Nutrition / Membership features. Owner-only RLS for user data;
-- public read-only for catalog tables (exercises, classes).

-- ── profiles: new preference + onboarding fields ───────────────────────────
alter table public.profiles
  add column training_days_per_week integer,
  add column theme_preference text not null default 'system'
    check (theme_preference in ('light', 'dark', 'system')),
  add column unit_preference text not null default 'kg'
    check (unit_preference in ('kg', 'lb')),
  add column default_rest_seconds integer not null default 90,
  add column workout_reminders_enabled boolean not null default false;

-- ── exercises: public catalog ───────────────────────────────────────────────
create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  equipment text not null,
  description text not null default ''
);

alter table public.exercises enable row level security;

create policy "Anyone can view exercises"
  on public.exercises for select
  using (true);

-- ── workout_plans / plan_days / plan_exercises ──────────────────────────────
create table public.workout_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  source text not null check (source in ('ai', 'custom', 'import')),
  days_per_week integer not null,
  duration_weeks integer,
  level text,
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

create index workout_plans_user_id_idx on public.workout_plans (user_id);

alter table public.workout_plans enable row level security;

create policy "Users can view their own plans"
  on public.workout_plans for select
  using (auth.uid() = user_id);

create policy "Users can create their own plans"
  on public.workout_plans for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own plans"
  on public.workout_plans for update
  using (auth.uid() = user_id);

create policy "Users can delete their own plans"
  on public.workout_plans for delete
  using (auth.uid() = user_id);

create table public.plan_days (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.workout_plans (id) on delete cascade,
  day_index integer not null,
  label text not null
);

create index plan_days_plan_id_idx on public.plan_days (plan_id);

alter table public.plan_days enable row level security;

create policy "Users can view days of their own plans"
  on public.plan_days for select
  using (exists (select 1 from public.workout_plans wp where wp.id = plan_days.plan_id and wp.user_id = auth.uid()));

create policy "Users can manage days of their own plans"
  on public.plan_days for insert
  with check (exists (select 1 from public.workout_plans wp where wp.id = plan_days.plan_id and wp.user_id = auth.uid()));

create policy "Users can update days of their own plans"
  on public.plan_days for update
  using (exists (select 1 from public.workout_plans wp where wp.id = plan_days.plan_id and wp.user_id = auth.uid()));

create policy "Users can delete days of their own plans"
  on public.plan_days for delete
  using (exists (select 1 from public.workout_plans wp where wp.id = plan_days.plan_id and wp.user_id = auth.uid()));

create table public.plan_exercises (
  id uuid primary key default gen_random_uuid(),
  plan_day_id uuid not null references public.plan_days (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id),
  order_index integer not null default 0,
  target_sets integer not null,
  target_reps text not null,
  notes text
);

create index plan_exercises_plan_day_id_idx on public.plan_exercises (plan_day_id);

alter table public.plan_exercises enable row level security;

create policy "Users can view exercises of their own plan days"
  on public.plan_exercises for select
  using (exists (
    select 1 from public.plan_days pd
    join public.workout_plans wp on wp.id = pd.plan_id
    where pd.id = plan_exercises.plan_day_id and wp.user_id = auth.uid()
  ));

create policy "Users can manage exercises of their own plan days"
  on public.plan_exercises for insert
  with check (exists (
    select 1 from public.plan_days pd
    join public.workout_plans wp on wp.id = pd.plan_id
    where pd.id = plan_exercises.plan_day_id and wp.user_id = auth.uid()
  ));

create policy "Users can update exercises of their own plan days"
  on public.plan_exercises for update
  using (exists (
    select 1 from public.plan_days pd
    join public.workout_plans wp on wp.id = pd.plan_id
    where pd.id = plan_exercises.plan_day_id and wp.user_id = auth.uid()
  ));

create policy "Users can delete exercises of their own plan days"
  on public.plan_exercises for delete
  using (exists (
    select 1 from public.plan_days pd
    join public.workout_plans wp on wp.id = pd.plan_id
    where pd.id = plan_exercises.plan_day_id and wp.user_id = auth.uid()
  ));

-- ── workout_sessions / logged_sets ──────────────────────────────────────────
create table public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_day_id uuid references public.plan_days (id) on delete set null,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create index workout_sessions_user_id_idx on public.workout_sessions (user_id);

alter table public.workout_sessions enable row level security;

create policy "Users can view their own sessions"
  on public.workout_sessions for select
  using (auth.uid() = user_id);

create policy "Users can create their own sessions"
  on public.workout_sessions for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own sessions"
  on public.workout_sessions for update
  using (auth.uid() = user_id);

create policy "Users can delete their own sessions"
  on public.workout_sessions for delete
  using (auth.uid() = user_id);

create table public.logged_sets (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workout_sessions (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id),
  set_index integer not null,
  weight_kg double precision,
  reps integer,
  completed_at timestamptz not null default now()
);

create index logged_sets_session_id_idx on public.logged_sets (session_id);
create index logged_sets_exercise_id_idx on public.logged_sets (exercise_id);

alter table public.logged_sets enable row level security;

create policy "Users can view sets of their own sessions"
  on public.logged_sets for select
  using (exists (select 1 from public.workout_sessions ws where ws.id = logged_sets.session_id and ws.user_id = auth.uid()));

create policy "Users can log sets on their own sessions"
  on public.logged_sets for insert
  with check (exists (select 1 from public.workout_sessions ws where ws.id = logged_sets.session_id and ws.user_id = auth.uid()));

create policy "Users can update sets of their own sessions"
  on public.logged_sets for update
  using (exists (select 1 from public.workout_sessions ws where ws.id = logged_sets.session_id and ws.user_id = auth.uid()));

create policy "Users can delete sets of their own sessions"
  on public.logged_sets for delete
  using (exists (select 1 from public.workout_sessions ws where ws.id = logged_sets.session_id and ws.user_id = auth.uid()));

-- ── classes / class_bookings ─────────────────────────────────────────────────
create table public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  coach_name text not null,
  location text not null,
  starts_at timestamptz not null,
  duration_minutes integer not null,
  capacity integer not null
);

create index classes_starts_at_idx on public.classes (starts_at);

alter table public.classes enable row level security;

create policy "Anyone can view classes"
  on public.classes for select
  using (true);

create table public.class_bookings (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null check (status in ('booked', 'waitlisted', 'cancelled')),
  created_at timestamptz not null default now(),
  unique (class_id, user_id)
);

create index class_bookings_user_id_idx on public.class_bookings (user_id);

alter table public.class_bookings enable row level security;

create policy "Users can view their own bookings"
  on public.class_bookings for select
  using (auth.uid() = user_id);

create policy "Users can create their own bookings"
  on public.class_bookings for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own bookings"
  on public.class_bookings for update
  using (auth.uid() = user_id);

create policy "Users can delete their own bookings"
  on public.class_bookings for delete
  using (auth.uid() = user_id);

-- ── nutrition_entries ────────────────────────────────────────────────────────
create table public.nutrition_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  entry_date date not null default current_date,
  meal_label text not null,
  calories integer not null,
  protein_g double precision,
  carbs_g double precision,
  fat_g double precision,
  logged_at timestamptz not null default now()
);

create index nutrition_entries_user_id_date_idx on public.nutrition_entries (user_id, entry_date);

alter table public.nutrition_entries enable row level security;

create policy "Users can view their own nutrition entries"
  on public.nutrition_entries for select
  using (auth.uid() = user_id);

create policy "Users can create their own nutrition entries"
  on public.nutrition_entries for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own nutrition entries"
  on public.nutrition_entries for update
  using (auth.uid() = user_id);

create policy "Users can delete their own nutrition entries"
  on public.nutrition_entries for delete
  using (auth.uid() = user_id);

-- ── seed: exercise catalog ──────────────────────────────────────────────────
insert into public.exercises (name, category, equipment, description) values
  ('Barbell Bench Press', 'Chest', 'Barbell', 'Flat bench press, primary chest builder.'),
  ('Incline Barbell Press', 'Chest', 'Barbell', 'Upper-chest focused press on an incline bench.'),
  ('Incline Dumbbell Press', 'Chest', 'Dumbbell', 'Unilateral upper-chest press.'),
  ('Flat Dumbbell Press', 'Chest', 'Dumbbell', 'Flat-bench dumbbell press for chest.'),
  ('Dumbbell Fly', 'Chest', 'Dumbbell', 'Isolation fly for chest stretch and squeeze.'),
  ('Cable Crossover', 'Chest', 'Cable', 'Cable fly for constant-tension chest isolation.'),
  ('Chest Dip', 'Chest', 'Bodyweight', 'Bodyweight dip leaned forward for chest emphasis.'),
  ('Push-Up', 'Chest', 'Bodyweight', 'Classic bodyweight chest/triceps/shoulder press.'),
  ('Machine Chest Press', 'Chest', 'Machine', 'Guided horizontal press for chest.'),
  ('Pec Deck', 'Chest', 'Machine', 'Machine fly for chest isolation.'),
  ('Deadlift', 'Back', 'Barbell', 'Full posterior-chain hip hinge, the ultimate back/leg builder.'),
  ('Romanian Deadlift', 'Back', 'Barbell', 'Hip-hinge variation emphasizing hamstrings and lower back.'),
  ('Barbell Row', 'Back', 'Barbell', 'Bent-over row for mid-back thickness.'),
  ('Pendlay Row', 'Back', 'Barbell', 'Dead-stop row for strict back power.'),
  ('T-Bar Row', 'Back', 'Barbell', 'Chest-supported thick-grip row.'),
  ('Dumbbell Row', 'Back', 'Dumbbell', 'Unilateral row for back thickness.'),
  ('Lat Pulldown', 'Back', 'Cable', 'Vertical pull for lat width.'),
  ('Pull-Up', 'Back', 'Bodyweight', 'Bodyweight vertical pull, the benchmark back exercise.'),
  ('Chin-Up', 'Back', 'Bodyweight', 'Underhand vertical pull, more biceps involvement.'),
  ('Cable Row', 'Back', 'Cable', 'Seated horizontal row for back thickness.'),
  ('Face Pull', 'Back', 'Cable', 'Rear-delt and upper-back health exercise.'),
  ('Back Extension', 'Back', 'Bodyweight', 'Lower-back and glute isolation on a hyperextension bench.'),
  ('Back Squat', 'Legs', 'Barbell', 'Barbell squat, the king of leg exercises.'),
  ('Front Squat', 'Legs', 'Barbell', 'Quad-dominant squat variation.'),
  ('Leg Press', 'Legs', 'Machine', 'Machine-guided squat pattern.'),
  ('Bulgarian Split Squat', 'Legs', 'Dumbbell', 'Rear-foot-elevated unilateral squat.'),
  ('Walking Lunge', 'Legs', 'Dumbbell', 'Unilateral leg exercise through a walking pattern.'),
  ('Leg Extension', 'Legs', 'Machine', 'Quad isolation machine.'),
  ('Lying Leg Curl', 'Legs', 'Machine', 'Hamstring isolation machine.'),
  ('Seated Leg Curl', 'Legs', 'Machine', 'Hamstring isolation, seated variation.'),
  ('Hip Thrust', 'Legs', 'Barbell', 'Glute-focused hip extension.'),
  ('Goblet Squat', 'Legs', 'Dumbbell', 'Front-loaded squat for beginners and warm-ups.'),
  ('Standing Calf Raise', 'Legs', 'Machine', 'Calf isolation, standing variation.'),
  ('Seated Calf Raise', 'Legs', 'Machine', 'Calf isolation targeting the soleus.'),
  ('Hack Squat', 'Legs', 'Machine', 'Machine squat with back support.'),
  ('Overhead Press', 'Shoulders', 'Barbell', 'Standing barbell press, primary shoulder builder.'),
  ('Seated Dumbbell Press', 'Shoulders', 'Dumbbell', 'Seated shoulder press for stability.'),
  ('Arnold Press', 'Shoulders', 'Dumbbell', 'Rotational dumbbell press hitting all three delt heads.'),
  ('Lateral Raise', 'Shoulders', 'Dumbbell', 'Side-delt isolation.'),
  ('Cable Lateral Raise', 'Shoulders', 'Cable', 'Constant-tension side-delt isolation.'),
  ('Front Raise', 'Shoulders', 'Dumbbell', 'Front-delt isolation.'),
  ('Rear Delt Fly', 'Shoulders', 'Dumbbell', 'Rear-delt isolation, bent-over variation.'),
  ('Machine Shoulder Press', 'Shoulders', 'Machine', 'Guided vertical press for shoulders.'),
  ('Upright Row', 'Shoulders', 'Barbell', 'Vertical pull hitting side delts and traps.'),
  ('Shrug', 'Shoulders', 'Barbell', 'Trap isolation.'),
  ('Barbell Curl', 'Arms', 'Barbell', 'Classic biceps mass builder.'),
  ('Dumbbell Curl', 'Arms', 'Dumbbell', 'Biceps isolation, unilateral.'),
  ('Hammer Curl', 'Arms', 'Dumbbell', 'Biceps/brachialis curl with neutral grip.'),
  ('Preacher Curl', 'Arms', 'Barbell', 'Strict biceps isolation on a preacher bench.'),
  ('Cable Curl', 'Arms', 'Cable', 'Constant-tension biceps isolation.'),
  ('Close-Grip Bench Press', 'Arms', 'Barbell', 'Triceps-focused pressing movement.'),
  ('Triceps Pushdown', 'Arms', 'Cable', 'Triceps isolation on a cable stack.'),
  ('Skull Crusher', 'Arms', 'Barbell', 'Lying triceps extension.'),
  ('Overhead Triceps Extension', 'Arms', 'Dumbbell', 'Triceps isolation with overhead stretch.'),
  ('Dip', 'Arms', 'Bodyweight', 'Bodyweight triceps/chest compound.'),
  ('Plank', 'Core', 'Bodyweight', 'Isometric core stability hold.'),
  ('Hanging Leg Raise', 'Core', 'Bodyweight', 'Lower-ab and hip flexor exercise.'),
  ('Cable Crunch', 'Core', 'Cable', 'Weighted ab flexion.'),
  ('Russian Twist', 'Core', 'Bodyweight', 'Rotational core exercise.'),
  ('Ab Wheel Rollout', 'Core', 'Bodyweight', 'Advanced anti-extension core exercise.'),
  ('Side Plank', 'Core', 'Bodyweight', 'Oblique isometric hold.'),
  ('Mountain Climber', 'Core', 'Bodyweight', 'Dynamic core and conditioning movement.'),
  ('Treadmill Run', 'Cardio', 'Machine', 'Steady-state or interval running.'),
  ('Rowing Machine', 'Cardio', 'Machine', 'Full-body cardio and conditioning.'),
  ('Stationary Bike', 'Cardio', 'Machine', 'Low-impact cardio conditioning.'),
  ('Jump Rope', 'Cardio', 'Bodyweight', 'High-tempo cardio and coordination.'),
  ('Kettlebell Swing', 'Cardio', 'Kettlebell', 'Explosive hip-hinge conditioning movement.'),
  ('Battle Ropes', 'Cardio', 'Equipment', 'High-intensity upper-body conditioning.'),
  ('Box Jump', 'Cardio', 'Bodyweight', 'Explosive lower-body power and conditioning.'),
  ('Burpee', 'Cardio', 'Bodyweight', 'Full-body conditioning movement.');

-- ── seed: recurring weekly class schedule (next 14 days) ────────────────────
with templates(dow, start_time, name, category, coach_name, location, duration_minutes, capacity) as (
  values
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
    (6, time '10:15', 'Core Express', 'Mobility', 'Coach Lina', 'Factory East', 30, 14)
),
days as (
  select generate_series(current_date, current_date + interval '13 days', interval '1 day')::date as d
)
insert into public.classes (name, category, coach_name, location, starts_at, duration_minutes, capacity)
select t.name, t.category, t.coach_name, t.location, (days.d + t.start_time) at time zone 'utc', t.duration_minutes, t.capacity
from days
join templates t on extract(isodow from days.d) = t.dow;
