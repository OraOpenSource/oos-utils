-- DO NOT MODIFY THIS FILE. IT IS AUTO GENERATED

prompt *** OOS_UTILS ***


prompt *** Prereqs OOS_UTILS ***

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



prompt *** Installing OOS_UTILS ***



prompt *** TABLES ***

prompt oos_util_values

declare
  l_count pls_integer;
  l_table_name user_tables.table_name%type;
  l_sql varchar2(4000);
begin
  l_table_name := lower('oos_util_values');

  select count(1)
  into l_count
  from user_tables
  where 1=1
    and table_name = upper(l_table_name);

  if l_count = 0 then
    l_sql := 'create table %table_name% (
  cat varchar2(255) not null,
  name varchar2(255) not null,
  value varchar2(255) not null,
  constraint %table_name%_uk1 unique (cat,name)
)';
    l_sql := replace(l_sql, '%table_name%', l_table_name);

  end if;

  if l_sql is not null then
    execute immediate l_sql;
  end if;

end;
/

prompt *** PACKAGES ***

prompt oos_util
create or replace package oos_util
as
  -- CONSTANTS
  /**
   * @constant gc_date_format default date format
   * @constant gc_timestamp_format default timestamp format
   * @constant gc_timestamp_tz_format default timestamp (with TZ) format
   */
  gc_date_format constant varchar2(255) := 'DD-MON-YYYY HH24:MI:SS';
  gc_timestamp_format constant varchar2(255) := gc_date_format || ':FF';
  gc_timestamp_tz_format constant varchar2(255) := gc_timestamp_format || ' TZR';

  -- OOS Util Val Cats
  gc_vals_cat_mime_type constant oos_util_values.cat%type := 'mime-type';

  gc_version constant varchar2(10) := '1.0.0';

  procedure assert(
    p_condition in boolean,
    p_msg in varchar2);

  procedure sleep(
    p_seconds in simple_integer);

end oos_util;
/

create or replace package body oos_util
as
  -- CONSTANTS

  gc_assert_error_number constant pls_integer := -20000;


  -- ******** PRIVATE ********

  /**
   * Internal logging procedure.
   * Requires Logger to be installed only while developing.
   * -- TODO mdsouza: conditional compilation notes
   *
   *
   * @author Martin D'Souza
   * @created 17-Aug-2015
   * @param p_message Item to log
   * @param p_scope Logger scope
   */
  procedure log(
    p_text in varchar2,
    p_scope in varchar2)
  as
  begin
    $if $$oos_util_debug $then
      logger.log(p_text, p_scope);
    $else
      null;
    $end
  end log;

  -- ******** PUBLIC ********


  /**
   * Validates assertion.
   * Will raise an application error if assertion is false
   *
   * @example
   *
   * oos_util.assert(1=2, 'this assertion did not pass');
   *
   * -- Results in
   *
   * Error starting at line : 1 in command -
   * exec oos_util.assert(1=2, 'this assertion did not pass')
   * Error report -
   * ORA-06550: line 1, column 7:
   * PLS-00306: wrong number or types of arguments in call to 'ASSERT'
   * ORA-06550: line 1, column 7:
   * PL/SQL: Statement ignored
   * 06550. 00000 -  "line %s, column %s:\n%s"
   * *Cause:    Usually a PL/SQL compilation error.
   * *Action:

   * @issue #19
   *
   * @author Martin D'Souza
   * @created 05-Sep-2015
   * @param p_condition Boolean condition to validate
   * @param p_msg Message to include in application error if p_condition fails
   */
  procedure assert(
    p_condition in boolean,
    p_msg in varchar2)
  as
  begin
    if not p_condition or p_condition is null then
      raise_application_error(gc_assert_error_number, p_msg);
    end if;
  end assert;


  /**
   * Sleep procedure for n seconds
   *
   * Notes:
   *  - It is recommended that you use Oracle's lock procedures: http://psoug.org/reference/sleep.html
   *    - In instances where you do not have access use this sleep method instead
   *  - This implementation may tie up CPU so only use for development purposes
   *  - This is a custom implementation of sleep and as a result the times are not 100% accurate
   *  - If calling in SQLDeveloper may get "IO Error: Socket read timed out". This is a JDBC driver setting, not a bug in this code.
   *
   * @issue #13
   *
   * @author Martin Giffy D'Souza
   * @created 31-Dec-2015
   * @param p_seconds Number of seconds to sleep for
   */
  procedure sleep(
    p_seconds in simple_integer)
  as
    l_now timestamp := systimestamp;
    l_end_time timestamp;

  begin
    l_end_time := l_now + numtodsinterval (p_seconds, 'second');

    -- Note: Can't use systimestamp in loop since it doesn't seem to calculate a new timestamp each iteration.
    while(l_end_time > l_now) loop
      l_now := systimestamp;
    end loop;
  end sleep;



end oos_util;
/

prompt oos_util_apex
create or replace package oos_util_apex
as

  function is_developer
    return boolean;

  function is_developer_yn
    return varchar2;

  function is_session_valid(
    p_session_id in apex_workspace_sessions.apex_session_id%type)
    return boolean;

  function is_session_valid_yn(
    p_session_id in apex_workspace_sessions.apex_session_id%type)
    return varchar2;

  procedure create_session(
    p_app_id in apex_applications.application_id%type,
    p_user_name in apex_workspace_sessions.user_name%type,
    p_page_id in apex_application_pages.page_id%type default null,
    p_session_id in apex_workspace_sessions.apex_session_id%type default null);

  procedure join_session(
    p_session_id in apex_workspace_sessions.apex_session_id%type,
    p_app_id in apex_applications.application_id%type default null);

  procedure trim_page_items(
    p_page_id in apex_application_pages.page_id%type default apex_application.g_flow_step_id);

  function is_page_item_rendered(
    p_item_name in apex_application_page_items.item_name%type)
    return boolean;

end oos_util_apex;
/

create or replace package body oos_util_apex
as

  /**
   * Returns true/false if APEX developer is enable
   * Supports both APEX 4 and 5
   *
   * Can be used in APEX to declaratively determine if in development mode
   *
   * @issue 25
   *
   * @author Martin Giffy D'Souza
   * @created 29-Dec-2015
   * @return true/false
   */
  function is_developer
    return boolean
  as
  begin
    if coalesce(apex_application.g_edit_cookie_session_id, v('APP_BUILDER_SESSION')) is null then
      return false;
    else
      return true;
    end if;
  end is_developer;


  /**
   * Returns Y/N if APEX developer is enable
   * See `is_developer` for details
   *
   * @issue #25
   *
   * @author Martin Giffy D'Souza
   * @created 29-Dec-2015
   * @return Y or N
   */
  function is_developer_yn
    return varchar2
  as
    $if dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    if is_developer then
      return 'Y';
    else
      return 'N';
    end if;
  end is_developer_yn;


  /**
   * Checks if APEX session is still active/valid
   *
   * @issue #9
   *
   * @author Martin Giffy D'Souza
   * @created 29-Dec-2015
   * @param p_session_id APEX session ID
   * @return true/false
   */
  function is_session_valid(
    p_session_id in apex_workspace_sessions.apex_session_id%type)
    return boolean
  as
    l_count pls_integer;
  begin
    oos_util.assert(p_session_id is not null, 'p_session_id must contain value');

    select count(1)
    into l_count
    from apex_workspace_sessions aws
    where 1=1
      and aws.apex_session_id = p_session_id
      and sysdate <= aws.session_idle_timeout_on
      and sysdate <= aws.session_life_timeout_on;

    if l_count = 0 then
      return false;
    else
      return true;
    end if;
  end is_session_valid;


  /**
   * Checks if session is still active
   *
   * @issue 9
   *
   * @author Martin Giffy D'Souza
   * @created 29-Dec-2015
   * @param p_session_id APEX session ID
   * @return Y/N
   */
  function is_session_valid_yn(
    p_session_id in apex_workspace_sessions.apex_session_id%type)
    return varchar2
  as
    $if dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    if is_session_valid(p_session_id => p_session_id) then
      return 'Y';
    else
      return 'N';
    end if;

  end is_session_valid_yn;


  /**
   * Creates a new APEX session.
   * Useful when testing APEX functionality in PL/SQL or using apex_mail etc
   *
   * Can only create one per Oracle session. To connect to a different APEX session, reconnect the Oracle session
   *
   *
   * Notes:
   *  - Content taken from:
   *    - http://www.talkapex.com/2012/08/how-to-create-apex-session-in-plsql.html
   *    - http://apextips.blogspot.com.au/2014/10/debugging-parameterised-views-outside.html
   *
   *
   * @issue #7
   * @issue #49 ensure page and user exist
   *
   * @author Martin Giffy D'Souza
   * @created 29-Dec-2015
   * @param p_app_id
   * @param p_user_name
   * @param p_page_id Page to try and register for post login. Recommended to leave null
   * @param p_session_id Session to re-join. Recommended leave null
   */
  procedure create_session(
    p_app_id in apex_applications.application_id%type,
    p_user_name in apex_workspace_sessions.user_name%type,
    p_page_id in apex_application_pages.page_id%type default null,
    p_session_id in apex_workspace_sessions.apex_session_id%type default null)
  as
    l_workspace_id apex_applications.workspace_id%TYPE;
    l_cgivar_name sys.owa.vc_arr;
    l_cgivar_val sys.owa.vc_arr;

    l_page_id apex_application_pages.page_id%type := p_page_id;
    l_home_link apex_applications.home_link%type;
    l_url_arr apex_application_global.vc_arr2;

    l_count pls_integer;
  begin

    sys.htp.init;

    l_cgivar_name(1) := 'REQUEST_PROTOCOL';
    l_cgivar_val(1) := 'HTTP';

    sys.owa.init_cgi_env(
      num_params => 1,
      param_name => l_cgivar_name,
      param_val => l_cgivar_val );

    select workspace_id
    into l_workspace_id
    from apex_applications
    where application_id = p_app_id;

    wwv_flow_api.set_security_group_id(l_workspace_id);

    if l_page_id is null then
      -- Try to get the page_id from home link
      select aa.home_link
      into l_home_link
      from apex_applications aa
      where 1=1
        and aa.application_id = p_app_id;

      if l_home_link is not null then
        l_url_arr := apex_util.string_to_table(l_home_link, ':');

        if l_url_arr.count >= 2 then
          l_page_id := l_url_arr(2);
        end if;
      end if;

      if l_page_id is null then
        l_page_id := 1;
      end if;

    end if; -- l_page_id is null

    -- #49 Ensure that page exists
    select count(1)
    into l_count
    from apex_application_pages aap
    where 1=1
      and aap.application_id = p_app_id
      and aap.page_id = l_page_id
      and l_page_id is not null;

    oos_util.assert(l_count = 1, 'Page must exist in the application');

    apex_application.g_instance := 1;
    apex_application.g_flow_id := p_app_id;
    apex_application.g_flow_step_id := l_page_id;

    apex_custom_auth.post_login(
      p_uname => p_user_name,
      p_session_id => null, -- could use APEX_CUSTOM_AUTH.GET_NEXT_SESSION_ID
      p_app_page => apex_application.g_flow_id || ':' || l_page_id);

    -- Rejoin session
    if p_session_id is not null then
      -- This will only set the session but doesn't register the items
      -- apex_custom_auth.set_session_id(p_session_id => p_session_id);
      -- #42 Seems a second login is required to fully join session
      apex_custom_auth.post_login(
        p_uname => p_user_name,
        p_session_id => p_session_id);
    end if;

  end create_session;


  /**
   * Join an existing APEX session
   *
   * Notes:
   *  - `v('P1_X')` won't work. Use `apex_util.get_session_state('P1_X')` instead
   *
   * @issue #7
   *
   * @author Martin Giffy D'Souza
   * @created 29-Dec-2015
   * @param p_session_id The session you want to join. Must be an existing active session.
   * @param p_app_id Use if multiple applications are linked to the same session. If null, last used application will be used.
   */
  procedure join_session(
    p_session_id in apex_workspace_sessions.apex_session_id%type,
    p_app_id in apex_applications.application_id%type default null)
  as
    l_app_id apex_applications.application_id%type := p_app_id;
    l_user_name apex_workspace_sessions.user_name%type;

  begin
    oos_util.assert(p_session_id is not null, 'p_session_id is required');

    if l_app_id is null then
      select max(application_id)
      into l_app_id
      from (
        select application_id, row_number() over (order by view_date desc) rn
        from apex_workspace_activity_log
        where apex_session_id = p_session_id)
      where rn = 1;
    end if;

    oos_util.assert(l_app_id is not null, 'Can not find matching app_id for session: ' || p_session_id);


    select user_name
    into l_user_name
    from apex_workspace_sessions
    where apex_session_id = p_session_id;

    create_session(
      p_app_id => l_app_id,
      p_user_name => l_user_name,
      p_session_id => p_session_id);

  end join_session;


  /**
   * Trims whitespace APEX page items (before and after).
   * Useful when submitting a page to trim all items.
   *
   * Notes:
   *  - Suggested to run submit page process application wide
   *  - Excludes inputs that users shouldn't modify and password fields
   *    - Ex: select list, hidden values, files
   *
   * @issue 24
   *
   * @author Martin Giffy D'Souza
   * @created 31-Dec-2015
   * @param p_page_id Items on this page will be trimmed.
   */
  procedure trim_page_items(
    p_page_id in apex_application_pages.page_id%type default apex_application.g_flow_step_id)
  as
  begin
    oos_util.assert(p_page_id is not null, 'p_page_id is required');

    for x in (
      select item_name, item_value_trim
      from (
        select
          x.item_name,
          x.item_value,
          regexp_replace(x.item_value, '(^[[:space:]]*|[[:space:]]*$)') item_value_trim
        from (
          select pi.item_name, v(pi.item_name) item_value
          from apex_application_page_items pi
          where 1=1
            and pi.page_id = p_page_id
            and pi.display_as_code not in (
              'NATIVE_HIDDEN', 'NATIVE_CHECKBOX',
              'NATIVE_RADIOGROUP', 'NATIVE_DISPLAY_ONLY',
              'NATIVE_PASSWORD', 'NATIVE_SELECT_LIST',
              'NATIVE_SHUTTLE', 'NATIVE_FILE')
        ) x
      ) x
      where 1=1
        and x.item_value is not null
        and (1=2
          or x.item_value != x.item_value_trim
          or x.item_value_trim is null) -- If item value is just white spaces then item_value_trim will be null
    ) loop

      apex_util.set_session_state(
        p_name => x.item_name,
        p_value => x.item_value_trim
        -- FUTURE mdsouza: make this an apex 5 compilation Optional
        -- ,p_commit => false
      );

    end loop;

  end trim_page_items;


  /**
   * Returns true/false if page item was rendered
   *
   * Notes:
   *  - This should only run on a page submit process otherwise it won't work. An error is raised otherwise
   *
   * @issue #39
   *
   * @author Daniel Hochleitner
   * @created 06-Mar-2016
   * @return true/false
   */
  function is_page_item_rendered(
    p_item_name in apex_application_page_items.item_name%type)
    return boolean
  as
    l_item_id apex_application_page_items.item_id%type;
    l_return boolean := false;
  begin

    -- Ensure that this is only done on page submit (otherwise it doesn't make sense)
    oos_util.assert(
      sys.owa_util.get_cgi_env('PATH_INFO') = '/wwv_flow.accept',
      lower($$plsql_unit) || '.is_page_item_rendered can only be run on a page submit process');

    select item_id
    into l_item_id
    from apex_application_page_items
    where 1=1
      and application_id = apex_application.g_flow_id
      and page_id = apex_application.g_flow_step_id
      and item_name = upper(p_item_name);

    -- If a page item is rendered the internal id is stored in a hidden field
    -- called p_arg_names. During submit the values are stored into the
    -- g_arg_names array by the WWV_Flow.accept procedure.
    -- By checking for existence of the page item id in the array, we are able
    -- to determine if APEX has rendered the item as "Saves state".
    -- Note: A item which is normally enterable but which is rendered
    --       "Read Only" is also considered rendered, because it still saves state

    if apex_application.g_arg_names.count > 0 then
      for i in 1 .. apex_application.g_arg_names.count loop
        if apex_application.g_arg_names(i) = l_item_id then
          l_return := true;
          exit;
        end if;
      end loop;
    end if;

    return l_return;
  end is_page_item_rendered;

end oos_util_apex;
/

prompt oos_util_bit
create or replace package oos_util_bit
as

  function bitand(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer;

  function bitor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer;

  function bitxor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer;

  function bitnot(
    p_x in binary_integer)
    return binary_integer;

end;
/

create or replace package body oos_util_bit
as

  /**
   * [bitwise AND](https://en.wikipedia.org/wiki/Bitwise_operation#AND)
   *
   * The function signature is similar to [`bitand`](https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612)
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @example
   *
   * select oos_util_bit.bitand(1,3)
   * from dual;
   *
   * OOS_UTIL_BIT.BITAND(1,3)
   * ------------------------
   *                       1
   *
   * @issue #69
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 11-Apr-2016
   * @param p_x binary_integer
   * @param p_y binary_integer
   * @return binary_integer
   */
  function bitand(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
  as
  begin
    return sys.standard.bitand(p_x, p_y);
  end bitand;

  /**
   * [bitwise OR](https://en.wikipedia.org/wiki/Bitwise_operation#OR)
   *
   * Copied from [http://www.orafaq.com/wiki/Bit](http://www.orafaq.com/wiki/Bit)
   *
   * The function signature is similar to [`bitand`](https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612)
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @example
   *
   * select oos_util_bit.bitor(1,3)
   * from dual;
   *
   * OOS_UTIL_BIT.BITOR(1,3)
   * -----------------------
   *                       3
   *
   * @issue #44
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 06-Apr-2016
   * @param p_x binary_integer
   * @param p_y binary_integer
   * @return binary_integer
   */
  function bitor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
  as
  begin
    return p_x + p_y - bitand(p_x, p_y);
  end bitor;

  /**
   * [bitwise XOR](https://en.wikipedia.org/wiki/Bitwise_operation#XOR)
   *
   * Copied from [http://www.orafaq.com/wiki/Bit](http://www.orafaq.com/wiki/Bit)
   *
   * The function signature is similar to [`bitand`](https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612)
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @example
   *
   * select oos_util_bit.bitxor(1,3)
   * from dual;
   *
   * OOS_UTIL_BIT.BITXOR(1,3)
   * ------------------------
   *                        2
   *
   * @issue #44
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 06-Apr-2016
   * @param p_x binary_integer
   * @param p_y binary_integer
   * @return binary_integer
   */
  function bitxor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
  as
  begin
    return bitor(p_x, p_y) - bitand(p_x, p_y);
  end bitxor;

  /**
   * [bitwise NOT](https://en.wikipedia.org/wiki/Bitwise_operation#NOT)
   *
   * Copied from [http://www.orafaq.com/wiki/Bit](http://www.orafaq.com/wiki/Bit)
   *
   * The function signature is similar to [`bitand`](https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612)
   *
   * The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an
   * argument is out of this range, the result is undefined.
   *
   * @example
   *
   * select oos_util_bit.bitnot(7)
   * from dual;
   *
   * OOS_UTIL_BIT.BITNOT(7)
   * ----------------------
   *                     -8
   *
   * @issue #44
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 06-Apr-2016
   * @param p_x binary_integer
   * @return binary_integer
   */
  function bitnot(
    p_x in binary_integer)
    return binary_integer
  as
  begin
    return (0 - p_x) - 1;
  end bitnot;

end;
/

prompt oos_util_date
create or replace package oos_util_date
as

  function date2epoch(
    p_date in date)
    return number;

  function epoch2date(
    p_epoch in number)
    return date;

end oos_util_date;
/

create or replace package body oos_util_date
as


  /**
   * Coverts date to Unix Epoch time
   *
   * @issue #18
   *
   * @author Martin Giffy D'Souza
   * @created 30-Dec-2015
   * @param p_date Date to convert to Epoch format
   * @return Unix Epoch time
   */
  function date2epoch(
    p_date in date)
    return number
  as
    $if dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    return
      round(
        (p_date - to_date ('19700101', 'yyyymmdd')) * 86400
        - (to_number(substr (tz_offset (sessiontimezone), 1, 3))+1) * 3600);

  end date2epoch;


  /**
   * Converts Unix linux time to Oracle date
   *
   * @issue 18
   *
   * @author Martin Giffy D'Souza
   * @created 31-Dec-2015
   * @param p_epoch Epoch Unix date (number)
   * @return date
   */
  function epoch2date(
    p_epoch in number)
    return date
  as

  begin
    return
      to_date ('19700101', 'yyyymmdd')
      + ((p_epoch + ((to_number(substr(tz_offset(sessiontimezone), 1, 3))+1) * 3600)) / 86400);
  end epoch2date;

end oos_util_date;
/

prompt oos_util_lob
create or replace package oos_util_lob
as
  -- CONSTANTS
  /**
   * gc_unit_b B
   * gc_unit_kb KB
   * gc_unit_mb MB
   * gc_unit_gb GB
   * gc_unit_tb TB
   * gc_unit_pb PB
   * gc_unit_eb EB
   * gc_unit_zb ZB
   * gc_unit_yb YB
   */
  gc_unit_b constant varchar2(1) := 'B';
  gc_unit_kb constant varchar2(2) := 'KB';
  gc_unit_mb constant varchar2(2) := 'MB';
  gc_unit_gb constant varchar2(2) := 'GB';
  gc_unit_tb constant varchar2(2) := 'TB';
  gc_unit_pb constant varchar2(2) := 'PB';
  gc_unit_eb constant varchar2(2) := 'EB';
  gc_unit_zb constant varchar2(2) := 'ZB';
  gc_unit_yb constant varchar2(2) := 'YB';
  --
  gc_size_b constant number := 1024;
  gc_size_kb constant number := power(1024, 2);
  gc_size_mb constant number := power(1024, 3);
  gc_size_gb constant number := power(1024, 4);
  gc_size_tb constant number := power(1024, 5);
  gc_size_pb constant number := power(1024, 6);
  gc_size_eb constant number := power(1024, 7);
  gc_size_zb constant number := power(1024, 8);
  gc_size_yb constant number := power(1024, 9);


  -- METHODS
  function clob2blob(
    p_clob in clob)
    return blob;

  function blob2clob(
    p_blob in blob)
    return clob;

  function get_file_size(
    p_file_size in number,
    p_units in varchar2 default null)
    return varchar2;

  function get_lob_size(
    p_lob in clob,
    p_units in varchar2 default null)
    return varchar2;

  function get_lob_size(
    p_lob in blob,
    p_units in varchar2 default null)
    return varchar2;

  function replace_clob(
    p_str in clob,
    p_search in varchar2,
    p_replace in clob)
    return clob;

  procedure write_to_file(
    p_text in clob,
    p_path in varchar2,
    p_filename in varchar2);

  function read_from_file(
    p_path in varchar2,
    p_filename in varchar2)
    return clob;

end oos_util_lob;
/

create or replace package body oos_util_lob
as

  /**
   * Convers clob to blob
   *
   * @issue #12
   *
   * @author Moritz Klein (https://github.com/commi235)
   * @created 07-Sep-2015
   * @param p_clob Clob to conver to blob
   * @return blob
   */
  function clob2blob(
    p_clob in clob)
    return blob
  as
    l_blob blob;
    l_dest_offset integer := 1;
    l_src_offset integer := 1;
    l_lang_ctx integer := dbms_lob.default_lang_ctx;
    l_warning integer;
  begin
    if p_clob is null then
      return null;
    end if;

    dbms_lob.createtemporary(
      lob_loc => l_blob,
      cache => false);

    dbms_lob.converttoblob(
      dest_lob => l_blob,
      src_clob => p_clob,
      amount => dbms_lob.lobmaxsize,
      dest_offset => l_dest_offset,
      src_offset => l_src_offset,
      blob_csid => dbms_lob.default_csid,
      lang_context => l_lang_ctx,
      warning => l_warning);

    oos_util.assert(l_warning = dbms_lob.no_warning, 'failed to convert clob to blob: ' || l_warning);

    return l_blob;
  end clob2blob;

  /**
   * Converts blob to clob
   *
   * Notes:
   *  - Copied from http://stackoverflow.com/questions/12849025/convert-blob-to-clob
   *
   * @issue #1
   *
   * @author Martin D'Souza
   * @created 02-Mar-2014
   * @param p_blob blob to be converted to clob
   * @return clob
   */
  function blob2clob(
    p_blob in blob)
    return clob
  as
    l_clob clob;
    l_dest_offset integer := 1;
    l_src_offset integer := 1;
    l_lang_context integer := dbms_lob.default_lang_ctx;
    l_warning integer;
  begin
    if p_blob is null then
      return null;
    end if;

    dbms_lob.createtemporary(
      lob_loc => l_clob,
      cache => false);

    dbms_lob.converttoclob(
      dest_lob => l_clob,
      src_blob => p_blob,
      amount => dbms_lob.lobmaxsize,
      dest_offset => l_dest_offset,
      src_offset => l_src_offset,
      blob_csid => dbms_lob.default_csid,
      lang_context => l_lang_context,
      warning => l_warning);

    oos_util.assert(l_warning = dbms_lob.no_warning, 'failed to convert blob to clob: ' || l_warning);

    return l_clob;
  end blob2clob;

  /**
   * Returns human readable file size
   *
   * @issue #6
   *
   * @author Martin D'Souza
   * @created 07-Sep-2015
   * @param p_file_size size of file in bytes
   * @param p_units See `gc_size_...` consants for options. If not provided, most significant one automatically chosen.
   * @return Human readable file size
   */
  function get_file_size(
    p_file_size in number,
    p_units in varchar2 default null)
    return varchar2
  as
    l_units varchar2(255);
  begin
    if p_file_size is null then
      return null;
    end if;

    -- List of formats: http://www.gnu.org/software/coreutils/manual/coreutils
    l_units := nvl(p_units,
      case
        when p_file_size < gc_size_b then oos_util_lob.gc_unit_b
        when p_file_size < gc_size_kb then oos_util_lob.gc_unit_kb
        when p_file_size < gc_size_mb then oos_util_lob.gc_unit_mb
        when p_file_size < gc_size_gb then oos_util_lob.gc_unit_gb
        when p_file_size < gc_size_tb then oos_util_lob.gc_unit_tb
        when p_file_size < gc_size_pb then oos_util_lob.gc_unit_pb
        when p_file_size < gc_size_eb then oos_util_lob.gc_unit_eb
        when p_file_size < gc_size_zb then oos_util_lob.gc_unit_zb
        else
          oos_util_lob.gc_unit_yb
      end
    );

    return
      trim(
        to_char(
        round(
          case
            when l_units = oos_util_lob.gc_unit_b then p_file_size/(gc_size_b/gc_size_b)
            when l_units = oos_util_lob.gc_unit_kb then p_file_size/(gc_size_kb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_mb then p_file_size/(gc_size_mb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_gb then p_file_size/(gc_size_gb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_tb then p_file_size/(gc_size_tb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_pb then p_file_size/(gc_size_pb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_eb then p_file_size/(gc_size_eb/gc_size_b)
            when l_units = oos_util_lob.gc_unit_zb then p_file_size/(gc_size_zb/gc_size_b)
            else
              p_file_size/(gc_size_yb/gc_size_b)
          end, 1)
        ,
        -- Number format
        '999G999G999G999G999G999G999G999G999' ||
          case
            when l_units != oos_util_lob.gc_unit_b then 'D9'
            else null
          end)
        )
      || ' ' || l_units;
  end get_file_size;

  /**
   * See get_file_size
   *
   * @author Martin D'Souza
   * @created 07-Sep-2015
   * @param p_lob
   * @param p_units
   * @return
   */
  function get_lob_size(
    p_lob in clob,
    p_units in varchar2 default null)
    return varchar2
  as
  begin
    return get_file_size(
      p_file_size => dbms_lob.getlength(p_lob),
      p_units => p_units
    );
  end get_lob_size;

  /**
   * See get_file_size
   *
   * @author Martin D'Souza
   * @created 07-Sep-2015
   * @param p_lob
   * @param p_units
   * @return
   */
  function get_lob_size(
    p_lob in blob,
    p_units in varchar2 default null)
    return varchar2
  as
  begin
    return get_file_size(
      p_file_size => dbms_lob.getlength(p_lob),
      p_units => p_units
    );
  end get_lob_size;


  /**
   * Replaces p_search with p_replace
   *
   * Oracle's replace function does handle clobs but runs into 32k issues
   *
   * Notes:
   *  - Source: http://dbaora.com/ora-22828-input-pattern-or-replacement-parameters-exceed-32k-size-limit/
   *
   * @issue #29
   *
   * @author Martin Giffy D'Souza
   * @created 29-Dec-2015
   * @param p_str
   * @param p_search
   * @param p_replace
   * @return Replaced string
   */
  function replace_clob(
    p_str in clob,
    p_search in varchar2,
    p_replace in clob)
    return clob
  as
    l_pos pls_integer;
  begin
    l_pos := instr(p_str, p_search);

    if l_pos > 0 then
      return substr(p_str, 1, l_pos-1)
          || p_replace
          || substr(p_str, l_pos+length(p_search));
    end if;

    return p_str;
  end replace_clob;

  /**
   *
   * Write a clob (p_text) into a file (p_filename) located in a database
   * server file system directory (p_path). p_path is an Oracle directory
   * object.
   *
   * @issue #56
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 05-Apr-2016
   * @param p_text
   * @param p_path
   * @param p_filename
   */
  procedure write_to_file(
    p_text in clob,
    p_path in varchar2,
    p_filename in varchar2)
  as
    l_tmp_lob blob;
  begin

    -- exit if any parameter is null
    oos_util.assert(p_text is not null, 'p_text required parameter');
    oos_util.assert(p_path is not null, 'p_path required parameter');
    oos_util.assert(p_filename is not null, 'p_filename required parameter');

    -- convert a clob to a blob
    l_tmp_lob := clob2blob(p_text);

    -- write a blob to a file
    declare
      l_lob_len pls_integer;
      l_fh utl_file.file_type;
      l_pos pls_integer := 1;
      l_buffer raw(32767);
      l_amount pls_integer := 32767;
    begin
      l_fh := utl_file.fopen(
        location => p_path,
        filename => p_filename,
        open_mode =>'wb',
        max_linesize => 32767);

      l_lob_len := dbms_lob.getlength(l_tmp_lob);

      while l_pos < l_lob_len loop
        dbms_lob.read(
          lob_loc => l_tmp_lob,
          amount => l_amount,
          offset => l_pos,
          buffer => l_buffer);

        utl_file.put_raw(
          file => l_fh,
          buffer => l_buffer,
          autoflush => false);

        l_pos := l_pos + l_amount;
      end loop;

      utl_file.fclose(l_fh);
      dbms_lob.freetemporary(l_tmp_lob);
    end;

  end write_to_file;

  /**
   *
   * Read a content of a file (p_filename) from a database server file system
   * directory (p_path) and return it as a temporary clob. The caller is
   * responsible to free the clob (dbms_lob.freetemporary()). p_path is an
   * Oracle directory object.
   *
   * The implementation is based on UTL_FILE so the following constraints apply:
   *
   * A line size can't exceed 32767 bytes.
   *
   * Because UTL_FILE.get_line ignores line terminator it has to be added
   * implicitly. Currently the line terminator is hardcoded to char(10)
   * (unix), so if in the original file the terminator is different then a
   * conversion will take place.
   *
   * TODO: consider DBMS_LOB.LOADCLOBFROMFILE instead.
   *
   * @issue #56
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 05-Apr-2016
   * @param p_path
   * @param p_filename
   * @return clob
   */
  function read_from_file(
    p_path in varchar2,
    p_filename in varchar2)
    return clob
  as
    l_fh utl_file.file_type;
    l_tmp_lob clob;
  begin
    l_fh := utl_file.fopen(
      location => p_path,
      filename => p_filename,
      open_mode => 'r',
      max_linesize => 32767);

    dbms_lob.createtemporary(
      lob_loc => l_tmp_lob,
      cache => false,
      dur => dbms_lob.session);

    declare
      c_lt constant varchar2(1) := chr(10); -- unix line terminator
      l_buf varchar2(32767);
    begin
      loop
        utl_file.get_line(l_fh, l_buf);
        dbms_lob.writeappend(l_tmp_lob, length(l_buf), l_buf);
        -- get_line ignores line terminator so it is explicitly included
        dbms_lob.writeappend(l_tmp_lob, length(c_lt), c_lt);
      end loop;
    exception
      when no_data_found then
        utl_file.fclose(l_fh);
    end;

    utl_file.fclose(l_fh);

    return l_tmp_lob;
  end read_from_file;

end oos_util_lob;
/

prompt oos_util_string
create or replace package oos_util_string
as

  -- TYPES
  /**
   * @type tab_vc2
   * @type tab_vc2_arr
   */
  type tab_vc2 is table of varchar2(32767);
  type tab_vc2_arr is table of varchar2(32767) index by pls_integer;

  -- CONSTANTS
  /**
   * @constant gc_default_delimiter Default delimiter for delimited strings
   */
  gc_default_delimiter constant varchar2(1) := ',';

  function to_char(
    p_val in number)
    return varchar2;

  function to_char(
    p_val in date)
    return varchar2;

  function to_char(
    p_val in timestamp)
    return varchar2;

  function to_char(
    p_val in timestamp with time zone)
    return varchar2;

  function to_char(
    p_val in timestamp with local time zone)
    return varchar2;

  function to_char(
    p_val in boolean)
    return varchar2;

  function truncate(
    p_str in varchar2,
    p_length in pls_integer,
    p_by_word in varchar2 default 'N',
    p_ellipsis in varchar2 default '...')
    return varchar2;

  function sprintf(
    p_str in varchar2,
    p_s1 in varchar2 default null,
    p_s2 in varchar2 default null,
    p_s3 in varchar2 default null,
    p_s4 in varchar2 default null,
    p_s5 in varchar2 default null,
    p_s6 in varchar2 default null,
    p_s7 in varchar2 default null,
    p_s8 in varchar2 default null,
    p_s9 in varchar2 default null,
    p_s10 in varchar2 default null)
    return varchar2;

  function string_to_table(
    p_string in clob,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2_arr;

  function string_to_table(
    p_string in varchar2,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2_arr;

  function listunagg(
    p_string in varchar2,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2 pipelined;

  function listunagg(
    p_string in clob,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2 pipelined;

  function reverse(
    p_string in varchar2)
    return varchar2;

end oos_util_string;
/

create or replace package body oos_util_string
as

  /**
   * Converts parameter to varchar2
   *
   * Notes:
   *  - Code copied from Logger: https://github.com/OraOpenSource/Logger
   *
   * @issue 11
   *
   * @author Martin D'Souza
   * @created 07-Jun-2014
   * @param p_val Number
   * @return string value for p_val
   */
  function to_char(
    p_val in number)
    return varchar2
  as
  begin
    return sys.standard.to_char(p_val);
  end to_char;

  /**
   * See first `to_char`
   *
   * @param p_val Date
   * @return string value for p_val
   */
  function to_char(
    p_val in date)
    return varchar2
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_date_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @param p_val Timestamp
   * @return string value for p_val
   */
  function to_char(
    p_val in timestamp)
    return varchar2
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_timestamp_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @param p_val Timestamp with TZ
   * @return string value for p_val
   */
  function to_char(
    p_val in timestamp with time zone)
    return varchar2
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_timestamp_tz_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @param p_val Timestamp with local TZ
   * @return string value for p_val
   */
  function to_char(
    p_val in timestamp with local time zone)
    return varchar2
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_timestamp_tz_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @param p_val Boolean
   * @return string value for p_val
   */
  function to_char(
    p_val in boolean)
    return varchar2
  as
  begin
    return case when p_val then 'TRUE' else 'FALSE' end;
  end to_char;

  /**
   * Truncates a string to ensure that it is not longer than `p_length`
   * If length of `p_str` is greater than `p_length` then an ellipsis (`...`) will be appended to string
   *
   * Supports following modes:
   *  - By length (default): Will perform a hard parse at `p_length`
   *  - By word: Will truncate at logical word break
   *
   *
   * @issue #5
   *
   * @author Martin D'Souza
   * @created 05-Sep-2015
   * @param p_str String to truncate
   * @param p_length Max length of final string
   * @param p_by_word Y/N. If Y then will truncate to last word possible
   * @param p_ellipsis ellipsis "..." default
   * @return Trimmed string
   */
  function truncate(
    p_str in varchar2,
    p_length in pls_integer,
    p_by_word in varchar2 default 'N',
    p_ellipsis in varchar2 default '...')
    return varchar2
  as
    l_stop_position pls_integer;
    l_str varchar2(32767) := trim(p_str);
    l_by_word boolean := false;

    l_max_length pls_integer := p_length - length(p_ellipsis); -- This is the max that the string can be without an ellipsis appended to it.

    $if dbms_db_version.version >= 12 $then
      pragma udf;
    $end
  begin
    -- TODO mdsouza: look at the cost of doing these checks
    oos_util.assert(upper(nvl(p_by_word, 'N')) in ('Y', 'N'), 'Invalid p_by_word. Must be Y/N');
    oos_util.assert(p_length > 0, 'p_length must be a postive number');

    if upper(nvl(p_by_word, 'N')) = 'Y' then
      l_by_word := true;
    end if;

    if length(l_str) <= p_length then
      l_str := l_str;
    elsif length(p_ellipsis) > p_length or l_max_length = 0 then
      -- Can't replace string with ellipsis if it'll return a larger string.
      l_str := substr(l_str, 1, p_length);
    elsif not l_by_word then
      -- Truncate by length
      l_str := trim(substr(l_str, 1, l_max_length)) || p_ellipsis;
    elsif l_by_word then
      -- If string at [max string(length) - ellipsis] and next characters belong to same word
      -- Then need to go back and find last non-word
      if regexp_instr(l_str, '\w{2,}', l_max_length, 1, 0) = l_max_length then
        l_str := substr(
            l_str,
            1,
            -- Find the last non-word and go back one character
            regexp_instr(substr(l_str,1, p_length - length(p_ellipsis)), '\W+\w*$') -1);

        if l_str is null then
          -- This will happen if the length is just slightly greater than the elipsis and first word is long
          l_str := substr(trim(p_str), 1, l_max_length);
        end if;

      else
        -- Find last non-word. Need to reverse the string since Oracle regexp doesn't support lookbehind assertions
        l_str := reverse(substr(l_str,1, l_max_length));
        l_str :=
          -- Unreverse string
          reverse(
            -- Cut the string from the first word char to the end in the reveresed string
            -- Since this is a reversed string, the first word char, is really the last word char
            substr(l_str, regexp_instr(l_str, '\w'))
          );

      end if;

      l_str := l_str || p_ellipsis;

      -- end l_by_word
    end if;

    return l_str;
  end truncate;

  /**
   * Does string replacement similar to C's sprintf
   *
   * Notes:
   *  - Uses the following replacement algorithm (in following order)
   *    - Replaces `%s<n>` with `p_s<n>`
   *    - Occurrences of `%s` (no number) are replaced with `p_s1..p_s10` in order that they appear in text
   *    - `%%` is escaped to `%`
   *
   * @example
   * select oos_util_string.sprintf('hello %s', 'martin') demo
   * from dual;
   *
   * DEMO
   * ------------------------------
   * hello martin
   *
   * select oos_util_string.sprintf('%s2, %s1', 'Firstname', 'Lastname') demo
   * from dual;
   *
   * DEMO
   * ------------------------------
   * Lastname, Firstname
   *
   * @issue #8
   *
   * @author Martin D'Souza
   * @created 15-Jun-2014
   * @param p_str Messsage to format using %s and %d replacement strings
   * @param p_s1..10 Replacement strings
   * @return p_msg with strings replaced
   */
  function sprintf(
    p_str in varchar2,
    p_s1 in varchar2 default null,
    p_s2 in varchar2 default null,
    p_s3 in varchar2 default null,
    p_s4 in varchar2 default null,
    p_s5 in varchar2 default null,
    p_s6 in varchar2 default null,
    p_s7 in varchar2 default null,
    p_s8 in varchar2 default null,
    p_s9 in varchar2 default null,
    p_s10 in varchar2 default null)
    return varchar2
  as
    l_return varchar2(4000);
    c_substring_regexp constant varchar2(10) := '%s';

  begin
    l_return := p_str;

    -- Replace %s<n> with p_s<n>
    -- #23: Need to do in reverse so 10 processes before 1
    for i in reverse 1..10 loop
      l_return := regexp_replace(l_return, c_substring_regexp || i,
        case
          when i = 1 then p_s1
          when i = 2 then p_s2
          when i = 3 then p_s3
          when i = 4 then p_s4
          when i = 5 then p_s5
          when i = 6 then p_s6
          when i = 7 then p_s7
          when i = 8 then p_s8
          when i = 9 then p_s9
          when i = 10 then p_s10
          else null
        end,
        1,0,'c');
    end loop;

    -- Replace any occurences of %s with p_s<n> (in order) and escape %% to %
    l_return := sys.utl_lms.format_message(l_return,p_s1, p_s2, p_s3, p_s4, p_s5, p_s6, p_s7, p_s8, p_s9, p_s10);

    return l_return;

  end sprintf;


  /**
   * Converts delimited string to array
   *
   * Notes:
   *  - Similar to `apex_util.string_to_table` but handles clobs
   *
   * @issue #32
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_string String containing delimited text
   * @param p_delimiter Delimiter
   * @return Array of string
   */
  function string_to_table(
    p_string in clob,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2_arr
  is
    l_occurrence pls_integer;
    l_last_pos pls_integer;
    l_pos pls_integer;
    l_length pls_integer;

    l_return tab_vc2_arr;
  begin

    if p_string is not null then
      l_occurrence := 1;
      l_last_pos := 0;
      l_pos := 1;
      l_length := dbms_lob.getlength(p_string);

      while l_pos > 0 loop
        l_pos := instr(p_string, p_delimiter, 1, l_occurrence);

        if l_pos = 0 then
          l_return(l_return.count + 1) := substr(p_string, l_last_pos + 1, l_length);
        else
          l_return(l_return.count + 1) := substr(p_string, l_last_pos + 1, l_pos - (l_last_pos+1));
        end if; -- l_pos = 0

        l_last_pos := l_pos;
        l_occurrence := l_occurrence + 1;
      end loop;
    end if; -- p_string is not null

    return l_return;
  end string_to_table;

  /**
   * See `string_to_table (p_string clob)` for notes
   *
   * @issue  #32
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_string String containing delimited text
   * @param p_delimiter Delimiter
   * @return Array of string
   */
  function string_to_table(
    p_string in varchar2,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2_arr
  is
    l_clob clob;
    l_return tab_vc2_arr;
  begin
    l_clob := p_string;
    return string_to_table(p_string => l_clob, p_delimiter => p_delimiter);
  end string_to_table;


  /**
   * Converts delimited string to queriable table
   *
   * Notes:
   *  - Text between delimiters must be `<= 4000` characters
   *
   * @example
   *  select rownum, column_value
   *  from table(oos_util_string.listunagg('abc,def'));
   *
   *      ROWNUM COLUMN_VAL
   * ---------- ----------
   *          1 abc
   *          2 def
   *
   * @issue #4
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_string String containing delimited text
   * @param p_delimiter Delimiter
   * @return pipelined table
   */
  function listunagg(
    p_string in varchar2,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2 pipelined
  is
    l_arr oos_util_string.tab_vc2_arr;
  begin
    l_arr := string_to_table(p_string => p_string, p_delimiter => p_delimiter);

    for i in 1 .. l_arr.count loop
      pipe row (l_arr(i));
    end loop;
  end listunagg;


  /**
   * Converts delimited string to queriable table
   *
   * See above for example
   *
   *
   * @issue #4
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_string String (clob) containing delimited text
   * @param p_delimiter Delimiter
   * @return pipelined table
   */
  function listunagg(
    p_string in clob,
    p_delimiter in varchar2 default gc_default_delimiter)
    return tab_vc2 pipelined
  is
    l_arr tab_vc2_arr;
  begin
    l_arr := string_to_table(p_string => p_string, p_delimiter => p_delimiter);

    for i in 1 .. l_arr.count loop
      pipe row (l_arr(i));
    end loop;
  end listunagg;


  /**
   * Returns the input string in its reverse order
   *
   * @issue #55
   *
   * @author Tim Nanos
   * @created 31-Mar-2016
   * @param p_string String
   * @return String
   */
  function reverse(
    p_string in varchar2)
    return varchar2
  is
    l_string varchar2(32767);
  begin
    if p_string is not null then
      for i in 1..length(p_string) loop
        l_string := substr(p_string, i, 1) || l_string;
      end loop;
    end if;
    
    return l_string;
  end reverse;

end oos_util_string;
/

prompt oos_util_validation
create or replace package oos_util_validation
as

  function is_number(p_str in varchar2)
    return boolean;

  function is_date(
    p_str in varchar2,
    p_date_format in varchar2)
    return boolean;


end oos_util_validation;
/

create or replace package body oos_util_validation
as


  -- ******** PUBLIC ********

  /**
   * Checks if string is numeric
   *
   * @issue #15
   *
   * @author Trent Schafer
   * @created 05-Sep-2015
   * @param p_str String to validate
   * @return True of p_str is number
   */
  function is_number(p_str in varchar2)
    return boolean
  as
    l_num number;
  begin
    l_num := to_number(p_str);
    return true;
  exception
    when value_error then
      return false;
  end is_number;


  /**
   * Checks if string is a valid date
   *
   * @issue #20
   *
   * @author Martin D'Souza
   * @created 05-Sep-2015
   * @param p_str
   * @param p_date_format
   * @return True if date is valid
   */
  function is_date(
    p_str in varchar2,
    p_date_format in varchar2)
    return boolean
  as
    l_date date;
  begin
    l_date := to_date(p_str, p_date_format);
    return true;
  exception
    when others then -- Using a when others since date format could also be invalid
      return false;
  end is_date;


end oos_util_validation;
/

prompt oos_util_web
create or replace package oos_util_web
as
  -- CONSTANTS
  /**
   * @constant gc_content_disposition_inline For downloading file and viewing inline
   * @constant gc_content_disposition_attach For downloading file as attachment
   */
  gc_content_disposition_inline constant varchar2(20) := 'inline';
  gc_content_disposition_attach constant varchar2(20) := 'attachment';

  function get_mime_type(
    p_filename in varchar2)
    return oos_util_values.value%type;

  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_web.gc_content_disposition_attach,
    p_cache_control in varchar2 default null,
    p_blob in blob);

  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_web.gc_content_disposition_attach,
    p_cache_control in varchar2 default null,
    p_clob in clob);


end oos_util_web;
/

create or replace package body oos_util_web
as

  -- CONSTANTS

  /**
   * Returns the mime-type for a filename
   *
   * @issue #27
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_filename Filename
   * @return mime-type
   */
  function get_mime_type(
    p_filename in varchar2)
    return oos_util_values.value%type
  as
    l_return oos_util_values.value%type;
    l_file_ext varchar2(10);
  begin

    l_file_ext := lower(trim(leading '.' from regexp_substr(p_filename,'\.[^\.]*$')));

    begin
      select value
      into l_return
      from oos_util_values ouv
      where 1=1
        and ouv.cat = oos_util.gc_vals_cat_mime_type
        and ouv.name = l_file_ext;

    exception
      when no_data_found then
       l_return := 'application/octet';
    end;

    return l_return;


    --   select lower(extension) as extension, mime_type
    --   from xmltable (
    --      xmlnamespaces (default 'http://xmlns.oracle.com/xdb/xdbconfig.xsd'),
    --      '//mime-mappings/mime-mapping'
    --     passing xdb.dbms_xdb.cfg_get()
    --      columns
    --       extension varchar2(30) path 'extension',
    --       mime_type varchar2(80) path 'mime-type')
    --   where lower(extension) = TODO regexp;


  end get_mime_type;


  /**
   * Download file
   *
   * @issue #2
   * @issue #47: cache support
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @example
   *  ```plsql
   *    select todo from dual
   *    where 1=1
   *    from dual
   *  ```
   * @param {number=} p_filename Filename
   * @param p_mime_type mime-type of file. If null will be resolved via p_filename
   * @param p_content_disposition inline or attachment
   * @param p_cache_control options to pass to the Cache-Control attribute. Examples include max-age=3600, no-cache, etc. See https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching?hl=en for examples
   * @param p_blob File to be downloaded
   */
  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_web.gc_content_disposition_attach,
    p_cache_control in varchar2 default null,
    p_blob in blob
    )
  as

    l_mime_type varchar2(255);
    l_blob blob := p_blob; -- Need to use l_blob since download is an in out for wpg_docload

  begin

    l_mime_type := coalesce(p_mime_type,oos_util_web.get_mime_type(p_filename => p_filename));

    -- Set Header
    sys.owa_util.mime_header(
      ccontent_type => l_mime_type,
      bclose_header => false );

    sys.htp.p('Content-length: ' || dbms_lob.getlength(p_blob));

    sys.htp.p(
      oos_util_string.sprintf(
        'Content-Disposition: %s; filename="%s"',
        p_content_disposition,
        p_filename));

    if p_cache_control is not null then
      sys.htp.p(oos_util_string.sprintf('Cache-Control: %s', p_cache_control));
    end if;

    sys.owa_util.http_header_close;

    -- download the BLOB
    sys.wpg_docload.download_file(p_blob => l_blob);

    -- Only call stop if in an APEX application
    if apex_application.g_flow_id is not null then
      apex_application.stop_apex_engine;
    end if;
    
  exception
    -- Not necessarily required but leaving in as a demo of how to handle stop_apex_engine
    when apex_application.e_stop_apex_engine then
       raise;
  end download_file;


  /**
   * Download clob file
   *
   * Notes:
   *  - See download_file (blob) for full documentation
   *
   * @issue #2
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_filename
   * @param p_mime_type
   * @param p_content_disposition
   * @param p_cache_control See download_file (blob) for documentation
   * @param p_clob
   */
  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_web.gc_content_disposition_attach,
    p_cache_control in varchar2 default null,
    p_clob in clob)
  as
    l_blob blob;
  begin

    l_blob := oos_util_lob.clob2blob(p_clob);

    download_file(
      p_filename => p_filename,
      p_mime_type => p_mime_type,
      p_content_disposition => p_content_disposition,
      p_cache_control => p_cache_control,
      p_blob => l_blob);
  end download_file;


end oos_util_web;
/



prompt *** Post Install ***

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



prompt *** Data ***

prompt oos_util_values
-- This file is generated, do not modify.

begin
  delete oos_util_values;
  insert all
    into oos_util_values(cat, name, value) values('mime-type', '123','application/vnd.lotus-1-2-3')
    into oos_util_values(cat, name, value) values('mime-type', 'ez','application/andrew-inset')
    into oos_util_values(cat, name, value) values('mime-type', 'aw','application/applixware')
    into oos_util_values(cat, name, value) values('mime-type', 'atom','application/atom+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'atomcat','application/atomcat+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'atomsvc','application/atomsvc+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'bdoc','application/bdoc')
    into oos_util_values(cat, name, value) values('mime-type', 'ccxml','application/ccxml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'cdmia','application/cdmi-capability')
    into oos_util_values(cat, name, value) values('mime-type', 'cdmic','application/cdmi-container')
    into oos_util_values(cat, name, value) values('mime-type', 'cdmid','application/cdmi-domain')
    into oos_util_values(cat, name, value) values('mime-type', 'cdmio','application/cdmi-object')
    into oos_util_values(cat, name, value) values('mime-type', 'cdmiq','application/cdmi-queue')
    into oos_util_values(cat, name, value) values('mime-type', 'cu','application/cu-seeme')
    into oos_util_values(cat, name, value) values('mime-type', 'mdp','application/dash+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'davmount','application/davmount+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'dbk','application/docbook+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'dssc','application/dssc+der')
    into oos_util_values(cat, name, value) values('mime-type', 'xdssc','application/dssc+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'ecma','application/ecmascript')
    into oos_util_values(cat, name, value) values('mime-type', 'emma','application/emma+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'epub','application/epub+zip')
    into oos_util_values(cat, name, value) values('mime-type', 'exi','application/exi')
    into oos_util_values(cat, name, value) values('mime-type', 'pfr','application/font-tdpfr')
    into oos_util_values(cat, name, value) values('mime-type', 'woff','application/font-woff')
    into oos_util_values(cat, name, value) values('mime-type', 'woff2','application/font-woff2')
    into oos_util_values(cat, name, value) values('mime-type', 'gml','application/gml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'gpx','application/gpx+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'gxf','application/gxf')
    into oos_util_values(cat, name, value) values('mime-type', 'stk','application/hyperstudio')
    into oos_util_values(cat, name, value) values('mime-type', 'ink','application/inkml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'inkml','application/inkml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'ipfix','application/ipfix')
    into oos_util_values(cat, name, value) values('mime-type', 'jar','application/java-archive')
    into oos_util_values(cat, name, value) values('mime-type', 'war','application/java-archive')
    into oos_util_values(cat, name, value) values('mime-type', 'ear','application/java-archive')
    into oos_util_values(cat, name, value) values('mime-type', 'ser','application/java-serialized-object')
    into oos_util_values(cat, name, value) values('mime-type', 'class','application/java-vm')
    into oos_util_values(cat, name, value) values('mime-type', 'js','application/javascript')
    into oos_util_values(cat, name, value) values('mime-type', 'json','application/json')
    into oos_util_values(cat, name, value) values('mime-type', 'map','application/json')
    into oos_util_values(cat, name, value) values('mime-type', 'json5','application/json5')
    into oos_util_values(cat, name, value) values('mime-type', 'jsonml','application/jsonml+json')
    into oos_util_values(cat, name, value) values('mime-type', 'jsonld','application/ld+json')
    into oos_util_values(cat, name, value) values('mime-type', 'lostxml','application/lost+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'hqx','application/mac-binhex40')
    into oos_util_values(cat, name, value) values('mime-type', 'cpt','application/mac-compactpro')
    into oos_util_values(cat, name, value) values('mime-type', 'mads','application/mads+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'webmanifest','application/manifest+json')
    into oos_util_values(cat, name, value) values('mime-type', 'mrc','application/marc')
    into oos_util_values(cat, name, value) values('mime-type', 'mrcx','application/marcxml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'ma','application/mathematica')
    into oos_util_values(cat, name, value) values('mime-type', 'nb','application/mathematica')
    into oos_util_values(cat, name, value) values('mime-type', 'mb','application/mathematica')
    into oos_util_values(cat, name, value) values('mime-type', 'mathml','application/mathml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'mbox','application/mbox')
    into oos_util_values(cat, name, value) values('mime-type', 'mscml','application/mediaservercontrol+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'metalink','application/metalink+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'meta4','application/metalink4+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'mets','application/mets+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'mods','application/mods+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'm21','application/mp21')
    into oos_util_values(cat, name, value) values('mime-type', 'mp21','application/mp21')
    into oos_util_values(cat, name, value) values('mime-type', 'mp4s','application/mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'm4p','application/mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'doc','application/msword')
    into oos_util_values(cat, name, value) values('mime-type', 'dot','application/msword')
    into oos_util_values(cat, name, value) values('mime-type', 'mxf','application/mxf')
    into oos_util_values(cat, name, value) values('mime-type', 'bin','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'dms','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'lrf','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'mar','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'so','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'dist','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'distz','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'pkg','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'bpk','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'dump','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'elc','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'deploy','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'exe','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'dll','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'deb','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'dmg','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'iso','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'img','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'msi','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'msp','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'msm','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'buffer','application/octet-stream')
    into oos_util_values(cat, name, value) values('mime-type', 'oda','application/oda')
    into oos_util_values(cat, name, value) values('mime-type', 'opf','application/oebps-package+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'ogx','application/ogg')
    into oos_util_values(cat, name, value) values('mime-type', 'omdoc','application/omdoc+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'onetoc','application/onenote')
    into oos_util_values(cat, name, value) values('mime-type', 'onetoc2','application/onenote')
    into oos_util_values(cat, name, value) values('mime-type', 'onetmp','application/onenote')
    into oos_util_values(cat, name, value) values('mime-type', 'onepkg','application/onenote')
    into oos_util_values(cat, name, value) values('mime-type', 'oxps','application/oxps')
    into oos_util_values(cat, name, value) values('mime-type', 'xer','application/patch-ops-error+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'pdf','application/pdf')
    into oos_util_values(cat, name, value) values('mime-type', 'pgp','application/pgp-encrypted')
    into oos_util_values(cat, name, value) values('mime-type', 'asc','application/pgp-signature')
    into oos_util_values(cat, name, value) values('mime-type', 'sig','application/pgp-signature')
    into oos_util_values(cat, name, value) values('mime-type', 'prf','application/pics-rules')
    into oos_util_values(cat, name, value) values('mime-type', 'p10','application/pkcs10')
    into oos_util_values(cat, name, value) values('mime-type', 'p7m','application/pkcs7-mime')
    into oos_util_values(cat, name, value) values('mime-type', 'p7c','application/pkcs7-mime')
    into oos_util_values(cat, name, value) values('mime-type', 'p7s','application/pkcs7-signature')
    into oos_util_values(cat, name, value) values('mime-type', 'p8','application/pkcs8')
    into oos_util_values(cat, name, value) values('mime-type', 'ac','application/pkix-attr-cert')
    into oos_util_values(cat, name, value) values('mime-type', 'cer','application/pkix-cert')
    into oos_util_values(cat, name, value) values('mime-type', 'crl','application/pkix-crl')
    into oos_util_values(cat, name, value) values('mime-type', 'pkipath','application/pkix-pkipath')
    into oos_util_values(cat, name, value) values('mime-type', 'pki','application/pkixcmp')
    into oos_util_values(cat, name, value) values('mime-type', 'pls','application/pls+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'ai','application/postscript')
    into oos_util_values(cat, name, value) values('mime-type', 'eps','application/postscript')
    into oos_util_values(cat, name, value) values('mime-type', 'ps','application/postscript')
    into oos_util_values(cat, name, value) values('mime-type', 'cww','application/prs.cww')
    into oos_util_values(cat, name, value) values('mime-type', 'pskcxml','application/pskc+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'rdf','application/rdf+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'rif','application/reginfo+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'rnc','application/relax-ng-compact-syntax')
    into oos_util_values(cat, name, value) values('mime-type', 'rl','application/resource-lists+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'rld','application/resource-lists-diff+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'rs','application/rls-services+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'gbr','application/rpki-ghostbusters')
    into oos_util_values(cat, name, value) values('mime-type', 'mft','application/rpki-manifest')
    into oos_util_values(cat, name, value) values('mime-type', 'roa','application/rpki-roa')
    into oos_util_values(cat, name, value) values('mime-type', 'rsd','application/rsd+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'rss','application/rss+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'rtf','text/rtf')
    into oos_util_values(cat, name, value) values('mime-type', 'sbml','application/sbml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'scq','application/scvp-cv-request')
    into oos_util_values(cat, name, value) values('mime-type', 'scs','application/scvp-cv-response')
    into oos_util_values(cat, name, value) values('mime-type', 'spq','application/scvp-vp-request')
    into oos_util_values(cat, name, value) values('mime-type', 'spp','application/scvp-vp-response')
    into oos_util_values(cat, name, value) values('mime-type', 'sdp','application/sdp')
    into oos_util_values(cat, name, value) values('mime-type', 'setpay','application/set-payment-initiation')
    into oos_util_values(cat, name, value) values('mime-type', 'setreg','application/set-registration-initiation')
    into oos_util_values(cat, name, value) values('mime-type', 'shf','application/shf+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'smi','application/smil+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'smil','application/smil+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'rq','application/sparql-query')
    into oos_util_values(cat, name, value) values('mime-type', 'srx','application/sparql-results+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'gram','application/srgs')
    into oos_util_values(cat, name, value) values('mime-type', 'grxml','application/srgs+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'sru','application/sru+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'ssdl','application/ssdl+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'ssml','application/ssml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'tei','application/tei+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'teicorpus','application/tei+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'tfi','application/thraud+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'tsd','application/timestamped-data')
    into oos_util_values(cat, name, value) values('mime-type', 'plb','application/vnd.3gpp.pic-bw-large')
    into oos_util_values(cat, name, value) values('mime-type', 'psb','application/vnd.3gpp.pic-bw-small')
    into oos_util_values(cat, name, value) values('mime-type', 'pvb','application/vnd.3gpp.pic-bw-var')
    into oos_util_values(cat, name, value) values('mime-type', 'tcap','application/vnd.3gpp2.tcap')
    into oos_util_values(cat, name, value) values('mime-type', 'pwn','application/vnd.3m.post-it-notes')
    into oos_util_values(cat, name, value) values('mime-type', 'aso','application/vnd.accpac.simply.aso')
    into oos_util_values(cat, name, value) values('mime-type', 'imp','application/vnd.accpac.simply.imp')
    into oos_util_values(cat, name, value) values('mime-type', 'acu','application/vnd.acucobol')
    into oos_util_values(cat, name, value) values('mime-type', 'atc','application/vnd.acucorp')
    into oos_util_values(cat, name, value) values('mime-type', 'acutc','application/vnd.acucorp')
    into oos_util_values(cat, name, value) values('mime-type', 'air','application/vnd.adobe.air-application-installer-package+zip')
    into oos_util_values(cat, name, value) values('mime-type', 'fcdt','application/vnd.adobe.formscentral.fcdt')
    into oos_util_values(cat, name, value) values('mime-type', 'fxp','application/vnd.adobe.fxp')
    into oos_util_values(cat, name, value) values('mime-type', 'fxpl','application/vnd.adobe.fxp')
    into oos_util_values(cat, name, value) values('mime-type', 'xdp','application/vnd.adobe.xdp+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xfdf','application/vnd.adobe.xfdf')
    into oos_util_values(cat, name, value) values('mime-type', 'ahead','application/vnd.ahead.space')
    into oos_util_values(cat, name, value) values('mime-type', 'azf','application/vnd.airzip.filesecure.azf')
    into oos_util_values(cat, name, value) values('mime-type', 'azs','application/vnd.airzip.filesecure.azs')
    into oos_util_values(cat, name, value) values('mime-type', 'azw','application/vnd.amazon.ebook')
    into oos_util_values(cat, name, value) values('mime-type', 'acc','application/vnd.americandynamics.acc')
    into oos_util_values(cat, name, value) values('mime-type', 'ami','application/vnd.amiga.ami')
    into oos_util_values(cat, name, value) values('mime-type', 'apk','application/vnd.android.package-archive')
    into oos_util_values(cat, name, value) values('mime-type', 'cii','application/vnd.anser-web-certificate-issue-initiation')
    into oos_util_values(cat, name, value) values('mime-type', 'fti','application/vnd.anser-web-funds-transfer-initiation')
    into oos_util_values(cat, name, value) values('mime-type', 'atx','application/vnd.antix.game-component')
    into oos_util_values(cat, name, value) values('mime-type', 'mpkg','application/vnd.apple.installer+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'm3u8','application/vnd.apple.mpegurl')
    into oos_util_values(cat, name, value) values('mime-type', 'pkpass','application/vnd.apple.pkpass')
    into oos_util_values(cat, name, value) values('mime-type', 'swi','application/vnd.aristanetworks.swi')
    into oos_util_values(cat, name, value) values('mime-type', 'iota','application/vnd.astraea-software.iota')
    into oos_util_values(cat, name, value) values('mime-type', 'aep','application/vnd.audiograph')
    into oos_util_values(cat, name, value) values('mime-type', 'mpm','application/vnd.blueice.multipass')
    into oos_util_values(cat, name, value) values('mime-type', 'bmi','application/vnd.bmi')
    into oos_util_values(cat, name, value) values('mime-type', 'rep','application/vnd.businessobjects')
    into oos_util_values(cat, name, value) values('mime-type', 'cdxml','application/vnd.chemdraw+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'mmd','application/vnd.chipnuts.karaoke-mmd')
    into oos_util_values(cat, name, value) values('mime-type', 'cdy','application/vnd.cinderella')
    into oos_util_values(cat, name, value) values('mime-type', 'cla','application/vnd.claymore')
    into oos_util_values(cat, name, value) values('mime-type', 'rp9','application/vnd.cloanto.rp9')
    into oos_util_values(cat, name, value) values('mime-type', 'c4g','application/vnd.clonk.c4group')
    into oos_util_values(cat, name, value) values('mime-type', 'c4d','application/vnd.clonk.c4group')
    into oos_util_values(cat, name, value) values('mime-type', 'c4f','application/vnd.clonk.c4group')
    into oos_util_values(cat, name, value) values('mime-type', 'c4p','application/vnd.clonk.c4group')
    into oos_util_values(cat, name, value) values('mime-type', 'c4u','application/vnd.clonk.c4group')
    into oos_util_values(cat, name, value) values('mime-type', 'c11amc','application/vnd.cluetrust.cartomobile-config')
    into oos_util_values(cat, name, value) values('mime-type', 'c11amz','application/vnd.cluetrust.cartomobile-config-pkg')
    into oos_util_values(cat, name, value) values('mime-type', 'csp','application/vnd.commonspace')
    into oos_util_values(cat, name, value) values('mime-type', 'cdbcmsg','application/vnd.contact.cmsg')
    into oos_util_values(cat, name, value) values('mime-type', 'cmc','application/vnd.cosmocaller')
    into oos_util_values(cat, name, value) values('mime-type', 'clkx','application/vnd.crick.clicker')
    into oos_util_values(cat, name, value) values('mime-type', 'clkk','application/vnd.crick.clicker.keyboard')
    into oos_util_values(cat, name, value) values('mime-type', 'clkp','application/vnd.crick.clicker.palette')
    into oos_util_values(cat, name, value) values('mime-type', 'clkt','application/vnd.crick.clicker.template')
    into oos_util_values(cat, name, value) values('mime-type', 'clkw','application/vnd.crick.clicker.wordbank')
    into oos_util_values(cat, name, value) values('mime-type', 'wbs','application/vnd.criticaltools.wbs+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'pml','application/vnd.ctc-posml')
    into oos_util_values(cat, name, value) values('mime-type', 'ppd','application/vnd.cups-ppd')
    into oos_util_values(cat, name, value) values('mime-type', 'car','application/vnd.curl.car')
    into oos_util_values(cat, name, value) values('mime-type', 'pcurl','application/vnd.curl.pcurl')
    into oos_util_values(cat, name, value) values('mime-type', 'dart','application/vnd.dart')
    into oos_util_values(cat, name, value) values('mime-type', 'rdz','application/vnd.data-vision.rdz')
    into oos_util_values(cat, name, value) values('mime-type', 'uvf','application/vnd.dece.data')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvf','application/vnd.dece.data')
    into oos_util_values(cat, name, value) values('mime-type', 'uvd','application/vnd.dece.data')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvd','application/vnd.dece.data')
    into oos_util_values(cat, name, value) values('mime-type', 'uvt','application/vnd.dece.ttml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvt','application/vnd.dece.ttml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'uvx','application/vnd.dece.unspecified')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvx','application/vnd.dece.unspecified')
    into oos_util_values(cat, name, value) values('mime-type', 'uvz','application/vnd.dece.zip')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvz','application/vnd.dece.zip')
    into oos_util_values(cat, name, value) values('mime-type', 'fe_launch','application/vnd.denovo.fcselayout-link')
    into oos_util_values(cat, name, value) values('mime-type', 'dna','application/vnd.dna')
    into oos_util_values(cat, name, value) values('mime-type', 'mlp','application/vnd.dolby.mlp')
    into oos_util_values(cat, name, value) values('mime-type', 'dpg','application/vnd.dpgraph')
    into oos_util_values(cat, name, value) values('mime-type', 'dfac','application/vnd.dreamfactory')
    into oos_util_values(cat, name, value) values('mime-type', 'kpxx','application/vnd.ds-keypoint')
    into oos_util_values(cat, name, value) values('mime-type', 'ait','application/vnd.dvb.ait')
    into oos_util_values(cat, name, value) values('mime-type', 'svc','application/vnd.dvb.service')
    into oos_util_values(cat, name, value) values('mime-type', 'geo','application/vnd.dynageo')
    into oos_util_values(cat, name, value) values('mime-type', 'mag','application/vnd.ecowin.chart')
    into oos_util_values(cat, name, value) values('mime-type', 'nml','application/vnd.enliven')
    into oos_util_values(cat, name, value) values('mime-type', 'esf','application/vnd.epson.esf')
    into oos_util_values(cat, name, value) values('mime-type', 'msf','application/vnd.epson.msf')
    into oos_util_values(cat, name, value) values('mime-type', 'qam','application/vnd.epson.quickanime')
    into oos_util_values(cat, name, value) values('mime-type', 'slt','application/vnd.epson.salt')
    into oos_util_values(cat, name, value) values('mime-type', 'ssf','application/vnd.epson.ssf')
    into oos_util_values(cat, name, value) values('mime-type', 'es3','application/vnd.eszigno3+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'et3','application/vnd.eszigno3+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'ez2','application/vnd.ezpix-album')
    into oos_util_values(cat, name, value) values('mime-type', 'ez3','application/vnd.ezpix-package')
    into oos_util_values(cat, name, value) values('mime-type', 'fdf','application/vnd.fdf')
    into oos_util_values(cat, name, value) values('mime-type', 'mseed','application/vnd.fdsn.mseed')
    into oos_util_values(cat, name, value) values('mime-type', 'seed','application/vnd.fdsn.seed')
    into oos_util_values(cat, name, value) values('mime-type', 'dataless','application/vnd.fdsn.seed')
    into oos_util_values(cat, name, value) values('mime-type', 'gph','application/vnd.flographit')
    into oos_util_values(cat, name, value) values('mime-type', 'ftc','application/vnd.fluxtime.clip')
    into oos_util_values(cat, name, value) values('mime-type', 'fm','application/vnd.framemaker')
    into oos_util_values(cat, name, value) values('mime-type', 'frame','application/vnd.framemaker')
    into oos_util_values(cat, name, value) values('mime-type', 'maker','application/vnd.framemaker')
    into oos_util_values(cat, name, value) values('mime-type', 'book','application/vnd.framemaker')
    into oos_util_values(cat, name, value) values('mime-type', 'fnc','application/vnd.frogans.fnc')
    into oos_util_values(cat, name, value) values('mime-type', 'ltf','application/vnd.frogans.ltf')
    into oos_util_values(cat, name, value) values('mime-type', 'fsc','application/vnd.fsc.weblaunch')
    into oos_util_values(cat, name, value) values('mime-type', 'oas','application/vnd.fujitsu.oasys')
    into oos_util_values(cat, name, value) values('mime-type', 'oa2','application/vnd.fujitsu.oasys2')
    into oos_util_values(cat, name, value) values('mime-type', 'oa3','application/vnd.fujitsu.oasys3')
    into oos_util_values(cat, name, value) values('mime-type', 'fg5','application/vnd.fujitsu.oasysgp')
    into oos_util_values(cat, name, value) values('mime-type', 'bh2','application/vnd.fujitsu.oasysprs')
    into oos_util_values(cat, name, value) values('mime-type', 'ddd','application/vnd.fujixerox.ddd')
    into oos_util_values(cat, name, value) values('mime-type', 'xdw','application/vnd.fujixerox.docuworks')
    into oos_util_values(cat, name, value) values('mime-type', 'xbd','application/vnd.fujixerox.docuworks.binder')
    into oos_util_values(cat, name, value) values('mime-type', 'fzs','application/vnd.fuzzysheet')
    into oos_util_values(cat, name, value) values('mime-type', 'txd','application/vnd.genomatix.tuxedo')
    into oos_util_values(cat, name, value) values('mime-type', 'ggb','application/vnd.geogebra.file')
    into oos_util_values(cat, name, value) values('mime-type', 'ggt','application/vnd.geogebra.tool')
    into oos_util_values(cat, name, value) values('mime-type', 'gex','application/vnd.geometry-explorer')
    into oos_util_values(cat, name, value) values('mime-type', 'gre','application/vnd.geometry-explorer')
    into oos_util_values(cat, name, value) values('mime-type', 'gxt','application/vnd.geonext')
    into oos_util_values(cat, name, value) values('mime-type', 'g2w','application/vnd.geoplan')
    into oos_util_values(cat, name, value) values('mime-type', 'g3w','application/vnd.geospace')
    into oos_util_values(cat, name, value) values('mime-type', 'gmx','application/vnd.gmx')
    into oos_util_values(cat, name, value) values('mime-type', 'kml','application/vnd.google-earth.kml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'kmz','application/vnd.google-earth.kmz')
    into oos_util_values(cat, name, value) values('mime-type', 'gqf','application/vnd.grafeq')
    into oos_util_values(cat, name, value) values('mime-type', 'gqs','application/vnd.grafeq')
    into oos_util_values(cat, name, value) values('mime-type', 'gac','application/vnd.groove-account')
    into oos_util_values(cat, name, value) values('mime-type', 'ghf','application/vnd.groove-help')
    into oos_util_values(cat, name, value) values('mime-type', 'gim','application/vnd.groove-identity-message')
    into oos_util_values(cat, name, value) values('mime-type', 'grv','application/vnd.groove-injector')
    into oos_util_values(cat, name, value) values('mime-type', 'gtm','application/vnd.groove-tool-message')
    into oos_util_values(cat, name, value) values('mime-type', 'tpl','application/vnd.groove-tool-template')
    into oos_util_values(cat, name, value) values('mime-type', 'vcg','application/vnd.groove-vcard')
    into oos_util_values(cat, name, value) values('mime-type', 'hal','application/vnd.hal+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'zmm','application/vnd.handheld-entertainment+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'hbci','application/vnd.hbci')
    into oos_util_values(cat, name, value) values('mime-type', 'les','application/vnd.hhe.lesson-player')
    into oos_util_values(cat, name, value) values('mime-type', 'hpgl','application/vnd.hp-hpgl')
    into oos_util_values(cat, name, value) values('mime-type', 'hpid','application/vnd.hp-hpid')
    into oos_util_values(cat, name, value) values('mime-type', 'hps','application/vnd.hp-hps')
    into oos_util_values(cat, name, value) values('mime-type', 'jlt','application/vnd.hp-jlyt')
    into oos_util_values(cat, name, value) values('mime-type', 'pcl','application/vnd.hp-pcl')
    into oos_util_values(cat, name, value) values('mime-type', 'pclxl','application/vnd.hp-pclxl')
    into oos_util_values(cat, name, value) values('mime-type', 'sfd-hdstx','application/vnd.hydrostatix.sof-data')
    into oos_util_values(cat, name, value) values('mime-type', 'mpy','application/vnd.ibm.minipay')
    into oos_util_values(cat, name, value) values('mime-type', 'afp','application/vnd.ibm.modcap')
    into oos_util_values(cat, name, value) values('mime-type', 'listafp','application/vnd.ibm.modcap')
    into oos_util_values(cat, name, value) values('mime-type', 'list3820','application/vnd.ibm.modcap')
    into oos_util_values(cat, name, value) values('mime-type', 'irm','application/vnd.ibm.rights-management')
    into oos_util_values(cat, name, value) values('mime-type', 'sc','application/vnd.ibm.secure-container')
    into oos_util_values(cat, name, value) values('mime-type', 'icc','application/vnd.iccprofile')
    into oos_util_values(cat, name, value) values('mime-type', 'icm','application/vnd.iccprofile')
    into oos_util_values(cat, name, value) values('mime-type', 'igl','application/vnd.igloader')
    into oos_util_values(cat, name, value) values('mime-type', 'ivp','application/vnd.immervision-ivp')
    into oos_util_values(cat, name, value) values('mime-type', 'ivu','application/vnd.immervision-ivu')
    into oos_util_values(cat, name, value) values('mime-type', 'igm','application/vnd.insors.igm')
    into oos_util_values(cat, name, value) values('mime-type', 'xpw','application/vnd.intercon.formnet')
    into oos_util_values(cat, name, value) values('mime-type', 'xpx','application/vnd.intercon.formnet')
    into oos_util_values(cat, name, value) values('mime-type', 'i2g','application/vnd.intergeo')
    into oos_util_values(cat, name, value) values('mime-type', 'qbo','application/vnd.intu.qbo')
    into oos_util_values(cat, name, value) values('mime-type', 'qfx','application/vnd.intu.qfx')
    into oos_util_values(cat, name, value) values('mime-type', 'rcprofile','application/vnd.ipunplugged.rcprofile')
    into oos_util_values(cat, name, value) values('mime-type', 'irp','application/vnd.irepository.package+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xpr','application/vnd.is-xpr')
    into oos_util_values(cat, name, value) values('mime-type', 'fcs','application/vnd.isac.fcs')
    into oos_util_values(cat, name, value) values('mime-type', 'jam','application/vnd.jam')
    into oos_util_values(cat, name, value) values('mime-type', 'rms','application/vnd.jcp.javame.midlet-rms')
    into oos_util_values(cat, name, value) values('mime-type', 'jisp','application/vnd.jisp')
    into oos_util_values(cat, name, value) values('mime-type', 'joda','application/vnd.joost.joda-archive')
    into oos_util_values(cat, name, value) values('mime-type', 'ktz','application/vnd.kahootz')
    into oos_util_values(cat, name, value) values('mime-type', 'ktr','application/vnd.kahootz')
    into oos_util_values(cat, name, value) values('mime-type', 'karbon','application/vnd.kde.karbon')
    into oos_util_values(cat, name, value) values('mime-type', 'chrt','application/vnd.kde.kchart')
    into oos_util_values(cat, name, value) values('mime-type', 'kfo','application/vnd.kde.kformula')
    into oos_util_values(cat, name, value) values('mime-type', 'flw','application/vnd.kde.kivio')
    into oos_util_values(cat, name, value) values('mime-type', 'kon','application/vnd.kde.kontour')
    into oos_util_values(cat, name, value) values('mime-type', 'kpr','application/vnd.kde.kpresenter')
    into oos_util_values(cat, name, value) values('mime-type', 'kpt','application/vnd.kde.kpresenter')
    into oos_util_values(cat, name, value) values('mime-type', 'ksp','application/vnd.kde.kspread')
    into oos_util_values(cat, name, value) values('mime-type', 'kwd','application/vnd.kde.kword')
    into oos_util_values(cat, name, value) values('mime-type', 'kwt','application/vnd.kde.kword')
    into oos_util_values(cat, name, value) values('mime-type', 'htke','application/vnd.kenameaapp')
    into oos_util_values(cat, name, value) values('mime-type', 'kia','application/vnd.kidspiration')
    into oos_util_values(cat, name, value) values('mime-type', 'kne','application/vnd.kinar')
    into oos_util_values(cat, name, value) values('mime-type', 'knp','application/vnd.kinar')
    into oos_util_values(cat, name, value) values('mime-type', 'skp','application/vnd.koan')
    into oos_util_values(cat, name, value) values('mime-type', 'skd','application/vnd.koan')
    into oos_util_values(cat, name, value) values('mime-type', 'skt','application/vnd.koan')
    into oos_util_values(cat, name, value) values('mime-type', 'skm','application/vnd.koan')
    into oos_util_values(cat, name, value) values('mime-type', 'sse','application/vnd.kodak-descriptor')
    into oos_util_values(cat, name, value) values('mime-type', 'lasxml','application/vnd.las.las+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'lbd','application/vnd.llamagraphics.life-balance.desktop')
    into oos_util_values(cat, name, value) values('mime-type', 'lbe','application/vnd.llamagraphics.life-balance.exchange+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'apr','application/vnd.lotus-approach')
    into oos_util_values(cat, name, value) values('mime-type', 'pre','application/vnd.lotus-freelance')
    into oos_util_values(cat, name, value) values('mime-type', 'nsf','application/vnd.lotus-notes')
    into oos_util_values(cat, name, value) values('mime-type', 'org','application/vnd.lotus-organizer')
    into oos_util_values(cat, name, value) values('mime-type', 'scm','application/vnd.lotus-screencam')
    into oos_util_values(cat, name, value) values('mime-type', 'lwp','application/vnd.lotus-wordpro')
    into oos_util_values(cat, name, value) values('mime-type', 'portpkg','application/vnd.macports.portpkg')
    into oos_util_values(cat, name, value) values('mime-type', 'mcd','application/vnd.mcd')
    into oos_util_values(cat, name, value) values('mime-type', 'mc1','application/vnd.medcalcdata')
    into oos_util_values(cat, name, value) values('mime-type', 'cdkey','application/vnd.mediastation.cdkey')
    into oos_util_values(cat, name, value) values('mime-type', 'mwf','application/vnd.mfer')
    into oos_util_values(cat, name, value) values('mime-type', 'mfm','application/vnd.mfmp')
    into oos_util_values(cat, name, value) values('mime-type', 'flo','application/vnd.micrografx.flo')
    into oos_util_values(cat, name, value) values('mime-type', 'igx','application/vnd.micrografx.igx')
    into oos_util_values(cat, name, value) values('mime-type', 'mif','application/vnd.mif')
    into oos_util_values(cat, name, value) values('mime-type', 'daf','application/vnd.mobius.daf')
    into oos_util_values(cat, name, value) values('mime-type', 'dis','application/vnd.mobius.dis')
    into oos_util_values(cat, name, value) values('mime-type', 'mbk','application/vnd.mobius.mbk')
    into oos_util_values(cat, name, value) values('mime-type', 'mqy','application/vnd.mobius.mqy')
    into oos_util_values(cat, name, value) values('mime-type', 'msl','application/vnd.mobius.msl')
    into oos_util_values(cat, name, value) values('mime-type', 'plc','application/vnd.mobius.plc')
    into oos_util_values(cat, name, value) values('mime-type', 'txf','application/vnd.mobius.txf')
    into oos_util_values(cat, name, value) values('mime-type', 'mpn','application/vnd.mophun.application')
    into oos_util_values(cat, name, value) values('mime-type', 'mpc','application/vnd.mophun.certificate')
    into oos_util_values(cat, name, value) values('mime-type', 'xul','application/vnd.mozilla.xul+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'cil','application/vnd.ms-artgalry')
    into oos_util_values(cat, name, value) values('mime-type', 'cab','application/vnd.ms-cab-compressed')
    into oos_util_values(cat, name, value) values('mime-type', 'xls','application/vnd.ms-excel')
    into oos_util_values(cat, name, value) values('mime-type', 'xlm','application/vnd.ms-excel')
    into oos_util_values(cat, name, value) values('mime-type', 'xla','application/vnd.ms-excel')
    into oos_util_values(cat, name, value) values('mime-type', 'xlc','application/vnd.ms-excel')
    into oos_util_values(cat, name, value) values('mime-type', 'xlt','application/vnd.ms-excel')
    into oos_util_values(cat, name, value) values('mime-type', 'xlw','application/vnd.ms-excel')
    into oos_util_values(cat, name, value) values('mime-type', 'xlam','application/vnd.ms-excel.addin.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'xlsb','application/vnd.ms-excel.sheet.binary.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'xlsm','application/vnd.ms-excel.sheet.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'xltm','application/vnd.ms-excel.template.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'eot','application/vnd.ms-fontobject')
    into oos_util_values(cat, name, value) values('mime-type', 'chm','application/vnd.ms-htmlhelp')
    into oos_util_values(cat, name, value) values('mime-type', 'ims','application/vnd.ms-ims')
    into oos_util_values(cat, name, value) values('mime-type', 'lrm','application/vnd.ms-lrm')
    into oos_util_values(cat, name, value) values('mime-type', 'thmx','application/vnd.ms-officetheme')
    into oos_util_values(cat, name, value) values('mime-type', 'cat','application/vnd.ms-pki.seccat')
    into oos_util_values(cat, name, value) values('mime-type', 'stl','application/vnd.ms-pki.stl')
    into oos_util_values(cat, name, value) values('mime-type', 'ppt','application/vnd.ms-powerpoint')
    into oos_util_values(cat, name, value) values('mime-type', 'pps','application/vnd.ms-powerpoint')
    into oos_util_values(cat, name, value) values('mime-type', 'pot','application/vnd.ms-powerpoint')
    into oos_util_values(cat, name, value) values('mime-type', 'ppam','application/vnd.ms-powerpoint.addin.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'pptm','application/vnd.ms-powerpoint.presentation.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'sldm','application/vnd.ms-powerpoint.slide.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'ppsm','application/vnd.ms-powerpoint.slideshow.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'potm','application/vnd.ms-powerpoint.template.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'mpp','application/vnd.ms-project')
    into oos_util_values(cat, name, value) values('mime-type', 'mpt','application/vnd.ms-project')
    into oos_util_values(cat, name, value) values('mime-type', 'docm','application/vnd.ms-word.document.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'dotm','application/vnd.ms-word.template.macroenabled.12')
    into oos_util_values(cat, name, value) values('mime-type', 'wps','application/vnd.ms-works')
    into oos_util_values(cat, name, value) values('mime-type', 'wks','application/vnd.ms-works')
    into oos_util_values(cat, name, value) values('mime-type', 'wcm','application/vnd.ms-works')
    into oos_util_values(cat, name, value) values('mime-type', 'wdb','application/vnd.ms-works')
    into oos_util_values(cat, name, value) values('mime-type', 'wpl','application/vnd.ms-wpl')
    into oos_util_values(cat, name, value) values('mime-type', 'xps','application/vnd.ms-xpsdocument')
    into oos_util_values(cat, name, value) values('mime-type', 'mseq','application/vnd.mseq')
    into oos_util_values(cat, name, value) values('mime-type', 'mus','application/vnd.musician')
    into oos_util_values(cat, name, value) values('mime-type', 'msty','application/vnd.muvee.style')
    into oos_util_values(cat, name, value) values('mime-type', 'taglet','application/vnd.mynfc')
    into oos_util_values(cat, name, value) values('mime-type', 'nlu','application/vnd.neurolanguage.nlu')
    into oos_util_values(cat, name, value) values('mime-type', 'ntf','application/vnd.nitf')
    into oos_util_values(cat, name, value) values('mime-type', 'nitf','application/vnd.nitf')
    into oos_util_values(cat, name, value) values('mime-type', 'nnd','application/vnd.noblenet-directory')
    into oos_util_values(cat, name, value) values('mime-type', 'nns','application/vnd.noblenet-sealer')
    into oos_util_values(cat, name, value) values('mime-type', 'nnw','application/vnd.noblenet-web')
    into oos_util_values(cat, name, value) values('mime-type', 'ngdat','application/vnd.nokia.n-gage.data')
    into oos_util_values(cat, name, value) values('mime-type', 'n-gage','application/vnd.nokia.n-gage.symbian.install')
    into oos_util_values(cat, name, value) values('mime-type', 'rpst','application/vnd.nokia.radio-preset')
    into oos_util_values(cat, name, value) values('mime-type', 'rpss','application/vnd.nokia.radio-presets')
    into oos_util_values(cat, name, value) values('mime-type', 'edm','application/vnd.novadigm.edm')
    into oos_util_values(cat, name, value) values('mime-type', 'edx','application/vnd.novadigm.edx')
    into oos_util_values(cat, name, value) values('mime-type', 'ext','application/vnd.novadigm.ext')
    into oos_util_values(cat, name, value) values('mime-type', 'odc','application/vnd.oasis.opendocument.chart')
    into oos_util_values(cat, name, value) values('mime-type', 'otc','application/vnd.oasis.opendocument.chart-template')
    into oos_util_values(cat, name, value) values('mime-type', 'odb','application/vnd.oasis.opendocument.database')
    into oos_util_values(cat, name, value) values('mime-type', 'odf','application/vnd.oasis.opendocument.formula')
    into oos_util_values(cat, name, value) values('mime-type', 'odft','application/vnd.oasis.opendocument.formula-template')
    into oos_util_values(cat, name, value) values('mime-type', 'odg','application/vnd.oasis.opendocument.graphics')
    into oos_util_values(cat, name, value) values('mime-type', 'otg','application/vnd.oasis.opendocument.graphics-template')
    into oos_util_values(cat, name, value) values('mime-type', 'odi','application/vnd.oasis.opendocument.image')
    into oos_util_values(cat, name, value) values('mime-type', 'oti','application/vnd.oasis.opendocument.image-template')
    into oos_util_values(cat, name, value) values('mime-type', 'odp','application/vnd.oasis.opendocument.presentation')
    into oos_util_values(cat, name, value) values('mime-type', 'otp','application/vnd.oasis.opendocument.presentation-template')
    into oos_util_values(cat, name, value) values('mime-type', 'ods','application/vnd.oasis.opendocument.spreadsheet')
    into oos_util_values(cat, name, value) values('mime-type', 'ots','application/vnd.oasis.opendocument.spreadsheet-template')
    into oos_util_values(cat, name, value) values('mime-type', 'odt','application/vnd.oasis.opendocument.text')
    into oos_util_values(cat, name, value) values('mime-type', 'odm','application/vnd.oasis.opendocument.text-master')
    into oos_util_values(cat, name, value) values('mime-type', 'ott','application/vnd.oasis.opendocument.text-template')
    into oos_util_values(cat, name, value) values('mime-type', 'oth','application/vnd.oasis.opendocument.text-web')
    into oos_util_values(cat, name, value) values('mime-type', 'xo','application/vnd.olpc-sugar')
    into oos_util_values(cat, name, value) values('mime-type', 'dd2','application/vnd.oma.dd2+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'oxt','application/vnd.openofficeorg.extension')
    into oos_util_values(cat, name, value) values('mime-type', 'pptx','application/vnd.openxmlformats-officedocument.presentationml.presentation')
    into oos_util_values(cat, name, value) values('mime-type', 'sldx','application/vnd.openxmlformats-officedocument.presentationml.slide')
    into oos_util_values(cat, name, value) values('mime-type', 'ppsx','application/vnd.openxmlformats-officedocument.presentationml.slideshow')
    into oos_util_values(cat, name, value) values('mime-type', 'potx','application/vnd.openxmlformats-officedocument.presentationml.template')
    into oos_util_values(cat, name, value) values('mime-type', 'xlsx','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    into oos_util_values(cat, name, value) values('mime-type', 'xltx','application/vnd.openxmlformats-officedocument.spreadsheetml.template')
    into oos_util_values(cat, name, value) values('mime-type', 'docx','application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    into oos_util_values(cat, name, value) values('mime-type', 'dotx','application/vnd.openxmlformats-officedocument.wordprocessingml.template')
    into oos_util_values(cat, name, value) values('mime-type', 'mgp','application/vnd.osgeo.mapguide.package')
    into oos_util_values(cat, name, value) values('mime-type', 'dp','application/vnd.osgi.dp')
    into oos_util_values(cat, name, value) values('mime-type', 'esa','application/vnd.osgi.subsystem')
    into oos_util_values(cat, name, value) values('mime-type', 'pdb','application/vnd.palm')
    into oos_util_values(cat, name, value) values('mime-type', 'pqa','application/vnd.palm')
    into oos_util_values(cat, name, value) values('mime-type', 'oprc','application/vnd.palm')
    into oos_util_values(cat, name, value) values('mime-type', 'paw','application/vnd.pawaafile')
    into oos_util_values(cat, name, value) values('mime-type', 'str','application/vnd.pg.format')
    into oos_util_values(cat, name, value) values('mime-type', 'ei6','application/vnd.pg.osasli')
    into oos_util_values(cat, name, value) values('mime-type', 'efif','application/vnd.picsel')
    into oos_util_values(cat, name, value) values('mime-type', 'wg','application/vnd.pmi.widget')
    into oos_util_values(cat, name, value) values('mime-type', 'plf','application/vnd.pocketlearn')
    into oos_util_values(cat, name, value) values('mime-type', 'pbd','application/vnd.powerbuilder6')
    into oos_util_values(cat, name, value) values('mime-type', 'box','application/vnd.previewsystems.box')
    into oos_util_values(cat, name, value) values('mime-type', 'mgz','application/vnd.proteus.magazine')
    into oos_util_values(cat, name, value) values('mime-type', 'qps','application/vnd.publishare-delta-tree')
    into oos_util_values(cat, name, value) values('mime-type', 'ptid','application/vnd.pvi.ptid1')
    into oos_util_values(cat, name, value) values('mime-type', 'qxd','application/vnd.quark.quarkxpress')
    into oos_util_values(cat, name, value) values('mime-type', 'qxt','application/vnd.quark.quarkxpress')
    into oos_util_values(cat, name, value) values('mime-type', 'qwd','application/vnd.quark.quarkxpress')
    into oos_util_values(cat, name, value) values('mime-type', 'qwt','application/vnd.quark.quarkxpress')
    into oos_util_values(cat, name, value) values('mime-type', 'qxl','application/vnd.quark.quarkxpress')
    into oos_util_values(cat, name, value) values('mime-type', 'qxb','application/vnd.quark.quarkxpress')
    into oos_util_values(cat, name, value) values('mime-type', 'bed','application/vnd.realvnc.bed')
    into oos_util_values(cat, name, value) values('mime-type', 'mxl','application/vnd.recordare.musicxml')
    into oos_util_values(cat, name, value) values('mime-type', 'musicxml','application/vnd.recordare.musicxml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'cryptonote','application/vnd.rig.cryptonote')
    into oos_util_values(cat, name, value) values('mime-type', 'cod','application/vnd.rim.cod')
    into oos_util_values(cat, name, value) values('mime-type', 'rm','application/vnd.rn-realmedia')
    into oos_util_values(cat, name, value) values('mime-type', 'rmvb','application/vnd.rn-realmedia-vbr')
    into oos_util_values(cat, name, value) values('mime-type', 'link66','application/vnd.route66.link66+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'st','application/vnd.sailingtracker.track')
    into oos_util_values(cat, name, value) values('mime-type', 'see','application/vnd.seemail')
    into oos_util_values(cat, name, value) values('mime-type', 'sema','application/vnd.sema')
    into oos_util_values(cat, name, value) values('mime-type', 'semd','application/vnd.semd')
    into oos_util_values(cat, name, value) values('mime-type', 'semf','application/vnd.semf')
    into oos_util_values(cat, name, value) values('mime-type', 'ifm','application/vnd.shana.informed.formdata')
    into oos_util_values(cat, name, value) values('mime-type', 'itp','application/vnd.shana.informed.formtemplate')
    into oos_util_values(cat, name, value) values('mime-type', 'iif','application/vnd.shana.informed.interchange')
    into oos_util_values(cat, name, value) values('mime-type', 'ipk','application/vnd.shana.informed.package')
    into oos_util_values(cat, name, value) values('mime-type', 'twd','application/vnd.simtech-mindmapper')
    into oos_util_values(cat, name, value) values('mime-type', 'twds','application/vnd.simtech-mindmapper')
    into oos_util_values(cat, name, value) values('mime-type', 'mmf','application/vnd.smaf')
    into oos_util_values(cat, name, value) values('mime-type', 'teacher','application/vnd.smart.teacher')
    into oos_util_values(cat, name, value) values('mime-type', 'sdkm','application/vnd.solent.sdkm+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'sdkd','application/vnd.solent.sdkm+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'dxp','application/vnd.spotfire.dxp')
    into oos_util_values(cat, name, value) values('mime-type', 'sfs','application/vnd.spotfire.sfs')
    into oos_util_values(cat, name, value) values('mime-type', 'sdc','application/vnd.stardivision.calc')
    into oos_util_values(cat, name, value) values('mime-type', 'sda','application/vnd.stardivision.draw')
    into oos_util_values(cat, name, value) values('mime-type', 'sdd','application/vnd.stardivision.impress')
    into oos_util_values(cat, name, value) values('mime-type', 'smf','application/vnd.stardivision.math')
    into oos_util_values(cat, name, value) values('mime-type', 'sdw','application/vnd.stardivision.writer')
    into oos_util_values(cat, name, value) values('mime-type', 'vor','application/vnd.stardivision.writer')
    into oos_util_values(cat, name, value) values('mime-type', 'sgl','application/vnd.stardivision.writer-global')
    into oos_util_values(cat, name, value) values('mime-type', 'smzip','application/vnd.stepmania.package')
    into oos_util_values(cat, name, value) values('mime-type', 'sm','application/vnd.stepmania.stepchart')
    into oos_util_values(cat, name, value) values('mime-type', 'sxc','application/vnd.sun.xml.calc')
    into oos_util_values(cat, name, value) values('mime-type', 'stc','application/vnd.sun.xml.calc.template')
    into oos_util_values(cat, name, value) values('mime-type', 'sxd','application/vnd.sun.xml.draw')
    into oos_util_values(cat, name, value) values('mime-type', 'std','application/vnd.sun.xml.draw.template')
    into oos_util_values(cat, name, value) values('mime-type', 'sxi','application/vnd.sun.xml.impress')
    into oos_util_values(cat, name, value) values('mime-type', 'sti','application/vnd.sun.xml.impress.template')
    into oos_util_values(cat, name, value) values('mime-type', 'sxm','application/vnd.sun.xml.math')
    into oos_util_values(cat, name, value) values('mime-type', 'sxw','application/vnd.sun.xml.writer')
    into oos_util_values(cat, name, value) values('mime-type', 'sxg','application/vnd.sun.xml.writer.global')
    into oos_util_values(cat, name, value) values('mime-type', 'stw','application/vnd.sun.xml.writer.template')
    into oos_util_values(cat, name, value) values('mime-type', 'sus','application/vnd.sus-calendar')
    into oos_util_values(cat, name, value) values('mime-type', 'susp','application/vnd.sus-calendar')
    into oos_util_values(cat, name, value) values('mime-type', 'svd','application/vnd.svd')
    into oos_util_values(cat, name, value) values('mime-type', 'sis','application/vnd.symbian.install')
    into oos_util_values(cat, name, value) values('mime-type', 'sisx','application/vnd.symbian.install')
    into oos_util_values(cat, name, value) values('mime-type', 'xsm','application/vnd.syncml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'bdm','application/vnd.syncml.dm+wbxml')
    into oos_util_values(cat, name, value) values('mime-type', 'xdm','application/vnd.syncml.dm+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'tao','application/vnd.tao.intent-module-archive')
    into oos_util_values(cat, name, value) values('mime-type', 'pcap','application/vnd.tcpdump.pcap')
    into oos_util_values(cat, name, value) values('mime-type', 'cap','application/vnd.tcpdump.pcap')
    into oos_util_values(cat, name, value) values('mime-type', 'dmp','application/vnd.tcpdump.pcap')
    into oos_util_values(cat, name, value) values('mime-type', 'tmo','application/vnd.tmobile-livetv')
    into oos_util_values(cat, name, value) values('mime-type', 'tpt','application/vnd.trid.tpt')
    into oos_util_values(cat, name, value) values('mime-type', 'mxs','application/vnd.triscape.mxs')
    into oos_util_values(cat, name, value) values('mime-type', 'tra','application/vnd.trueapp')
    into oos_util_values(cat, name, value) values('mime-type', 'ufd','application/vnd.ufdl')
    into oos_util_values(cat, name, value) values('mime-type', 'ufdl','application/vnd.ufdl')
    into oos_util_values(cat, name, value) values('mime-type', 'utz','application/vnd.uiq.theme')
    into oos_util_values(cat, name, value) values('mime-type', 'umj','application/vnd.umajin')
    into oos_util_values(cat, name, value) values('mime-type', 'unityweb','application/vnd.unity')
    into oos_util_values(cat, name, value) values('mime-type', 'uoml','application/vnd.uoml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'vcx','application/vnd.vcx')
    into oos_util_values(cat, name, value) values('mime-type', 'vsd','application/vnd.visio')
    into oos_util_values(cat, name, value) values('mime-type', 'vst','application/vnd.visio')
    into oos_util_values(cat, name, value) values('mime-type', 'vss','application/vnd.visio')
    into oos_util_values(cat, name, value) values('mime-type', 'vsw','application/vnd.visio')
    into oos_util_values(cat, name, value) values('mime-type', 'vis','application/vnd.visionary')
    into oos_util_values(cat, name, value) values('mime-type', 'vsf','application/vnd.vsf')
    into oos_util_values(cat, name, value) values('mime-type', 'wbxml','application/vnd.wap.wbxml')
    into oos_util_values(cat, name, value) values('mime-type', 'wmlc','application/vnd.wap.wmlc')
    into oos_util_values(cat, name, value) values('mime-type', 'wmlsc','application/vnd.wap.wmlscriptc')
    into oos_util_values(cat, name, value) values('mime-type', 'wtb','application/vnd.webturbo')
    into oos_util_values(cat, name, value) values('mime-type', 'nbp','application/vnd.wolfram.player')
    into oos_util_values(cat, name, value) values('mime-type', 'wpd','application/vnd.wordperfect')
    into oos_util_values(cat, name, value) values('mime-type', 'wqd','application/vnd.wqd')
    into oos_util_values(cat, name, value) values('mime-type', 'stf','application/vnd.wt.stf')
    into oos_util_values(cat, name, value) values('mime-type', 'xar','application/vnd.xara')
    into oos_util_values(cat, name, value) values('mime-type', 'xfdl','application/vnd.xfdl')
    into oos_util_values(cat, name, value) values('mime-type', 'hvd','application/vnd.yamaha.hv-dic')
    into oos_util_values(cat, name, value) values('mime-type', 'hvs','application/vnd.yamaha.hv-script')
    into oos_util_values(cat, name, value) values('mime-type', 'hvp','application/vnd.yamaha.hv-voice')
    into oos_util_values(cat, name, value) values('mime-type', 'osf','application/vnd.yamaha.openscoreformat')
    into oos_util_values(cat, name, value) values('mime-type', 'osfpvg','application/vnd.yamaha.openscoreformat.osfpvg+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'saf','application/vnd.yamaha.smaf-audio')
    into oos_util_values(cat, name, value) values('mime-type', 'spf','application/vnd.yamaha.smaf-phrase')
    into oos_util_values(cat, name, value) values('mime-type', 'cmp','application/vnd.yellowriver-custom-menu')
    into oos_util_values(cat, name, value) values('mime-type', 'zir','application/vnd.zul')
    into oos_util_values(cat, name, value) values('mime-type', 'zirz','application/vnd.zul')
    into oos_util_values(cat, name, value) values('mime-type', 'zaz','application/vnd.zzazz.deck+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'vxml','application/voicexml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'wgt','application/widget')
    into oos_util_values(cat, name, value) values('mime-type', 'hlp','application/winhlp')
    into oos_util_values(cat, name, value) values('mime-type', 'wsdl','application/wsdl+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'wspolicy','application/wspolicy+xml')
    into oos_util_values(cat, name, value) values('mime-type', '7z','application/x-7z-compressed')
    into oos_util_values(cat, name, value) values('mime-type', 'abw','application/x-abiword')
    into oos_util_values(cat, name, value) values('mime-type', 'ace','application/x-ace-compressed')
    into oos_util_values(cat, name, value) values('mime-type', 'aab','application/x-authorware-bin')
    into oos_util_values(cat, name, value) values('mime-type', 'x32','application/x-authorware-bin')
    into oos_util_values(cat, name, value) values('mime-type', 'u32','application/x-authorware-bin')
    into oos_util_values(cat, name, value) values('mime-type', 'vox','application/x-authorware-bin')
    into oos_util_values(cat, name, value) values('mime-type', 'aam','application/x-authorware-map')
    into oos_util_values(cat, name, value) values('mime-type', 'aas','application/x-authorware-seg')
    into oos_util_values(cat, name, value) values('mime-type', 'bcpio','application/x-bcpio')
    into oos_util_values(cat, name, value) values('mime-type', 'torrent','application/x-bittorrent')
    into oos_util_values(cat, name, value) values('mime-type', 'blb','application/x-blorb')
    into oos_util_values(cat, name, value) values('mime-type', 'blorb','application/x-blorb')
    into oos_util_values(cat, name, value) values('mime-type', 'bz','application/x-bzip')
    into oos_util_values(cat, name, value) values('mime-type', 'bz2','application/x-bzip2')
    into oos_util_values(cat, name, value) values('mime-type', 'boz','application/x-bzip2')
    into oos_util_values(cat, name, value) values('mime-type', 'cbr','application/x-cbr')
    into oos_util_values(cat, name, value) values('mime-type', 'cba','application/x-cbr')
    into oos_util_values(cat, name, value) values('mime-type', 'cbt','application/x-cbr')
    into oos_util_values(cat, name, value) values('mime-type', 'cbz','application/x-cbr')
    into oos_util_values(cat, name, value) values('mime-type', 'cb7','application/x-cbr')
    into oos_util_values(cat, name, value) values('mime-type', 'vcd','application/x-cdlink')
    into oos_util_values(cat, name, value) values('mime-type', 'cfs','application/x-cfs-compressed')
    into oos_util_values(cat, name, value) values('mime-type', 'chat','application/x-chat')
    into oos_util_values(cat, name, value) values('mime-type', 'pgn','application/x-chess-pgn')
    into oos_util_values(cat, name, value) values('mime-type', 'crx','application/x-chrome-extension')
    into oos_util_values(cat, name, value) values('mime-type', 'cco','application/x-cocoa')
    into oos_util_values(cat, name, value) values('mime-type', 'nsc','application/x-conference')
    into oos_util_values(cat, name, value) values('mime-type', 'cpio','application/x-cpio')
    into oos_util_values(cat, name, value) values('mime-type', 'csh','application/x-csh')
    into oos_util_values(cat, name, value) values('mime-type', 'udeb','application/x-debian-package')
    into oos_util_values(cat, name, value) values('mime-type', 'dgc','application/x-dgc-compressed')
    into oos_util_values(cat, name, value) values('mime-type', 'dir','application/x-director')
    into oos_util_values(cat, name, value) values('mime-type', 'dcr','application/x-director')
    into oos_util_values(cat, name, value) values('mime-type', 'dxr','application/x-director')
    into oos_util_values(cat, name, value) values('mime-type', 'cst','application/x-director')
    into oos_util_values(cat, name, value) values('mime-type', 'cct','application/x-director')
    into oos_util_values(cat, name, value) values('mime-type', 'cxt','application/x-director')
    into oos_util_values(cat, name, value) values('mime-type', 'w3d','application/x-director')
    into oos_util_values(cat, name, value) values('mime-type', 'fgd','application/x-director')
    into oos_util_values(cat, name, value) values('mime-type', 'swa','application/x-director')
    into oos_util_values(cat, name, value) values('mime-type', 'wad','application/x-doom')
    into oos_util_values(cat, name, value) values('mime-type', 'ncx','application/x-dtbncx+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'dtb','application/x-dtbook+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'res','application/x-dtbresource+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'dvi','application/x-dvi')
    into oos_util_values(cat, name, value) values('mime-type', 'evy','application/x-envoy')
    into oos_util_values(cat, name, value) values('mime-type', 'eva','application/x-eva')
    into oos_util_values(cat, name, value) values('mime-type', 'bdf','application/x-font-bdf')
    into oos_util_values(cat, name, value) values('mime-type', 'gsf','application/x-font-ghostscript')
    into oos_util_values(cat, name, value) values('mime-type', 'psf','application/x-font-linux-psf')
    into oos_util_values(cat, name, value) values('mime-type', 'otf','font/opentype')
    into oos_util_values(cat, name, value) values('mime-type', 'pcf','application/x-font-pcf')
    into oos_util_values(cat, name, value) values('mime-type', 'snf','application/x-font-snf')
    into oos_util_values(cat, name, value) values('mime-type', 'ttf','application/x-font-ttf')
    into oos_util_values(cat, name, value) values('mime-type', 'ttc','application/x-font-ttf')
    into oos_util_values(cat, name, value) values('mime-type', 'pfa','application/x-font-type1')
    into oos_util_values(cat, name, value) values('mime-type', 'pfb','application/x-font-type1')
    into oos_util_values(cat, name, value) values('mime-type', 'pfm','application/x-font-type1')
    into oos_util_values(cat, name, value) values('mime-type', 'afm','application/x-font-type1')
    into oos_util_values(cat, name, value) values('mime-type', 'arc','application/x-freearc')
    into oos_util_values(cat, name, value) values('mime-type', 'spl','application/x-futuresplash')
    into oos_util_values(cat, name, value) values('mime-type', 'gca','application/x-gca-compressed')
    into oos_util_values(cat, name, value) values('mime-type', 'ulx','application/x-glulx')
    into oos_util_values(cat, name, value) values('mime-type', 'gnumeric','application/x-gnumeric')
    into oos_util_values(cat, name, value) values('mime-type', 'gramps','application/x-gramps-xml')
    into oos_util_values(cat, name, value) values('mime-type', 'gtar','application/x-gtar')
    into oos_util_values(cat, name, value) values('mime-type', 'hdf','application/x-hdf')
    into oos_util_values(cat, name, value) values('mime-type', 'php','application/x-httpd-php')
    into oos_util_values(cat, name, value) values('mime-type', 'install','application/x-install-instructions')
    into oos_util_values(cat, name, value) values('mime-type', 'jardiff','application/x-java-archive-diff')
    into oos_util_values(cat, name, value) values('mime-type', 'jnlp','application/x-java-jnlp-file')
    into oos_util_values(cat, name, value) values('mime-type', 'latex','application/x-latex')
    into oos_util_values(cat, name, value) values('mime-type', 'luac','application/x-lua-bytecode')
    into oos_util_values(cat, name, value) values('mime-type', 'lzh','application/x-lzh-compressed')
    into oos_util_values(cat, name, value) values('mime-type', 'lha','application/x-lzh-compressed')
    into oos_util_values(cat, name, value) values('mime-type', 'run','application/x-makeself')
    into oos_util_values(cat, name, value) values('mime-type', 'mie','application/x-mie')
    into oos_util_values(cat, name, value) values('mime-type', 'prc','application/x-pilot')
    into oos_util_values(cat, name, value) values('mime-type', 'mobi','application/x-mobipocket-ebook')
    into oos_util_values(cat, name, value) values('mime-type', 'application','application/x-ms-application')
    into oos_util_values(cat, name, value) values('mime-type', 'lnk','application/x-ms-shortcut')
    into oos_util_values(cat, name, value) values('mime-type', 'wmd','application/x-ms-wmd')
    into oos_util_values(cat, name, value) values('mime-type', 'wmz','application/x-msmetafile')
    into oos_util_values(cat, name, value) values('mime-type', 'xbap','application/x-ms-xbap')
    into oos_util_values(cat, name, value) values('mime-type', 'mdb','application/x-msaccess')
    into oos_util_values(cat, name, value) values('mime-type', 'obd','application/x-msbinder')
    into oos_util_values(cat, name, value) values('mime-type', 'crd','application/x-mscardfile')
    into oos_util_values(cat, name, value) values('mime-type', 'clp','application/x-msclip')
    into oos_util_values(cat, name, value) values('mime-type', 'com','application/x-msdownload')
    into oos_util_values(cat, name, value) values('mime-type', 'bat','application/x-msdownload')
    into oos_util_values(cat, name, value) values('mime-type', 'mvb','application/x-msmediaview')
    into oos_util_values(cat, name, value) values('mime-type', 'm13','application/x-msmediaview')
    into oos_util_values(cat, name, value) values('mime-type', 'm14','application/x-msmediaview')
    into oos_util_values(cat, name, value) values('mime-type', 'wmf','application/x-msmetafile')
    into oos_util_values(cat, name, value) values('mime-type', 'emf','application/x-msmetafile')
    into oos_util_values(cat, name, value) values('mime-type', 'emz','application/x-msmetafile')
    into oos_util_values(cat, name, value) values('mime-type', 'mny','application/x-msmoney')
    into oos_util_values(cat, name, value) values('mime-type', 'pub','application/x-mspublisher')
    into oos_util_values(cat, name, value) values('mime-type', 'scd','application/x-msschedule')
    into oos_util_values(cat, name, value) values('mime-type', 'trm','application/x-msterminal')
    into oos_util_values(cat, name, value) values('mime-type', 'wri','application/x-mswrite')
    into oos_util_values(cat, name, value) values('mime-type', 'nc','application/x-netcdf')
    into oos_util_values(cat, name, value) values('mime-type', 'cdf','application/x-netcdf')
    into oos_util_values(cat, name, value) values('mime-type', 'pac','application/x-ns-proxy-autoconfig')
    into oos_util_values(cat, name, value) values('mime-type', 'nzb','application/x-nzb')
    into oos_util_values(cat, name, value) values('mime-type', 'pl','application/x-perl')
    into oos_util_values(cat, name, value) values('mime-type', 'pm','application/x-perl')
    into oos_util_values(cat, name, value) values('mime-type', 'p12','application/x-pkcs12')
    into oos_util_values(cat, name, value) values('mime-type', 'pfx','application/x-pkcs12')
    into oos_util_values(cat, name, value) values('mime-type', 'p7b','application/x-pkcs7-certificates')
    into oos_util_values(cat, name, value) values('mime-type', 'spc','application/x-pkcs7-certificates')
    into oos_util_values(cat, name, value) values('mime-type', 'p7r','application/x-pkcs7-certreqresp')
    into oos_util_values(cat, name, value) values('mime-type', 'rar','application/x-rar-compressed')
    into oos_util_values(cat, name, value) values('mime-type', 'rpm','application/x-redhat-package-manager')
    into oos_util_values(cat, name, value) values('mime-type', 'ris','application/x-research-info-systems')
    into oos_util_values(cat, name, value) values('mime-type', 'sea','application/x-sea')
    into oos_util_values(cat, name, value) values('mime-type', 'sh','application/x-sh')
    into oos_util_values(cat, name, value) values('mime-type', 'shar','application/x-shar')
    into oos_util_values(cat, name, value) values('mime-type', 'swf','application/x-shockwave-flash')
    into oos_util_values(cat, name, value) values('mime-type', 'xap','application/x-silverlight-app')
    into oos_util_values(cat, name, value) values('mime-type', 'sql','application/x-sql')
    into oos_util_values(cat, name, value) values('mime-type', 'sit','application/x-stuffit')
    into oos_util_values(cat, name, value) values('mime-type', 'sitx','application/x-stuffitx')
    into oos_util_values(cat, name, value) values('mime-type', 'srt','application/x-subrip')
    into oos_util_values(cat, name, value) values('mime-type', 'sv4cpio','application/x-sv4cpio')
    into oos_util_values(cat, name, value) values('mime-type', 'sv4crc','application/x-sv4crc')
    into oos_util_values(cat, name, value) values('mime-type', 't3','application/x-t3vm-image')
    into oos_util_values(cat, name, value) values('mime-type', 'gam','application/x-tads')
    into oos_util_values(cat, name, value) values('mime-type', 'tar','application/x-tar')
    into oos_util_values(cat, name, value) values('mime-type', 'tcl','application/x-tcl')
    into oos_util_values(cat, name, value) values('mime-type', 'tk','application/x-tcl')
    into oos_util_values(cat, name, value) values('mime-type', 'tex','application/x-tex')
    into oos_util_values(cat, name, value) values('mime-type', 'tfm','application/x-tex-tfm')
    into oos_util_values(cat, name, value) values('mime-type', 'texinfo','application/x-texinfo')
    into oos_util_values(cat, name, value) values('mime-type', 'texi','application/x-texinfo')
    into oos_util_values(cat, name, value) values('mime-type', 'obj','application/x-tgif')
    into oos_util_values(cat, name, value) values('mime-type', 'ustar','application/x-ustar')
    into oos_util_values(cat, name, value) values('mime-type', 'src','application/x-wais-source')
    into oos_util_values(cat, name, value) values('mime-type', 'webapp','application/x-web-app-manifest+json')
    into oos_util_values(cat, name, value) values('mime-type', 'der','application/x-x509-ca-cert')
    into oos_util_values(cat, name, value) values('mime-type', 'crt','application/x-x509-ca-cert')
    into oos_util_values(cat, name, value) values('mime-type', 'pem','application/x-x509-ca-cert')
    into oos_util_values(cat, name, value) values('mime-type', 'fig','application/x-xfig')
    into oos_util_values(cat, name, value) values('mime-type', 'xlf','application/x-xliff+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xpi','application/x-xpinstall')
    into oos_util_values(cat, name, value) values('mime-type', 'xz','application/x-xz')
    into oos_util_values(cat, name, value) values('mime-type', 'z1','application/x-zmachine')
    into oos_util_values(cat, name, value) values('mime-type', 'z2','application/x-zmachine')
    into oos_util_values(cat, name, value) values('mime-type', 'z3','application/x-zmachine')
    into oos_util_values(cat, name, value) values('mime-type', 'z4','application/x-zmachine')
    into oos_util_values(cat, name, value) values('mime-type', 'z5','application/x-zmachine')
    into oos_util_values(cat, name, value) values('mime-type', 'z6','application/x-zmachine')
    into oos_util_values(cat, name, value) values('mime-type', 'z7','application/x-zmachine')
    into oos_util_values(cat, name, value) values('mime-type', 'z8','application/x-zmachine')
    into oos_util_values(cat, name, value) values('mime-type', 'xaml','application/xaml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xdf','application/xcap-diff+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xenc','application/xenc+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xhtml','application/xhtml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xht','application/xhtml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xml','text/xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xsl','application/xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xsd','application/xml')
    into oos_util_values(cat, name, value) values('mime-type', 'dtd','application/xml-dtd')
    into oos_util_values(cat, name, value) values('mime-type', 'xop','application/xop+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xpl','application/xproc+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xslt','application/xslt+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xspf','application/xspf+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'mxml','application/xv+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xhvml','application/xv+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xvml','application/xv+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'xvm','application/xv+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'yang','application/yang')
    into oos_util_values(cat, name, value) values('mime-type', 'yin','application/yin+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'zip','application/zip')
    into oos_util_values(cat, name, value) values('mime-type', 'adp','audio/adpcm')
    into oos_util_values(cat, name, value) values('mime-type', 'au','audio/basic')
    into oos_util_values(cat, name, value) values('mime-type', 'snd','audio/basic')
    into oos_util_values(cat, name, value) values('mime-type', 'mid','audio/midi')
    into oos_util_values(cat, name, value) values('mime-type', 'midi','audio/midi')
    into oos_util_values(cat, name, value) values('mime-type', 'kar','audio/midi')
    into oos_util_values(cat, name, value) values('mime-type', 'rmi','audio/midi')
    into oos_util_values(cat, name, value) values('mime-type', 'mp4a','audio/mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'm4a','audio/mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'mpga','audio/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'mp2','audio/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'mp2a','audio/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'mp3','audio/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'm2a','audio/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'm3a','audio/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'oga','audio/ogg')
    into oos_util_values(cat, name, value) values('mime-type', 'ogg','audio/ogg')
    into oos_util_values(cat, name, value) values('mime-type', 'spx','audio/ogg')
    into oos_util_values(cat, name, value) values('mime-type', 's3m','audio/s3m')
    into oos_util_values(cat, name, value) values('mime-type', 'sil','audio/silk')
    into oos_util_values(cat, name, value) values('mime-type', 'uva','audio/vnd.dece.audio')
    into oos_util_values(cat, name, value) values('mime-type', 'uvva','audio/vnd.dece.audio')
    into oos_util_values(cat, name, value) values('mime-type', 'eol','audio/vnd.digital-winds')
    into oos_util_values(cat, name, value) values('mime-type', 'dra','audio/vnd.dra')
    into oos_util_values(cat, name, value) values('mime-type', 'dts','audio/vnd.dts')
    into oos_util_values(cat, name, value) values('mime-type', 'dtshd','audio/vnd.dts.hd')
    into oos_util_values(cat, name, value) values('mime-type', 'lvp','audio/vnd.lucent.voice')
    into oos_util_values(cat, name, value) values('mime-type', 'pya','audio/vnd.ms-playready.media.pya')
    into oos_util_values(cat, name, value) values('mime-type', 'ecelp4800','audio/vnd.nuera.ecelp4800')
    into oos_util_values(cat, name, value) values('mime-type', 'ecelp7470','audio/vnd.nuera.ecelp7470')
    into oos_util_values(cat, name, value) values('mime-type', 'ecelp9600','audio/vnd.nuera.ecelp9600')
    into oos_util_values(cat, name, value) values('mime-type', 'rip','audio/vnd.rip')
    into oos_util_values(cat, name, value) values('mime-type', 'wav','audio/wav')
    into oos_util_values(cat, name, value) values('mime-type', 'weba','audio/webm')
    into oos_util_values(cat, name, value) values('mime-type', 'aac','audio/x-aac')
    into oos_util_values(cat, name, value) values('mime-type', 'aif','audio/x-aiff')
    into oos_util_values(cat, name, value) values('mime-type', 'aiff','audio/x-aiff')
    into oos_util_values(cat, name, value) values('mime-type', 'aifc','audio/x-aiff')
    into oos_util_values(cat, name, value) values('mime-type', 'caf','audio/x-caf')
    into oos_util_values(cat, name, value) values('mime-type', 'flac','audio/x-flac')
    into oos_util_values(cat, name, value) values('mime-type', 'mka','audio/x-matroska')
    into oos_util_values(cat, name, value) values('mime-type', 'm3u','audio/x-mpegurl')
    into oos_util_values(cat, name, value) values('mime-type', 'wax','audio/x-ms-wax')
    into oos_util_values(cat, name, value) values('mime-type', 'wma','audio/x-ms-wma')
    into oos_util_values(cat, name, value) values('mime-type', 'ram','audio/x-pn-realaudio')
    into oos_util_values(cat, name, value) values('mime-type', 'ra','audio/x-realaudio')
    into oos_util_values(cat, name, value) values('mime-type', 'rmp','audio/x-pn-realaudio-plugin')
    into oos_util_values(cat, name, value) values('mime-type', 'xm','audio/xm')
    into oos_util_values(cat, name, value) values('mime-type', 'cdx','chemical/x-cdx')
    into oos_util_values(cat, name, value) values('mime-type', 'cif','chemical/x-cif')
    into oos_util_values(cat, name, value) values('mime-type', 'cmdf','chemical/x-cmdf')
    into oos_util_values(cat, name, value) values('mime-type', 'cml','chemical/x-cml')
    into oos_util_values(cat, name, value) values('mime-type', 'csml','chemical/x-csml')
    into oos_util_values(cat, name, value) values('mime-type', 'xyz','chemical/x-xyz')
    into oos_util_values(cat, name, value) values('mime-type', 'bmp','image/bmp')
    into oos_util_values(cat, name, value) values('mime-type', 'cgm','image/cgm')
    into oos_util_values(cat, name, value) values('mime-type', 'g3','image/g3fax')
    into oos_util_values(cat, name, value) values('mime-type', 'gif','image/gif')
    into oos_util_values(cat, name, value) values('mime-type', 'ief','image/ief')
    into oos_util_values(cat, name, value) values('mime-type', 'jpeg','image/jpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'jpg','image/jpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'jpe','image/jpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'ktx','image/ktx')
    into oos_util_values(cat, name, value) values('mime-type', 'png','image/png')
    into oos_util_values(cat, name, value) values('mime-type', 'btif','image/prs.btif')
    into oos_util_values(cat, name, value) values('mime-type', 'sgi','image/sgi')
    into oos_util_values(cat, name, value) values('mime-type', 'svg','image/svg+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'svgz','image/svg+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'tiff','image/tiff')
    into oos_util_values(cat, name, value) values('mime-type', 'tif','image/tiff')
    into oos_util_values(cat, name, value) values('mime-type', 'psd','image/vnd.adobe.photoshop')
    into oos_util_values(cat, name, value) values('mime-type', 'uvi','image/vnd.dece.graphic')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvi','image/vnd.dece.graphic')
    into oos_util_values(cat, name, value) values('mime-type', 'uvg','image/vnd.dece.graphic')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvg','image/vnd.dece.graphic')
    into oos_util_values(cat, name, value) values('mime-type', 'djvu','image/vnd.djvu')
    into oos_util_values(cat, name, value) values('mime-type', 'djv','image/vnd.djvu')
    into oos_util_values(cat, name, value) values('mime-type', 'sub','text/vnd.dvb.subtitle')
    into oos_util_values(cat, name, value) values('mime-type', 'dwg','image/vnd.dwg')
    into oos_util_values(cat, name, value) values('mime-type', 'dxf','image/vnd.dxf')
    into oos_util_values(cat, name, value) values('mime-type', 'fbs','image/vnd.fastbidsheet')
    into oos_util_values(cat, name, value) values('mime-type', 'fpx','image/vnd.fpx')
    into oos_util_values(cat, name, value) values('mime-type', 'fst','image/vnd.fst')
    into oos_util_values(cat, name, value) values('mime-type', 'mmr','image/vnd.fujixerox.edmics-mmr')
    into oos_util_values(cat, name, value) values('mime-type', 'rlc','image/vnd.fujixerox.edmics-rlc')
    into oos_util_values(cat, name, value) values('mime-type', 'mdi','image/vnd.ms-modi')
    into oos_util_values(cat, name, value) values('mime-type', 'wdp','image/vnd.ms-photo')
    into oos_util_values(cat, name, value) values('mime-type', 'npx','image/vnd.net-fpx')
    into oos_util_values(cat, name, value) values('mime-type', 'wbmp','image/vnd.wap.wbmp')
    into oos_util_values(cat, name, value) values('mime-type', 'xif','image/vnd.xiff')
    into oos_util_values(cat, name, value) values('mime-type', 'webp','image/webp')
    into oos_util_values(cat, name, value) values('mime-type', '3ds','image/x-3ds')
    into oos_util_values(cat, name, value) values('mime-type', 'ras','image/x-cmu-raster')
    into oos_util_values(cat, name, value) values('mime-type', 'cmx','image/x-cmx')
    into oos_util_values(cat, name, value) values('mime-type', 'fh','image/x-freehand')
    into oos_util_values(cat, name, value) values('mime-type', 'fhc','image/x-freehand')
    into oos_util_values(cat, name, value) values('mime-type', 'fh4','image/x-freehand')
    into oos_util_values(cat, name, value) values('mime-type', 'fh5','image/x-freehand')
    into oos_util_values(cat, name, value) values('mime-type', 'fh7','image/x-freehand')
    into oos_util_values(cat, name, value) values('mime-type', 'ico','image/x-icon')
    into oos_util_values(cat, name, value) values('mime-type', 'jng','image/x-jng')
    into oos_util_values(cat, name, value) values('mime-type', 'sid','image/x-mrsid-image')
    into oos_util_values(cat, name, value) values('mime-type', 'pcx','image/x-pcx')
    into oos_util_values(cat, name, value) values('mime-type', 'pic','image/x-pict')
    into oos_util_values(cat, name, value) values('mime-type', 'pct','image/x-pict')
    into oos_util_values(cat, name, value) values('mime-type', 'pnm','image/x-portable-anymap')
    into oos_util_values(cat, name, value) values('mime-type', 'pbm','image/x-portable-bitmap')
    into oos_util_values(cat, name, value) values('mime-type', 'pgm','image/x-portable-graymap')
    into oos_util_values(cat, name, value) values('mime-type', 'ppm','image/x-portable-pixmap')
    into oos_util_values(cat, name, value) values('mime-type', 'rgb','image/x-rgb')
    into oos_util_values(cat, name, value) values('mime-type', 'tga','image/x-tga')
    into oos_util_values(cat, name, value) values('mime-type', 'xbm','image/x-xbitmap')
    into oos_util_values(cat, name, value) values('mime-type', 'xpm','image/x-xpixmap')
    into oos_util_values(cat, name, value) values('mime-type', 'xwd','image/x-xwindowdump')
    into oos_util_values(cat, name, value) values('mime-type', 'eml','message/rfc822')
    into oos_util_values(cat, name, value) values('mime-type', 'mime','message/rfc822')
    into oos_util_values(cat, name, value) values('mime-type', 'igs','model/iges')
    into oos_util_values(cat, name, value) values('mime-type', 'iges','model/iges')
    into oos_util_values(cat, name, value) values('mime-type', 'msh','model/mesh')
    into oos_util_values(cat, name, value) values('mime-type', 'mesh','model/mesh')
    into oos_util_values(cat, name, value) values('mime-type', 'silo','model/mesh')
    into oos_util_values(cat, name, value) values('mime-type', 'dae','model/vnd.collada+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'dwf','model/vnd.dwf')
    into oos_util_values(cat, name, value) values('mime-type', 'gdl','model/vnd.gdl')
    into oos_util_values(cat, name, value) values('mime-type', 'gtw','model/vnd.gtw')
    into oos_util_values(cat, name, value) values('mime-type', 'mts','model/vnd.mts')
    into oos_util_values(cat, name, value) values('mime-type', 'vtu','model/vnd.vtu')
    into oos_util_values(cat, name, value) values('mime-type', 'wrl','model/vrml')
    into oos_util_values(cat, name, value) values('mime-type', 'vrml','model/vrml')
    into oos_util_values(cat, name, value) values('mime-type', 'x3db','model/x3d+binary')
    into oos_util_values(cat, name, value) values('mime-type', 'x3dbz','model/x3d+binary')
    into oos_util_values(cat, name, value) values('mime-type', 'x3dv','model/x3d+vrml')
    into oos_util_values(cat, name, value) values('mime-type', 'x3dvz','model/x3d+vrml')
    into oos_util_values(cat, name, value) values('mime-type', 'x3d','model/x3d+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'x3dz','model/x3d+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'appcache','text/cache-manifest')
    into oos_util_values(cat, name, value) values('mime-type', 'manifest','text/cache-manifest')
    into oos_util_values(cat, name, value) values('mime-type', 'ics','text/calendar')
    into oos_util_values(cat, name, value) values('mime-type', 'ifb','text/calendar')
    into oos_util_values(cat, name, value) values('mime-type', 'coffee','text/coffeescript')
    into oos_util_values(cat, name, value) values('mime-type', 'litcoffee','text/coffeescript')
    into oos_util_values(cat, name, value) values('mime-type', 'css','text/css')
    into oos_util_values(cat, name, value) values('mime-type', 'csv','text/csv')
    into oos_util_values(cat, name, value) values('mime-type', 'hjson','text/hjson')
    into oos_util_values(cat, name, value) values('mime-type', 'html','text/html')
    into oos_util_values(cat, name, value) values('mime-type', 'htm','text/html')
    into oos_util_values(cat, name, value) values('mime-type', 'shtml','text/html')
    into oos_util_values(cat, name, value) values('mime-type', 'jade','text/jade')
    into oos_util_values(cat, name, value) values('mime-type', 'jsx','text/jsx')
    into oos_util_values(cat, name, value) values('mime-type', 'less','text/less')
    into oos_util_values(cat, name, value) values('mime-type', 'mml','text/mathml')
    into oos_util_values(cat, name, value) values('mime-type', 'n3','text/n3')
    into oos_util_values(cat, name, value) values('mime-type', 'txt','text/plain')
    into oos_util_values(cat, name, value) values('mime-type', 'text','text/plain')
    into oos_util_values(cat, name, value) values('mime-type', 'conf','text/plain')
    into oos_util_values(cat, name, value) values('mime-type', 'def','text/plain')
    into oos_util_values(cat, name, value) values('mime-type', 'list','text/plain')
    into oos_util_values(cat, name, value) values('mime-type', 'log','text/plain')
    into oos_util_values(cat, name, value) values('mime-type', 'in','text/plain')
    into oos_util_values(cat, name, value) values('mime-type', 'ini','text/plain')
    into oos_util_values(cat, name, value) values('mime-type', 'dsc','text/prs.lines.tag')
    into oos_util_values(cat, name, value) values('mime-type', 'rtx','text/richtext')
    into oos_util_values(cat, name, value) values('mime-type', 'sgml','text/sgml')
    into oos_util_values(cat, name, value) values('mime-type', 'sgm','text/sgml')
    into oos_util_values(cat, name, value) values('mime-type', 'stylus','text/stylus')
    into oos_util_values(cat, name, value) values('mime-type', 'styl','text/stylus')
    into oos_util_values(cat, name, value) values('mime-type', 'tsv','text/tab-separated-values')
    into oos_util_values(cat, name, value) values('mime-type', 't','text/troff')
    into oos_util_values(cat, name, value) values('mime-type', 'tr','text/troff')
    into oos_util_values(cat, name, value) values('mime-type', 'roff','text/troff')
    into oos_util_values(cat, name, value) values('mime-type', 'man','text/troff')
    into oos_util_values(cat, name, value) values('mime-type', 'me','text/troff')
    into oos_util_values(cat, name, value) values('mime-type', 'ms','text/troff')
    into oos_util_values(cat, name, value) values('mime-type', 'ttl','text/turtle')
    into oos_util_values(cat, name, value) values('mime-type', 'uri','text/uri-list')
    into oos_util_values(cat, name, value) values('mime-type', 'uris','text/uri-list')
    into oos_util_values(cat, name, value) values('mime-type', 'urls','text/uri-list')
    into oos_util_values(cat, name, value) values('mime-type', 'vcard','text/vcard')
    into oos_util_values(cat, name, value) values('mime-type', 'curl','text/vnd.curl')
    into oos_util_values(cat, name, value) values('mime-type', 'dcurl','text/vnd.curl.dcurl')
    into oos_util_values(cat, name, value) values('mime-type', 'mcurl','text/vnd.curl.mcurl')
    into oos_util_values(cat, name, value) values('mime-type', 'scurl','text/vnd.curl.scurl')
    into oos_util_values(cat, name, value) values('mime-type', 'fly','text/vnd.fly')
    into oos_util_values(cat, name, value) values('mime-type', 'flx','text/vnd.fmi.flexstor')
    into oos_util_values(cat, name, value) values('mime-type', 'gv','text/vnd.graphviz')
    into oos_util_values(cat, name, value) values('mime-type', '3dml','text/vnd.in3d.3dml')
    into oos_util_values(cat, name, value) values('mime-type', 'spot','text/vnd.in3d.spot')
    into oos_util_values(cat, name, value) values('mime-type', 'jad','text/vnd.sun.j2me.app-descriptor')
    into oos_util_values(cat, name, value) values('mime-type', 'wml','text/vnd.wap.wml')
    into oos_util_values(cat, name, value) values('mime-type', 'wmls','text/vnd.wap.wmlscript')
    into oos_util_values(cat, name, value) values('mime-type', 'vtt','text/vtt')
    into oos_util_values(cat, name, value) values('mime-type', 's','text/x-asm')
    into oos_util_values(cat, name, value) values('mime-type', 'asm','text/x-asm')
    into oos_util_values(cat, name, value) values('mime-type', 'c','text/x-c')
    into oos_util_values(cat, name, value) values('mime-type', 'cc','text/x-c')
    into oos_util_values(cat, name, value) values('mime-type', 'cxx','text/x-c')
    into oos_util_values(cat, name, value) values('mime-type', 'cpp','text/x-c')
    into oos_util_values(cat, name, value) values('mime-type', 'h','text/x-c')
    into oos_util_values(cat, name, value) values('mime-type', 'hh','text/x-c')
    into oos_util_values(cat, name, value) values('mime-type', 'dic','text/x-c')
    into oos_util_values(cat, name, value) values('mime-type', 'htc','text/x-component')
    into oos_util_values(cat, name, value) values('mime-type', 'f','text/x-fortran')
    into oos_util_values(cat, name, value) values('mime-type', 'for','text/x-fortran')
    into oos_util_values(cat, name, value) values('mime-type', 'f77','text/x-fortran')
    into oos_util_values(cat, name, value) values('mime-type', 'f90','text/x-fortran')
    into oos_util_values(cat, name, value) values('mime-type', 'hbs','text/x-handlebars-template')
    into oos_util_values(cat, name, value) values('mime-type', 'java','text/x-java-source')
    into oos_util_values(cat, name, value) values('mime-type', 'lua','text/x-lua')
    into oos_util_values(cat, name, value) values('mime-type', 'markdown','text/x-markdown')
    into oos_util_values(cat, name, value) values('mime-type', 'md','text/x-markdown')
    into oos_util_values(cat, name, value) values('mime-type', 'mkd','text/x-markdown')
    into oos_util_values(cat, name, value) values('mime-type', 'nfo','text/x-nfo')
    into oos_util_values(cat, name, value) values('mime-type', 'opml','text/x-opml')
    into oos_util_values(cat, name, value) values('mime-type', 'p','text/x-pascal')
    into oos_util_values(cat, name, value) values('mime-type', 'pas','text/x-pascal')
    into oos_util_values(cat, name, value) values('mime-type', 'pde','text/x-processing')
    into oos_util_values(cat, name, value) values('mime-type', 'sass','text/x-sass')
    into oos_util_values(cat, name, value) values('mime-type', 'scss','text/x-scss')
    into oos_util_values(cat, name, value) values('mime-type', 'etx','text/x-setext')
    into oos_util_values(cat, name, value) values('mime-type', 'sfv','text/x-sfv')
    into oos_util_values(cat, name, value) values('mime-type', 'ymp','text/x-suse-ymp')
    into oos_util_values(cat, name, value) values('mime-type', 'uu','text/x-uuencode')
    into oos_util_values(cat, name, value) values('mime-type', 'vcs','text/x-vcalendar')
    into oos_util_values(cat, name, value) values('mime-type', 'vcf','text/x-vcard')
    into oos_util_values(cat, name, value) values('mime-type', 'yaml','text/yaml')
    into oos_util_values(cat, name, value) values('mime-type', 'yml','text/yaml')
    into oos_util_values(cat, name, value) values('mime-type', '3gp','video/3gpp')
    into oos_util_values(cat, name, value) values('mime-type', '3gpp','video/3gpp')
    into oos_util_values(cat, name, value) values('mime-type', '3g2','video/3gpp2')
    into oos_util_values(cat, name, value) values('mime-type', 'h261','video/h261')
    into oos_util_values(cat, name, value) values('mime-type', 'h263','video/h263')
    into oos_util_values(cat, name, value) values('mime-type', 'h264','video/h264')
    into oos_util_values(cat, name, value) values('mime-type', 'jpgv','video/jpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'jpm','video/jpm')
    into oos_util_values(cat, name, value) values('mime-type', 'jpgm','video/jpm')
    into oos_util_values(cat, name, value) values('mime-type', 'mj2','video/mj2')
    into oos_util_values(cat, name, value) values('mime-type', 'mjp2','video/mj2')
    into oos_util_values(cat, name, value) values('mime-type', 'ts','video/mp2t')
    into oos_util_values(cat, name, value) values('mime-type', 'mp4','video/mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'mp4v','video/mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'mpg4','video/mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'mpeg','video/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'mpg','video/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'mpe','video/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'm1v','video/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'm2v','video/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'ogv','video/ogg')
    into oos_util_values(cat, name, value) values('mime-type', 'qt','video/quicktime')
    into oos_util_values(cat, name, value) values('mime-type', 'mov','video/quicktime')
    into oos_util_values(cat, name, value) values('mime-type', 'uvh','video/vnd.dece.hd')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvh','video/vnd.dece.hd')
    into oos_util_values(cat, name, value) values('mime-type', 'uvm','video/vnd.dece.mobile')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvm','video/vnd.dece.mobile')
    into oos_util_values(cat, name, value) values('mime-type', 'uvp','video/vnd.dece.pd')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvp','video/vnd.dece.pd')
    into oos_util_values(cat, name, value) values('mime-type', 'uvs','video/vnd.dece.sd')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvs','video/vnd.dece.sd')
    into oos_util_values(cat, name, value) values('mime-type', 'uvv','video/vnd.dece.video')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvv','video/vnd.dece.video')
    into oos_util_values(cat, name, value) values('mime-type', 'dvb','video/vnd.dvb.file')
    into oos_util_values(cat, name, value) values('mime-type', 'fvt','video/vnd.fvt')
    into oos_util_values(cat, name, value) values('mime-type', 'mxu','video/vnd.mpegurl')
    into oos_util_values(cat, name, value) values('mime-type', 'm4u','video/vnd.mpegurl')
    into oos_util_values(cat, name, value) values('mime-type', 'pyv','video/vnd.ms-playready.media.pyv')
    into oos_util_values(cat, name, value) values('mime-type', 'uvu','video/vnd.uvvu.mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'uvvu','video/vnd.uvvu.mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'viv','video/vnd.vivo')
    into oos_util_values(cat, name, value) values('mime-type', 'webm','video/webm')
    into oos_util_values(cat, name, value) values('mime-type', 'f4v','video/x-f4v')
    into oos_util_values(cat, name, value) values('mime-type', 'fli','video/x-fli')
    into oos_util_values(cat, name, value) values('mime-type', 'flv','video/x-flv')
    into oos_util_values(cat, name, value) values('mime-type', 'm4v','video/x-m4v')
    into oos_util_values(cat, name, value) values('mime-type', 'mkv','video/x-matroska')
    into oos_util_values(cat, name, value) values('mime-type', 'mk3d','video/x-matroska')
    into oos_util_values(cat, name, value) values('mime-type', 'mks','video/x-matroska')
    into oos_util_values(cat, name, value) values('mime-type', 'mng','video/x-mng')
    into oos_util_values(cat, name, value) values('mime-type', 'asf','video/x-ms-asf')
    into oos_util_values(cat, name, value) values('mime-type', 'asx','video/x-ms-asf')
    into oos_util_values(cat, name, value) values('mime-type', 'vob','video/x-ms-vob')
    into oos_util_values(cat, name, value) values('mime-type', 'wm','video/x-ms-wm')
    into oos_util_values(cat, name, value) values('mime-type', 'wmv','video/x-ms-wmv')
    into oos_util_values(cat, name, value) values('mime-type', 'wmx','video/x-ms-wmx')
    into oos_util_values(cat, name, value) values('mime-type', 'wvx','video/x-ms-wvx')
    into oos_util_values(cat, name, value) values('mime-type', 'avi','video/x-msvideo')
    into oos_util_values(cat, name, value) values('mime-type', 'movie','video/x-sgi-movie')
    into oos_util_values(cat, name, value) values('mime-type', 'smv','video/x-smv')
    into oos_util_values(cat, name, value) values('mime-type', 'ice','x-conference/x-cooltalk')
  select 1 from dual;
end;
/
commit;

