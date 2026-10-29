-- Meal and nutrition system: a searchable food catalog (seeded local dishes plus
-- cached USDA results), quantity-based nutrition, and favorites. Manual entry
-- still works; the nutrition_entries calorie/macro columns are unchanged.

-- foods: shared, public-read catalog, like `exercises`. Seeded with Indian staples
-- (USDA covers them poorly) and filled with cached USDA results by the
-- food-search Edge Function. No client INSERT policy: otherwise any user could
-- plant wrong nutrition data for everyone.
create table public.foods (
  id uuid primary key default gen_random_uuid(),
  fdc_id text, -- USDA FoodData Central id, null for local-only entries
  name text not null,
  brand text,
  category text,
  calories_per_100g numeric not null,
  protein_g_per_100g numeric not null default 0,
  carbs_g_per_100g numeric not null default 0,
  fat_g_per_100g numeric not null default 0,
  saturated_fat_g_per_100g numeric,
  fiber_g_per_100g numeric,
  sugar_g_per_100g numeric,
  sodium_mg_per_100g numeric,
  source text not null check (source in ('usda', 'local')),
  created_at timestamptz not null default now()
);

create unique index foods_fdc_id_idx on public.foods (fdc_id) where fdc_id is not null;
create index foods_name_idx on public.foods (lower(name));

alter table public.foods enable row level security;

create policy "Anyone can view foods"
  on public.foods for select
  using (true);

-- nutrition_entries: link to a food and quantity. Both columns stay nullable so
-- a manual entry is still a valid row.
alter table public.nutrition_entries
  add column meal_category text not null default 'snack'
    check (meal_category in ('breakfast', 'lunch', 'dinner', 'snack')),
  add column food_id uuid references public.foods (id),
  add column quantity_g numeric;

-- ── favorite_foods ───────────────────────────────────────────────────────────
create table public.favorite_foods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  food_id uuid not null references public.foods (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, food_id)
);

create index favorite_foods_user_id_idx on public.favorite_foods (user_id);

alter table public.favorite_foods enable row level security;

create policy "Users can view their own favorite foods"
  on public.favorite_foods for select
  using (auth.uid() = user_id);

create policy "Users can add their own favorite foods"
  on public.favorite_foods for insert
  with check (auth.uid() = user_id);

create policy "Users can remove their own favorite foods"
  on public.favorite_foods for delete
  using (auth.uid() = user_id);

-- cache_usda_foods: stores a batch of USDA results. Called by the Edge Function
-- with the user's own JWT (not service_role). SECURITY DEFINER because clients
-- can't insert into `foods` directly.
create or replace function public.cache_usda_foods(items jsonb)
returns setof public.foods
language plpgsql
security definer set search_path = public
as $$
begin
  return query
  insert into public.foods (
    fdc_id, name, brand, category, calories_per_100g, protein_g_per_100g,
    carbs_g_per_100g, fat_g_per_100g, saturated_fat_g_per_100g,
    fiber_g_per_100g, sugar_g_per_100g, sodium_mg_per_100g, source
  )
  select
    item ->> 'fdcId',
    item ->> 'name',
    item ->> 'brand',
    item ->> 'category',
    (item ->> 'caloriesPer100g')::numeric,
    coalesce((item ->> 'proteinPer100g')::numeric, 0),
    coalesce((item ->> 'carbsPer100g')::numeric, 0),
    coalesce((item ->> 'fatPer100g')::numeric, 0),
    (item ->> 'saturatedFatPer100g')::numeric,
    (item ->> 'fiberPer100g')::numeric,
    (item ->> 'sugarPer100g')::numeric,
    (item ->> 'sodiumMgPer100g')::numeric,
    'usda'
  from jsonb_array_elements(items) as item
  on conflict (fdc_id) where fdc_id is not null do update set
    name = excluded.name,
    calories_per_100g = excluded.calories_per_100g,
    protein_g_per_100g = excluded.protein_g_per_100g,
    carbs_g_per_100g = excluded.carbs_g_per_100g,
    fat_g_per_100g = excluded.fat_g_per_100g
  returning foods.*;
end;
$$;

grant execute on function public.cache_usda_foods(jsonb) to authenticated;

-- Seed: common Indian dishes and staples, per 100g (cooked unless noted).
insert into public.foods (name, category, calories_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, fiber_g_per_100g, sugar_g_per_100g, sodium_mg_per_100g, source) values
  ('Roti (whole wheat, plain)', 'Indian - Breads', 297, 11.0, 58.0, 4.0, 10.0, 1.0, 400, 'local'),
  ('Chapati (plain)', 'Indian - Breads', 297, 11.0, 58.0, 4.0, 10.0, 1.0, 400, 'local'),
  ('Naan (plain)', 'Indian - Breads', 310, 9.0, 50.0, 8.0, 2.0, 3.0, 500, 'local'),
  ('Paratha (plain)', 'Indian - Breads', 330, 6.5, 45.0, 14.0, 3.5, 1.0, 400, 'local'),
  ('Puri', 'Indian - Breads', 370, 6.0, 40.0, 20.0, 2.0, 1.0, 300, 'local'),
  ('Steamed Rice (white)', 'Indian - Grains', 130, 2.7, 28.0, 0.3, 0.4, 0.1, 1, 'local'),
  ('Jeera Rice', 'Indian - Grains', 185, 3.5, 32.0, 5.0, 0.8, 0.3, 300, 'local'),
  ('Biryani (chicken)', 'Indian - Rice dishes', 165, 9.0, 18.0, 6.5, 1.0, 1.5, 450, 'local'),
  ('Biryani (vegetable)', 'Indian - Rice dishes', 145, 3.5, 20.0, 5.5, 2.0, 2.0, 420, 'local'),
  ('Pulao (vegetable)', 'Indian - Rice dishes', 150, 3.0, 24.0, 4.5, 1.5, 1.5, 380, 'local'),
  ('Dal Tadka', 'Indian - Lentils/Curries', 110, 6.5, 15.0, 3.0, 4.0, 1.5, 350, 'local'),
  ('Dal Makhani', 'Indian - Lentils/Curries', 150, 7.0, 15.0, 7.5, 4.5, 2.0, 400, 'local'),
  ('Sambar', 'Indian - Lentils/Curries', 85, 4.0, 12.0, 2.5, 3.0, 2.0, 380, 'local'),
  ('Rajma (kidney bean curry)', 'Indian - Lentils/Curries', 130, 7.5, 18.0, 3.5, 6.0, 2.5, 350, 'local'),
  ('Chole (chickpea curry)', 'Indian - Lentils/Curries', 150, 7.5, 20.0, 5.0, 6.5, 3.0, 400, 'local'),
  ('Palak Paneer', 'Indian - Curries', 180, 8.5, 8.0, 13.0, 2.5, 3.0, 420, 'local'),
  ('Paneer Butter Masala', 'Indian - Curries', 240, 9.0, 10.0, 18.0, 1.5, 5.0, 450, 'local'),
  ('Chicken Curry', 'Indian - Curries', 165, 15.0, 6.0, 9.5, 1.0, 2.0, 420, 'local'),
  ('Butter Chicken', 'Indian - Curries', 220, 14.0, 8.0, 15.0, 1.0, 4.0, 480, 'local'),
  ('Chicken Tikka Masala', 'Indian - Curries', 195, 16.0, 7.0, 11.5, 1.0, 3.5, 460, 'local'),
  ('Aloo Gobi', 'Indian - Curries', 110, 2.5, 14.0, 5.5, 3.0, 2.5, 350, 'local'),
  ('Aloo Paratha', 'Indian - Breads', 260, 5.5, 36.0, 10.0, 3.5, 1.5, 420, 'local'),
  ('Bhindi Masala', 'Indian - Curries', 105, 2.5, 10.0, 6.5, 3.5, 2.0, 320, 'local'),
  ('Baingan Bharta', 'Indian - Curries', 95, 2.0, 10.0, 5.5, 3.5, 3.0, 340, 'local'),
  ('Idli', 'Indian - South Indian', 150, 4.0, 30.0, 0.8, 1.5, 0.5, 300, 'local'),
  ('Dosa (plain)', 'Indian - South Indian', 170, 3.5, 28.0, 4.5, 1.0, 0.5, 320, 'local'),
  ('Masala Dosa', 'Indian - South Indian', 200, 4.0, 30.0, 7.0, 1.5, 1.0, 380, 'local'),
  ('Upma', 'Indian - South Indian', 130, 3.0, 20.0, 4.5, 2.0, 1.0, 350, 'local'),
  ('Poha', 'Indian - Breakfast', 130, 2.5, 24.0, 3.5, 1.5, 1.5, 300, 'local'),
  ('Samosa', 'Indian - Snacks', 260, 4.5, 28.0, 15.0, 2.5, 1.5, 400, 'local'),
  ('Pakora (vegetable)', 'Indian - Snacks', 280, 6.0, 25.0, 17.0, 3.0, 1.0, 380, 'local'),
  ('Chaat (bhel puri)', 'Indian - Snacks', 150, 3.5, 25.0, 4.0, 2.5, 5.0, 450, 'local'),
  ('Curd/Dahi (plain)', 'Indian - Dairy', 60, 3.5, 4.5, 3.0, 0, 4.5, 50, 'local'),
  ('Raita', 'Indian - Dairy', 65, 3.0, 5.5, 3.0, 0.5, 3.5, 150, 'local'),
  ('Lassi (sweet)', 'Indian - Beverages', 95, 2.5, 15.0, 2.5, 0, 14.0, 60, 'local'),
  ('Gulab Jamun', 'Indian - Desserts', 330, 4.5, 45.0, 15.0, 0.5, 40.0, 60, 'local'),
  ('Kheer', 'Indian - Desserts', 160, 4.0, 22.0, 6.0, 0.3, 18.0, 70, 'local'),
  ('Jalebi', 'Indian - Desserts', 375, 2.0, 60.0, 15.0, 0.5, 50.0, 40, 'local'),
  ('Chicken Tandoori', 'Indian - Grilled/Tandoor', 165, 25.0, 2.5, 6.0, 0, 1.0, 450, 'local'),
  ('Seekh Kebab (chicken)', 'Indian - Grilled/Tandoor', 220, 20.0, 3.0, 14.0, 0.5, 1.0, 480, 'local'),
  ('Egg Curry', 'Indian - Curries', 150, 9.0, 6.0, 10.5, 1.0, 2.0, 400, 'local'),
  ('Khichdi', 'Indian - Rice dishes', 120, 4.5, 20.0, 2.5, 2.0, 0.5, 300, 'local'),
  ('Vegetable Korma', 'Indian - Curries', 140, 3.0, 12.0, 9.0, 2.5, 3.0, 380, 'local'),
  ('Peanut Chutney', 'Indian - Condiments', 290, 13.0, 12.0, 23.0, 5.0, 2.0, 350, 'local'),
  ('Coconut Chutney', 'Indian - Condiments', 230, 3.5, 7.0, 21.0, 4.5, 2.0, 300, 'local'),
  ('Tamarind Chutney', 'Indian - Condiments', 180, 1.0, 44.0, 0.3, 1.5, 35.0, 400, 'local'),
  ('Roasted Chana (chickpeas)', 'Indian - Snacks', 364, 19.0, 61.0, 6.0, 17.0, 11.0, 15, 'local'),
  ('Paneer (raw)', 'Indian - Dairy', 265, 18.0, 1.2, 20.8, 0, 1.2, 20, 'local'),
  ('Ghee', 'Indian - Fats', 900, 0, 0, 100, 0, 0, 0, 'local'),
  ('Rasam', 'Indian - South Indian', 55, 1.5, 9.0, 1.5, 1.0, 1.5, 350, 'local'),
  ('Vada (medu vada)', 'Indian - South Indian', 245, 7.0, 28.0, 12.0, 3.0, 1.0, 380, 'local');
