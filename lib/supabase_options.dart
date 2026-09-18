/// Supabase project connection details.
///
/// The publishable/anon key is safe to ship in client code by design --
/// it's meant to be public, with access actually enforced by Postgres Row
/// Level Security policies (see supabase/migrations/). Never put the
/// secret/service_role key here.
class SupabaseOptions {
  SupabaseOptions._();

  static const String url = 'https://gixazqpnofouxroakpet.supabase.co';
  static const String publishableKey = 'sb_publishable_xzs8I_FCZwxRNmHYEV1MSw_nTFppOu_';
}
