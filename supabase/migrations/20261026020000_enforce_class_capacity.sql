-- Capacity was only checked in the app, so a direct REST call with a valid token
-- could book past a class's capacity (RLS only checks auth.uid() = user_id).
-- This trigger enforces it in the database.
create or replace function public.check_class_capacity()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  seats_taken integer;
  seats_total integer;
begin
  if new.status <> 'booked' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.status = 'booked' then
    return new; -- not newly taking a seat
  end if;

  select capacity into seats_total from public.classes where id = new.class_id;
  select count(*) into seats_taken from public.class_bookings
    where class_id = new.class_id and status = 'booked' and id is distinct from new.id;

  if seats_taken >= seats_total then
    raise exception 'Class is full' using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger enforce_class_capacity
  before insert or update on public.class_bookings
  for each row execute procedure public.check_class_capacity();
