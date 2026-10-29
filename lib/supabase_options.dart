/// Supabase connection details.
/// The publishable key is meant to be public; Row Level Security does the
/// enforcing (see supabase/migrations/). Never put the service_role key here.
class SupabaseOptions {
  SupabaseOptions._();

  static const String url = 'https://gixazqpnofouxroakpet.supabase.co';
  static const String publishableKey = 'sb_publishable_xzs8I_FCZwxRNmHYEV1MSw_nTFppOu_';
}
