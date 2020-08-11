-- This script will ensure that current user has the appropriate privileges
whenever sqlerror exit
set serveroutput on

-- SESSION PRIVILEGES (#34)
declare
    type t_sess_privs is table of pls_integer index by varchar2(50);
    l_sess_privs t_sess_privs;
    l_req_privs t_sess_privs;
    l_priv varchar2(50);
    l_dummy pls_integer;
    l_priv_error  boolean := false;
begin
    l_req_privs('CREATE SESSION')       := 1;
    l_req_privs('CREATE TABLE')         := 1;
    l_req_privs('CREATE PROCEDURE')     := 1;


    for c1 in (select privilege from session_privs) loop
      l_sess_privs(c1.privilege) := 1;
    end loop;  --c1

    dbms_output.put_line('_____________________________________________________________________________');

    l_priv := l_req_privs.first;
    loop
      exit when l_priv is null;
      begin
        l_dummy := l_sess_privs(l_priv);

        exception when no_data_found then
          dbms_output.put_line('Error, the current schema is missing the following privilege: '||l_priv);
          l_priv_error := true;
      end;

      l_priv := l_req_privs.next(l_priv);
    end loop;

    if not l_priv_error then
      dbms_output.put_line('User has all required privileges, installation will continue.');
    end if;

    dbms_output.put_line('_____________________________________________________________________________');

    if l_priv_error then
      raise_application_error (-20000, 'One or more required privileges are missing.');
    end if;

    -- Check that user is NOT oos_util (#35)
    if upper(user) = 'OOS_UTIL' then
      raise_application_error(-20001, 'Can not install in user OOS_UTIL due to naming conflicts. Chose another user');
    end if;
end;
/

whenever sqlerror continue
