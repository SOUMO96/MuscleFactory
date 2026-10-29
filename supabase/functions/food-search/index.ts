// Proxies food search to USDA FoodData Central so the API key stays on the
// server. Normalizes results and caches them into public.foods through the
// cache_usda_foods() RPC, called with the caller's own JWT (not service_role).
import { createClient } from "jsr:@supabase/supabase-js@2";

const USDA_API_KEY = Deno.env.get("USDA_API_KEY");

// USDA nutrient IDs (stable across the API, documented in their guide)
// for the fields this app actually tracks.
const NUTRIENT_IDS = {
  calories: 1008,
  protein: 1003,
  carbs: 1005,
  fat: 1004,
  saturatedFat: 1258,
  fiber: 1079,
  sugar: 2000,
  sodium: 1093,
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function nutrientValue(foodNutrients: unknown[], nutrientId: number): number | null {
  for (const n of foodNutrients as Array<{ nutrientId?: number; nutrientNumber?: string; value?: number }>) {
    if (n.nutrientId === nutrientId) return n.value ?? null;
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    if (!USDA_API_KEY) {
      throw new Error("Food search is not configured (missing USDA_API_KEY).");
    }

    const { query } = await req.json();
    if (typeof query !== "string" || query.trim().length < 2) {
      return new Response(JSON.stringify({ error: "Query must be at least 2 characters." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const usdaUrl = new URL("https://api.nal.usda.gov/fdc/v1/foods/search");
    usdaUrl.searchParams.set("api_key", USDA_API_KEY);
    usdaUrl.searchParams.set("query", query.trim());
    usdaUrl.searchParams.set("pageSize", "15");
    usdaUrl.searchParams.set("dataType", "Foundation,SR Legacy,Branded");

    const usdaRes = await fetch(usdaUrl);
    if (!usdaRes.ok) {
      throw new Error(`USDA API error: ${usdaRes.status}`);
    }
    const usdaJson = await usdaRes.json();
    const foods = (usdaJson.foods ?? []) as Array<{
      fdcId: number;
      description: string;
      brandOwner?: string;
      foodCategory?: string;
      foodNutrients: unknown[];
    }>;

    const items = foods
      .map((f) => ({
        fdcId: String(f.fdcId),
        name: f.description,
        brand: f.brandOwner ?? null,
        category: f.foodCategory ?? null,
        caloriesPer100g: nutrientValue(f.foodNutrients, NUTRIENT_IDS.calories),
        proteinPer100g: nutrientValue(f.foodNutrients, NUTRIENT_IDS.protein),
        carbsPer100g: nutrientValue(f.foodNutrients, NUTRIENT_IDS.carbs),
        fatPer100g: nutrientValue(f.foodNutrients, NUTRIENT_IDS.fat),
        saturatedFatPer100g: nutrientValue(f.foodNutrients, NUTRIENT_IDS.saturatedFat),
        fiberPer100g: nutrientValue(f.foodNutrients, NUTRIENT_IDS.fiber),
        sugarPer100g: nutrientValue(f.foodNutrients, NUTRIENT_IDS.sugar),
        sodiumMgPer100g: nutrientValue(f.foodNutrients, NUTRIENT_IDS.sodium),
      }))
      // A result with no calorie value isn't usable for this app's
      // per-100g scaling -- skip rather than cache a broken row.
      .filter((item) => item.caloriesPer100g !== null);

    if (items.length === 0) {
      return new Response(JSON.stringify({ foods: [] }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const authHeader = req.headers.get("Authorization");
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader ?? "" } } },
    );

    const { data, error } = await supabase.rpc("cache_usda_foods", { items });
    if (error) throw error;

    return new Response(JSON.stringify({ foods: data }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
