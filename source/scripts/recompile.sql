-- This is a post installation script
-- It is used to recompile any invalid oos_util packages
-- Note: can use dbms_utility.compile_schema but only want to modify oos_util objects
-- As such try to manually recompile these objects until they are all valid.
set serveroutput on
declare
  l_count pls_integer;
  l_loop_counter pls_integer := 1;

  l_plsql_ccflags varchar2(4000);
  l_cnt pls_integer;
begin

  -- Conditional compilation

  -- #156: sys.utl_file access
  select count(1)
  into l_cnt
  from (
    select 1
    from user_tab_privs
    where 1=1
      and grantee = user
      and table_name = 'UTL_FILE'
      and owner = 'SYS'
    union
    select 1
    from role_tab_privs
    where 1=1
      and role in (
        select granted_role
        from user_role_privs
        where username = user)
      and table_name = 'UTL_FILE'
      and owner = 'SYS'
  );
  l_plsql_ccflags := 'UTL_FILE:' ||
    case
      when l_cnt > 0 then 'TRUE'
      else 'FALSE'
    end || ''
  ;

  dbms_output.put_line('PLSQL_CCFLAGS=' || l_plsql_ccflags);

  <<start_check>>
  for x in (
    select
      'alter package ' || object_name || ' compile '
      || decode(object_type, 'PACKAGE BODY', 'body')
      || ' PLSQL_CCFLAGS=''' || l_plsql_ccflags || ''''
      as exp
    from user_objects
    where 1=1
      and object_name like 'OOS_UTIL%'
      and object_type like 'PACKAGE%'
      and (1=2
        or l_loop_counter = 1 -- Always recompile first time with the PLSQL_CCFLAGS
        or status != 'VALID'
      )
    ) loop

    -- dbms_output.put_line(x.exp);
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
