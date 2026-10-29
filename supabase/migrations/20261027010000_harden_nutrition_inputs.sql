-- Hardening for the nutrition feature.
-- cache_usda_foods() was open to every authenticated user with no validation, so
-- anyone could call it directly to write made-up values into the shared `foods`
-- catalog, or spam duplicate rows by omitting fdcId (a null never hits the
-- upsert's conflict target). It now validates each item. The nutrition_entries
-- limits below live here, not just in the UI, since the client can be bypassed.
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
    left(item ->> 'name', 200),
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
  where
    -- fdc_id is required: real USDA results always have one, and a null never hits
    -- the upsert's conflict target, so it would insert a new row on every call.
    coalesce(item ->> 'fdcId', '') <> ''
    and coalesce(item ->> 'name', '') <> ''
    and (item ->> 'caloriesPer100g') ~ '^[0-9.]+$'
    and (item ->> 'caloriesPer100g')::numeric between 0 and 950
    and coalesce((item ->> 'proteinPer100g')::numeric, 0) between 0 and 100
    and coalesce((item ->> 'carbsPer100g')::numeric, 0) between 0 and 100
    and coalesce((item ->> 'fatPer100g')::numeric, 0) between 0 and 100
  on conflict (fdc_id) where fdc_id is not null do update set
    name = excluded.name,
    calories_per_100g = excluded.calories_per_100g,
    protein_g_per_100g = excluded.protein_g_per_100g,
    carbs_g_per_100g = excluded.carbs_g_per_100g,
    fat_g_per_100g = excluded.fat_g_per_100g
  returning foods.*;
end;
$$;

-- Table-level limits too, so a bug in the function isn't the only guard on the
-- shared catalog.
alter table public.foods
  add constraint foods_calories_range check (calories_per_100g >= 0 and calories_per_100g <= 950),
  add constraint foods_protein_range check (protein_g_per_100g >= 0 and protein_g_per_100g <= 100),
  add constraint foods_carbs_range check (carbs_g_per_100g >= 0 and carbs_g_per_100g <= 100),
  add constraint foods_fat_range check (fat_g_per_100g >= 0 and fat_g_per_100g <= 100),
  add constraint foods_name_length check (char_length(name) between 1 and 200);

-- Limits on logged entries: manual calories/macros and quantity-derived values
-- both land here.
alter table public.nutrition_entries
  add constraint nutrition_entries_calories_range check (calories >= 0 and calories <= 20000),
  add constraint nutrition_entries_protein_range check (protein_g is null or (protein_g >= 0 and protein_g <= 2000)),
  add constraint nutrition_entries_carbs_range check (carbs_g is null or (carbs_g >= 0 and carbs_g <= 2000)),
  add constraint nutrition_entries_fat_range check (fat_g is null or (fat_g >= 0 and fat_g <= 2000)),
  add constraint nutrition_entries_quantity_range check (quantity_g is null or (quantity_g > 0 and quantity_g <= 10000));
