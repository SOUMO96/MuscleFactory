-- ensure_classes_through() was callable by anonymous clients: new functions get
-- EXECUTE for PUBLIC by default, and the previous migration only added a grant
-- for `authenticated` without revoking that. The function is SECURITY DEFINER
-- and `target_date` was unbounded, so anyone could flood `classes` with rows.
-- Revoke from PUBLIC/anon, and cap how far ahead one call can generate.
revoke execute on function public.ensure_classes_through(date) from public;
revoke execute on function public.ensure_classes_through(date) from anon;
grant execute on function public.ensure_classes_through(date) to authenticated;

create or replace function public.ensure_classes_through(target_date date)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if target_date > current_date + interval '60 days' then
    raise exception 'target_date too far in the future';
  end if;

  insert into public.classes (name, category, coach_name, location, starts_at, duration_minutes, capacity, template_id)
  select t.name, t.category, t.coach_name, t.location, (d.day + t.start_time) at time zone 'utc', t.duration_minutes, t.capacity, t.id
  from generate_series(current_date, target_date, interval '1 day') as d(day)
  join public.class_templates t on extract(isodow from d.day) = t.dow
  on conflict (template_id, starts_at) where template_id is not null do nothing;
end;
$$;
