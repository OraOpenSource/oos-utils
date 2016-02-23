-- This is a post installation script
-- It is used to recompile any invalid oos_util packages
-- Note: can use dbms_utility.compile_schema but only want to modify oos_util objects
-- As such try to manually recompile these objects until they are all valid.
declare
  l_count pls_integer;
  l_loop_counter pls_integer := 1;
begin

  <<start_check>>
  for x in (
    select
      'alter package ' || object_name || ' compile '
      || decode(object_type, 'PACKAGE BODY', 'body') exp
    from user_objects
    where 1=1
      and object_name like 'OOS_UTIL%'
      and object_type like 'PACKAGE%'
      and status != 'VALID') loop

    execute immediate x.exp;
  end loop;

  select count(1)
  into l_count
  from user_objects
  where 1=1
    and object_name like 'OOS_UTIL%'
    and object_type like 'PACKAGE%'
    and status != 'VALID';

  if l_count > 0 and l_loop_counter <= 10 then
    l_loop_counter := l_loop_counter + 1;
    goto start_check;
  end if;
end;
/
