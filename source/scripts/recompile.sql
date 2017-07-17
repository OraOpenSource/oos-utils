-- This is a post installation script
-- It is used to recompile any invalid oos_util packages
-- Note: can use dbms_utility.compile_schema but only want to modify oos_util objects
-- As such try to manually recompile these objects until they are all valid.
set serveroutput on
declare
  l_count pls_integer;
  l_loop_counter pls_integer := 1;

  l_plsql_ccflags varchar2(4000);
begin

  -- Conditional compilation

  -- #156: sys.utl_file access
  select listagg(cc_flag, ',') within group (order by 1 desc)
  into l_plsql_ccflags
  from (
    -- UTL_FILE
    select 'UTL_FILE:' || decode(count(1), 0, 'FALSE', 'TRUE') cc_flag
    from (
      select table_name, owner
      from user_tab_privs
      where 1=1
        and grantee = user
      union
      select table_name, owner
      from role_tab_privs
      where 1=1
        and role in (
          select granted_role
          from user_role_privs
          where username = user)
      )
    where 1=1
      and table_name = 'UTL_FILE'
      and owner = 'SYS'
    -- APEX
    union all
    select 'APEX:' || decode(count(1), 0, 'FALSE', 'TRUE') cc_flag
    from all_synonyms
    where 1=1
      and owner = 'PUBLIC'
      and synonym_name = 'APEX_APPLICATION'
   );


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
