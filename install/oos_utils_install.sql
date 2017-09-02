
-- DO NOT MODIFY THIS FILE. IT IS AUTO GENERATED
set define off

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

  -- TYPES
  /**
   * @type tab_num `number` nested table
   * @type tab_num_arr `number` associated array
   * @type tab_vc2 `varchar2` nested table
   * @type tab_vc2_arr `varchar2` associated array
   */
  type tab_num is table of number;
  type tab_num_arr is table of number index by pls_integer;
  type tab_vc2 is table of varchar2(32767);
  type tab_vc2_arr is table of varchar2(32767) index by pls_integer;



  -- CONSTANTS
  /**
   * @constant gc_date_format default date format
   * @constant gc_timestamp_format default timestamp format
   * @constant gc_timestamp_tz_format default timestamp (with TZ) format
   * @constant gc_version String represenation of MAJOR.MINOR.PATCH: Note documented version is just an example.
   * @constant gc_version_major Version number major 1.0.0
   * @constant gc_version_minor Verison number minor 0.1.0
   * @constant gc_version_patch Version number patch 0.0.1
   */
  gc_date_format constant varchar2(255) := 'YYYY-MM-DD HH24:MI:SS';
  gc_timestamp_format constant varchar2(255) := gc_date_format || ':FF';
  gc_timestamp_tz_format constant varchar2(255) := gc_timestamp_format || ' TZR';

  -- Version numbers. Useful for anyone writing condtional compilation for OOS Utils
  gc_version_major constant pls_integer := 1;
  gc_version_minor constant pls_integer := 0;
  gc_version_patch constant pls_integer := 1;
  gc_version constant varchar2(30) := gc_version_major || '.' || gc_version_minor || '.' || gc_version_patch;


  -- OOS Util Val Cats
  gc_vals_cat_mime_type constant oos_util_values.cat%type := 'mime-type';

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

  /*!
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
   * @example
   * begin
   *   dbms_output.put_line(oos_util_string.to_char(sysdate));
   *   oos_util.sleep(5);
   *   dbms_output.put_line(oos_util_string.to_char(sysdate));
   * end;
   * /
   *
   * 26-APR-2016 14:29:02
   * 26-APR-2016 14:29:07
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
   * Can be used in APEX to declaratively determine if in development mode.
   *
   * @example
   * begin
   *   if oos_util_apex.is_developer then
   *     dbms_output.put_line('Developer mode');
   *   else
   *     dbms_output.put_line('Non-Dev mode');
   *   end if;
   * end;
   *
   * @issue 25
   *
   * @author Martin Giffy D'Souza
   * @created 29-Dec-2015
   * @return boolan True: Developer has an active session in Application Builder
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
   * @example
   * begin
   *   if oos_util_apex.is_developer_yn = 'Y' then
   *     dbms_output.put_line('Developer mode');
   *   else
   *     dbms_output.put_line('Non-Dev mode');
   *   end if;
   * end;
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
   * @example
   *
   * begin
   *   if oos_util_apex.is_session_valid(p_session_id => :app_session) then
   *     dbms_output.put_line('Session is active');
   *   else
   *     dbms_output.put_line('Session is inactive');
   *   end if;
   * end;
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
   * @example
   *
   * begin
   *   if oos_util_apex.is_session_valid_yn(p_session_id => :app_session) = 'Y' then
   *     dbms_output.put_line('Session is active');
   *   else
   *     dbms_output.put_line('Session is inactive');
   *   end if;
   * end;
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
   *  - Known Issues:
   *    - [#118](https://github.com/OraOpenSource/oos-utils/issues/118)
   *    - [#132](https://github.com/OraOpenSource/oos-utils/issues/132)
   *    - [#49](https://github.com/OraOpenSource/oos-utils/issues/49)
   *
   * @example
   *
   * begin
   *   oos_util_apex.create_session(
   *     p_app_id => :app_id,
   *     p_user_name => :app_user,
   *     p_page_id => :app_page_id
   *   );
   * end;
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
   * Join an existing APEX session.
   * Note they're some known issues with this procedure right now:
   * - [#88](https://github.com/OraOpenSource/oos-utils/issues/88)
   *
   * Notes:
   *  - `v('P1_X')` won't work. Use `apex_util.get_session_state('P1_X')` instead
   *
   *
   * @example
   *
   * begin
   *   oos_util_apex.join_session(
   *     p_session_id => :app_session,
   *     p_app_id => :app_id
   *   );
   * end;
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
   * @example
   *
   * begin
   *   oos_util_apex.trim_page_items(p_page_id => :app_page_id);
   * end;
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
   * @example
   * begin
   *   if oos_util_apex.is_page_item_rendered(p_item_name => 'P1_EMPNO') then
   *     dbms_output.put_line('P1_EMPNO rendered');
   *   else
   *     dbms_output.put_line('P1_EMPNO was not rendered');
   *   end if;
   * end;
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
    return binary_integer
    deterministic;

  function bitor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
    deterministic;

  function bitxor(
    p_x in binary_integer,
    p_y in binary_integer)
    return binary_integer
    deterministic;

  function bitnot(
    p_x in binary_integer)
    return binary_integer
    deterministic;

  function bitshift_left(
    p_x binary_integer,
    p_y binary_integer)
    return binary_integer
    deterministic;

  function bitshift_right(
    p_x binary_integer,
    p_y binary_integer)
    return binary_integer
    deterministic;

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
    deterministic
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
    deterministic
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
    deterministic
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
    deterministic
  as
  begin
    return (0 - p_x) - 1;
  end bitnot;


  /**
   * From [https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Operators/Bitwise_Operators#Left_shift](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Operators/Bitwise_Operators#Left_shift): _This operator shifts the first operand the specified number of bits to the left. Excess bits shifted off to the left are discarded. Zero bits are shifted in from the right_.
   *
   * @example
   *
   * select oos_util_bit.bitshift_left(7, 4)
   * from dual;
   *
   * OOS_UTIL_BIT.BITSHIFT_LEFT(7,4)
   * 112
   *
   * -- In binary terms this converted 111 (7) to 1110000 (112)
   *
   * @issue #112
   *
   * @author Anton Scheffer
   * @created 22-Sep-2016
   * @param p_x binary_integer
   * @param p_y binary_integer
   * @return binary_integer
   */
  function bitshift_left(
    p_x binary_integer,
    p_y binary_integer)
    return binary_integer
    deterministic
  is
  begin
    return p_x * power(2, p_y);
  end bitshift_left;

  /**
   * From [https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Operators/Bitwise_Operators#Right_shift](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Operators/Bitwise_Operators#Right_shift): _This operator shifts the first operand the specified number of bits to the right. Excess bits shifted off to the right are discarded. Copies of the leftmost bit are shifted in from the left. Since the new leftmost bit has the same value as the previous leftmost bit, the sign bit (the leftmost bit) does not change. Hence the name "sign-propagating"._
   *
   * @example
   *
   * select oos_util_bit.bitshift_right(7, 1)
   * from dual;
   *
   * OOS_UTIL_BIT.BITSHIFT_RIGHT(7,1)
   * 3
   *
   * -- In binary terms this converted 111 (7) to 011 (3)
   *
   * @issue #112
   *
   * @author Anton Scheffer
   * @created 22-Sep-2016
   * @param p_x binary_integer
   * @param p_y binary_integer
   * @return binary_integer
   */
  function bitshift_right(
    p_x binary_integer,
    p_y binary_integer)
    return binary_integer
    deterministic
  is
  begin
    return trunc(p_x / power(2, p_y));
  end bitshift_right;

end;
/

prompt oos_util_crypto
create or replace package oos_util_crypto
as
  -- CONSTANTS
  /**
   * @constant gc_hash_md4
   * @constant gc_hash_md5
   * @constant gc_hash_sh1
   * @constant gc_hash_sh224
   * @constant gc_hash_sh256
   * @constant gc_hash_sh384
   * @constant gc_hash_sh512
   * @constant gc_hash_ripemd160
   * @constant gc_hmac_md4
   * @constant gc_hmac_md5
   * @constant gc_hmac_sh1
   * @constant gc_hmac_sh224
   * @constant gc_hmac_sh256
   * @constant gc_hmac_sh384
   * @constant gc_hmac_sh512
   * @constant gc_hmac_ripemd160
   */
   -- Hash Functions
   gc_hash_md4 constant pls_integer := 1;
   gc_hash_md5 constant pls_integer := 2;
   gc_hash_sh1 constant pls_integer := 3;
   gc_hash_sh224 constant pls_integer := 11;
   gc_hash_sh256 constant pls_integer := 4;
   gc_hash_sh384 constant pls_integer := 5;
   gc_hash_sh512 constant pls_integer := 6;
   gc_hash_ripemd160 constant pls_integer := 15;
   -- MAC Functions
   gc_hmac_md4 constant pls_integer := 0;
   gc_hmac_md5 constant pls_integer := 1;
   gc_hmac_sh1 constant pls_integer := 2;
   gc_hmac_sh224 constant pls_integer := 10;
   gc_hmac_sh256 constant pls_integer := 3;
   gc_hmac_sh384 constant pls_integer := 4;
   gc_hmac_sh512 constant pls_integer := 5;
   gc_hmac_ripemd160 constant pls_integer := 14;
   -- Block Cipher Algorithms
   gc_encrypt_des constant pls_integer := 1;  -- 0x0001
   gc_encrypt_3des_2key constant pls_integer := 2;  -- 0x0002
   gc_encrypt_3des constant pls_integer := 3;  -- 0x0003
   gc_encrypt_aes constant pls_integer := 4;  -- 0x0004
   gc_encrypt_pbe_md5des constant pls_integer := 5;  -- 0x0005
   gc_encrypt_aes128 constant pls_integer := 6;  -- 0x0006
   gc_encrypt_aes192 constant pls_integer := 7;  -- 0x0007
   gc_encrypt_aes256 constant pls_integer := 8;  -- 0x0008
   -- Block Cipher Chaining Modifiers
   gc_chain_cbc constant pls_integer := 256;  -- 0x0100
   gc_chain_cfb constant pls_integer := 512;  -- 0x0200
   gc_chain_ecb constant pls_integer := 768;  -- 0x0300
   gc_chain_ofb constant pls_integer := 1024;  -- 0x0400
   gc_chain_ofb_real constant pls_integer := 1280;  -- 0x0500
   -- Block Cipher Padding Modifiers
   gc_pad_pkcs5 constant pls_integer := 4096;  -- 0x1000
   gc_pad_none constant pls_integer := 8192;  -- 0x2000
   gc_pad_zero constant pls_integer := 12288;  -- 0x3000
   gc_pad_orcl constant pls_integer := 16384;  -- 0x4000
   gc_pad_oneandzeroes constant pls_integer := 20480;  -- 0x5000
   gc_pad_ansi_x923 constant pls_integer := 24576;  -- 0x6000
   -- Stream Cipher Algorithms
   gc_encrypt_rc4 constant pls_integer := 129;  -- 0x0081

   function hash(
     p_src raw,
     p_typ pls_integer)
     return raw;

   function hash_str(
     p_src varchar2,
     p_typ pls_integer)
     return varchar2;

   function mac(
    p_src raw,
    p_typ pls_integer,
    p_key raw)
    return raw;

   function mac_str(
    p_src varchar2,
    p_typ pls_integer,
    p_key varchar2)
    return varchar2;

  -- Enable these in future versions #154
  --  function randombytes( number_bytes positive )
  --  return raw;
   --
  --  function encrypt( src raw, typ pls_integer, key raw, iv raw := null )
  --  return raw;
   --
  --  function decrypt( src raw, typ pls_integer, key raw, iv raw := null )
  --  return raw;


end oos_util_crypto;

/

create or replace package body oos_util_crypto
as

  -- To test: https://www.freeformatter.com/hmac-generator.html#ad-output
  --
    bmax32 constant number := power( 2, 32 ) - 1;
    bmax64 constant number := power( 2, 64 ) - 1;
    type tp_crypto is table of number;
    type tp_aes_tab is table of number index by pls_integer;
  --
    SP1 tp_crypto;
    SP2 tp_crypto;
    SP3 tp_crypto;
    SP4 tp_crypto;
    SP5 tp_crypto;
    SP6 tp_crypto;
    SP7 tp_crypto;
    SP8 tp_crypto;
  --
    function bitor( x number, y number )
    return number
    is
    begin
      return x + y - bitand( x, y );
    end;
  --
    function bitxor( x number, y number )
    return number
    is
    begin
      return x + y - 2 * bitand( x, y );
    end;
  --
    function shl( x number, b pls_integer )
    return number
    is
    begin
      return x * power( 2, b );
    end;
  --
    function shr( x number, b pls_integer )
    return number
    is
    begin
      return trunc( x / power( 2, b ) );
    end;
  --
    function bitor32( x integer, y integer )
    return integer
    is
    begin
      return bitand( x + y - bitand( x, y  ), bmax32 );
    end;
  --
    function bitxor32( x integer, y  integer  )
    return integer
    is
    begin
      return bitand( x + y - 2 * bitand( x, y ), bmax32 );
    end;
  --
    function ror32( x number, b pls_integer )
    return number
    is
      t number;
    begin
      t := bitand( x, bmax32 );
      return bitand( bitor( shr( t, b ), shl( t, 32 - b ) ), bmax32 );
    end;
  --
    function rol32( x number, b pls_integer )
    return number
    is
      t number;
    begin
      t := bitand( x, bmax32 );
      return bitand( bitor( shl( t, b ), shr( t, 32 - b ) ), bmax32 );
    end;
  --
    function ror64( x number, b pls_integer )
    return number
    is
      t number;
    begin
      t := bitand( x, bmax64 );
      return bitand( bitor( shr( t, b ), shl( t, 64 - b ) ), bmax64 );
    end;
  --
    function rol64( x number, b pls_integer )
    return number
    is
      t number;
    begin
      t := bitand( x, bmax64 );
      return bitand( bitor( shl( t, b ), shr( t, 64 - b ) ), bmax64 );
    end;
  --
    function ripemd160( p_msg raw )
    return raw
    is
      t_md varchar2(128);
      fmt2 varchar2(10) := 'fm0XXXXXXX';
      t_len pls_integer;
      t_pad_len pls_integer;
      t_pad varchar2(144);
      t_msg_buf varchar2(32766);
      t_idx pls_integer;
      t_chunksize pls_integer := 16320; -- 255 * 64
      t_block varchar2(128);
  --
      st tp_crypto;
      sl tp_crypto;
      sr tp_crypto;
  --
      procedure ff( a in out number, b number, c in out number, d number, e number, xi pls_integer, r pls_integer )
      is
        x number := utl_raw.cast_to_binary_integer( substr( t_block, xi * 8 + 1, 8 ), utl_raw.little_endian );
      begin
        a := bitand( rol32( a + bitxor( bitxor( b, c ), d ) + x, r ) + e, bmax32 );
        c := rol32( c, 10 );
      end;
  --
      procedure ll( a in out number, b number, c in out number, d number, e number, xi pls_integer, r pls_integer, h number )
      is
        x number := utl_raw.cast_to_binary_integer( substr( t_block, xi * 8 + 1, 8 ), utl_raw.little_endian );
      begin
        a := bitand( rol32( a + bitxor( b, bitor( c, - d - 1 ) ) + x + h, r ) + e, bmax32 );
        c := rol32( c, 10 );
      end;
  --
      procedure gg( a in out number, b number, c in out number, d number, e number, xi pls_integer, r pls_integer, h number )
      is
        x number := utl_raw.cast_to_binary_integer( substr( t_block, xi * 8 + 1, 8 ), utl_raw.little_endian );
      begin
        a := bitand( rol32( a + bitor( bitand( b, c ), bitand( - b - 1, d ) ) + x + h, r ) + e, bmax32 );
        c := rol32( c, 10 );
      end;
  --
      procedure kk( a in out number, b number, c in out number, d number, e number, xi pls_integer, r pls_integer, h number )
      is
        x number := utl_raw.cast_to_binary_integer( substr( t_block, xi * 8 + 1, 8 ), utl_raw.little_endian );
      begin
        a := bitand( rol32( a + bitor( bitand( b, d ), bitand( c, - d - 1 ) ) + x + h, r ) + e, bmax32 );
        c := rol32( c, 10 );
      end;
  --
      procedure hh( a in out number, b number, c in out number, d number, e number, xi pls_integer, r pls_integer, h number )
      is
        x number := utl_raw.cast_to_binary_integer( substr( t_block, xi * 8 + 1, 8 ), utl_raw.little_endian );
      begin
        a := bitand( rol32( a + bitxor( bitor( b, - c - 1 ), d ) + x + h, r ) + e, bmax32 );
        c := rol32( c, 10 );
      end;
  --
      procedure fa( ar in out tp_crypto, s pls_integer, xis tp_crypto, r_cnt tp_crypto )
      is
      begin
        for i in 1 .. 16
        loop
          ff( ar(mod(15-i+s,5)+1),ar(mod(16-i+s,5)+1),ar(mod(17-i+s,5)+1),ar(mod(18-i+s,5)+1),ar(mod(19-i+s,5)+1),xis(i),r_cnt(i) );
        end loop;
      end;
      procedure ga( ar in out tp_crypto, s pls_integer, h number, xis tp_crypto, r_cnt tp_crypto )
      is
      begin
        for i in 1 .. 16
        loop
          gg( ar(mod(15-i+s,5)+1),ar(mod(16-i+s,5)+1),ar(mod(17-i+s,5)+1),ar(mod(18-i+s,5)+1),ar(mod(19-i+s,5)+1),xis(i),r_cnt(i), h );
        end loop;
      end;
      procedure ha( ar in out tp_crypto, s pls_integer, h number, xis tp_crypto, r_cnt tp_crypto )
      is
      begin
        for i in 1 .. 16
        loop
          hh( ar(mod(15-i+s,5)+1),ar(mod(16-i+s,5)+1),ar(mod(17-i+s,5)+1),ar(mod(18-i+s,5)+1),ar(mod(19-i+s,5)+1),xis(i),r_cnt(i), h );
        end loop;
      end;
      procedure ka( ar in out tp_crypto, s pls_integer, h number, xis tp_crypto, r_cnt tp_crypto )
      is
      begin
        for i in 1 .. 16
        loop
          kk( ar(mod(15-i+s,5)+1),ar(mod(16-i+s,5)+1),ar(mod(17-i+s,5)+1),ar(mod(18-i+s,5)+1),ar(mod(19-i+s,5)+1),xis(i),r_cnt(i), h );
        end loop;
      end;
      procedure la( ar in out tp_crypto, s pls_integer, h number, xis tp_crypto, r_cnt tp_crypto )
      is
      begin
        for i in 1 .. 16
        loop
          ll( ar(mod(15-i+s,5)+1),ar(mod(16-i+s,5)+1),ar(mod(17-i+s,5)+1),ar(mod(18-i+s,5)+1),ar(mod(19-i+s,5)+1),xis(i),r_cnt(i), h );
        end loop;
      end;
    begin
      t_len := nvl( utl_raw.length( p_msg ), 0 );
      t_pad_len := 64 - mod( t_len, 64 );
      if t_pad_len < 9
      then
        t_pad_len := 64 + t_pad_len;
      end if;
      t_pad := rpad( '8', t_pad_len * 2 - 16, '0' )
         || utl_raw.cast_from_binary_integer( t_len * 8, utl_raw.little_endian )
         || '00000000';
  --
      st := tp_crypto( 1732584193 -- 67452301
                     , 4023233417 -- efcdab89
                     , 2562383102 -- 98badcfe
                     ,  271733878 -- 10325476
                     , 3285377520 -- c3d2e1f0
                     );
  --
      sl := tp_crypto( 0, 0, 0, 0, 0 );
      sr := tp_crypto( 0, 0, 0, 0, 0 );
  --
      t_idx := 1;
      while t_idx <= t_len + t_pad_len
      loop
        if t_len - t_idx + 1 >= t_chunksize
        then
          t_msg_buf := utl_raw.substr( p_msg, t_idx, t_chunksize );
          t_idx := t_idx + t_chunksize;
        else
          if t_idx <= t_len
          then
            t_msg_buf := utl_raw.substr( p_msg, t_idx );
            t_idx := t_len + 1;
          else
            t_msg_buf := '';
          end if;
          if nvl( length( t_msg_buf ), 0 ) + t_pad_len * 2 <= 32766
          then
            t_msg_buf := t_msg_buf || t_pad;
            t_idx := t_idx + t_pad_len;
          end if;
        end if;
        for i in 1 .. length( t_msg_buf ) / 128
        loop
          t_block := substr( t_msg_buf, i * 128 - 127, 128 );
  --
          for i in 1 .. 5
          loop
           sl(i) := st(i);
           sr(i) := st(i);
          end loop;
  --
          fa( sl, 1
            , tp_crypto( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15 )
            , tp_crypto(11,14,15,12, 5, 8, 7, 9,11,13,14,15, 6, 7, 9, 8 )
            );
          ga( sl, 5, 1518500249 -- 5a827999
            , tp_crypto( 7, 4,13, 1,10, 6,15, 3,12, 0, 9, 5, 2,14,11, 8 )
            , tp_crypto( 7, 6, 8,13,11, 9, 7,15, 7,12,15, 9,11, 7,13,12 )
            );
          ha( sl, 4, 1859775393  -- 6ed9eba1
            , tp_crypto( 3,10,14, 4, 9,15, 8, 1, 2, 7, 0, 6,13,11, 5,12 )
            , tp_crypto(11,13, 6, 7,14, 9,13,15,14, 8,13, 6, 5,12, 7, 5 )
            );
          ka( sl, 3, 2400959708  -- 8f1bbcdc
            , tp_crypto( 1, 9,11,10, 0, 8,12, 4,13, 3, 7,15,14, 5, 6, 2 )
            , tp_crypto(11,12,14,15,14,15, 9, 8, 9,14, 5, 6, 8, 6, 5,12 )
            );
          la( sl, 2, 2840853838  -- a953fd4e
            , tp_crypto( 4, 0, 5, 9, 7,12, 2,10,14, 1, 3, 8,11, 6,15,13 )
            , tp_crypto( 9,15, 5,11, 6, 8,13,12, 5,12,13,14,11, 8, 5, 6 )
            );
  --
          la( sr, 1, 1352829926  -- 50a28be6
            , tp_crypto( 5,14, 7, 0, 9, 2,11, 4,13, 6,15, 8, 1,10, 3,12 )
            , tp_crypto( 8, 9, 9,11,13,15,15, 5, 7, 7, 8,11,14,14,12, 6 )
            );
          ka( sr, 5, 1548603684  -- 5c4dd124
            , tp_crypto( 6,11, 3, 7, 0,13, 5,10,14,15, 8,12, 4, 9, 1, 2 )
            , tp_crypto( 9,13,15, 7,12, 8, 9,11, 7, 7,12, 7, 6,15,13,11 )
            );
          ha( sr, 4, 1836072691  -- 6d703ef3
            , tp_crypto(15, 5, 1, 3, 7,14, 6, 9,11, 8,12, 2,10, 0, 4,13 )
            , tp_crypto( 9, 7,15,11, 8, 6, 6,14,12,13, 5,14,13,13, 7, 5 )
            );
          ga( sr, 3, 2053994217  -- 7a6d76e9
            , tp_crypto( 8, 6, 4, 1, 3,11,15, 0, 5,12, 2,13, 9, 7,10,14 )
            , tp_crypto(15, 5, 8,11,14,14, 6,14, 6, 9,12, 9,12, 5,15, 8 )
            );
          fa( sr, 2
            , tp_crypto(12,15,10, 4, 1, 5, 8, 7, 6, 2,13,14, 0, 3, 9,11 )
            , tp_crypto( 8, 5,12, 9,12, 5,14, 6, 8,13, 6, 5,15,13,11,11 )
            );
  --
          sl(2) := bitand( sl(2) + st(1) + sr(3), bmax32 );
          st(1) := bitand( st(2) + sl(3) + sr(4), bmax32 );
          st(2) := bitand( st(3) + sl(4) + sr(5), bmax32 );
          st(3) := bitand( st(4) + sl(5) + sr(1), bmax32 );
          st(4) := bitand( st(5) + sl(1) + sr(2), bmax32 );
          st(5) := sl(2);
  --
        end loop;
      end loop;
  --
      t_md := utl_raw.reverse( to_char( st(1), fmt2 ) )
           || utl_raw.reverse( to_char( st(2), fmt2 ) )
           || utl_raw.reverse( to_char( st(3), fmt2 ) )
           || utl_raw.reverse( to_char( st(4), fmt2 ) )
           || utl_raw.reverse( to_char( st(5), fmt2 ) );
  --
      return t_md;
    end;
  --
    function md4( p_msg raw )
    return raw
    is
      t_md varchar2(128);
      fmt1 varchar2(10) := 'XXXXXXXX';
      fmt2 varchar2(10) := 'fm0XXXXXXX';
      t_len pls_integer;
      t_pad_len pls_integer;
      t_pad varchar2(144);
      t_msg_buf varchar2(32766);
      t_idx pls_integer;
      t_chunksize pls_integer := 16320; -- 255 * 64
      t_block varchar2(128);
      a number;
      b number;
      c number;
      d number;
      AA number;
      BB number;
      CC number;
      DD number;
  --
      procedure ff( a in out number, b number, c number, d number, xi number, s pls_integer )
      is
        x number := utl_raw.cast_to_binary_integer( substr( t_block, xi * 8 + 1, 8 ), utl_raw.little_endian );
      begin
        a := a + bitor( bitand( b, c ), bitand( - b - 1, d ) ) + x;
        a := rol32( a, s );
      end;
  --
      procedure gg( a in out number, b number, c number, d number, xi number, s pls_integer )
      is
        x number := utl_raw.cast_to_binary_integer( substr( t_block, xi * 8 + 1, 8 ), utl_raw.little_endian );
      begin
        a := a + bitor( bitor( bitand( b, c ), bitand( b, d ) ), bitand( c, d ) ) + x + 1518500249; -- to_number( '5a827999', 'xxxxxxxx' );
        a := rol32( a, s );
      end;
  --
      procedure hh( a in out number, b number, c number, d number, xi number, s pls_integer )
      is
        x number := utl_raw.cast_to_binary_integer( substr( t_block, xi * 8 + 1, 8 ), utl_raw.little_endian );
      begin
        a := a + bitxor( bitxor( b, c ), d ) + x + 1859775393; -- to_number( '6ed9eba1', 'xxxxxxxx' );
        a := rol32( a, s );
      end;
  --
    begin
      t_len := nvl( utl_raw.length( p_msg ), 0 );
      t_pad_len := 64 - mod( t_len, 64 );
      if t_pad_len < 9
      then
        t_pad_len := 64 + t_pad_len;
      end if;
      t_pad := rpad( '8', t_pad_len * 2 - 16, '0' )
         || utl_raw.cast_from_binary_integer( t_len * 8, utl_raw.little_endian )
         || '00000000';
  --
      AA := to_number( '67452301', fmt1 );
      BB := to_number( 'efcdab89', fmt1 );
      CC := to_number( '98badcfe', fmt1 );
      DD := to_number( '10325476', fmt1 );
  --
      t_idx := 1;
      while t_idx <= t_len + t_pad_len
      loop
        if t_len - t_idx + 1 >= t_chunksize
        then
          t_msg_buf := utl_raw.substr( p_msg, t_idx, t_chunksize );
          t_idx := t_idx + t_chunksize;
        else
          if t_idx <= t_len
          then
            t_msg_buf := utl_raw.substr( p_msg, t_idx );
            t_idx := t_len + 1;
          else
            t_msg_buf := '';
          end if;
          if nvl( length( t_msg_buf ), 0 ) + t_pad_len * 2 <= 32766
          then
            t_msg_buf := t_msg_buf || t_pad;
            t_idx := t_idx + t_pad_len;
          end if;
        end if;
        for i in 1 .. length( t_msg_buf ) / 128
        loop
          t_block := substr( t_msg_buf, i * 128 - 127, 128 );
          a := AA;
          b := BB;
          c := CC;
          d := DD;
  --
          for j in 0 .. 3
          loop
            ff( a, b, c, d, j * 4 + 0, 3 );
            ff( d, a, b, c, j * 4 + 1, 7 );
            ff( c, d, a, b, j * 4 + 2, 11 );
            ff( b, c, d, a, j * 4 + 3, 19 );
          end loop;
  --
          for j in 0 .. 3
          loop
            gg( a, b, c, d, j + 0, 3 );
            gg( d, a, b, c, j + 4, 5 );
            gg( c, d, a, b, j + 8, 9 );
            gg( b, c, d, a, j + 12, 13 );
          end loop;
  --
          for j in 0 .. 3
          loop
            hh( a, b, c, d, bitand( j, 1 ) * 2 + bitand( j, 2 ) / 2 + 0, 3 );
            hh( d, a, b, c, bitand( j, 1 ) * 2 + bitand( j, 2 ) / 2 + 8, 9 );
            hh( c, d, a, b, bitand( j, 1 ) * 2 + bitand( j, 2 ) / 2 + 4, 11 );
            hh( b, c, d, a, bitand( j, 1 ) * 2 + bitand( j, 2 ) / 2 + 12, 15 );
          end loop;
  --
          AA := bitand( AA + a, bmax32 );
          BB := bitand( BB + b, bmax32 );
          CC := bitand( CC + c, bmax32 );
          DD := bitand( DD + d, bmax32 );
        end loop;
      end loop;
  --
      t_md := utl_raw.reverse( to_char( AA, fmt2 ) )
           || utl_raw.reverse( to_char( BB, fmt2 ) )
           || utl_raw.reverse( to_char( CC, fmt2 ) )
           || utl_raw.reverse( to_char( DD, fmt2 ) );
  --
      return t_md;
    end;
  --
    function md5( p_msg raw )
    return raw
    is
      t_md varchar2(128);
      fmt1 varchar2(10) := 'XXXXXXXX';
      fmt2 varchar2(10) := 'fm0XXXXXXX';
      t_len pls_integer;
      t_pad_len pls_integer;
      t_pad varchar2(144);
      t_msg_buf varchar2(32766);
      t_idx pls_integer;
      t_chunksize pls_integer := 16320; -- 255 * 64
      t_block varchar2(128);
      type tp_tab is table of number;
      Ht tp_tab;
      K tp_tab;
      s tp_tab;
      H_str varchar2(64);
      K_str varchar2(512);
      a number;
      b number;
      c number;
      d number;
      e number;
      f number;
      g number;
      h number;
    begin
      t_len := nvl( utl_raw.length( p_msg ), 0 );
      t_pad_len := 64 - mod( t_len, 64 );
      if t_pad_len < 9
      then
        t_pad_len := 64 + t_pad_len;
      end if;
      t_pad := rpad( '8', t_pad_len * 2 - 16, '0' )
         || utl_raw.cast_from_binary_integer( t_len * 8, utl_raw.little_endian )
         || '00000000';
  --
      s := tp_tab( 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22
                 , 5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20
                 , 4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23
                 , 6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
                 );
  --
      H_str := '67452301efcdab8998badcfe10325476';
      Ht := tp_tab();
      Ht.extend(4);
      for i in 1 .. 4
      loop
        Ht(i) := to_number( substr( H_str, i * 8 - 7, 8 ), fmt1 );
      end loop;
  --
      K_str := 'd76aa478e8c7b756242070dbc1bdceeef57c0faf4787c62aa8304613fd469501'
            || '698098d88b44f7afffff5bb1895cd7be6b901122fd987193a679438e49b40821'
            || 'f61e2562c040b340265e5a51e9b6c7aad62f105d02441453d8a1e681e7d3fbc8'
            || '21e1cde6c33707d6f4d50d87455a14eda9e3e905fcefa3f8676f02d98d2a4c8a'
            || 'fffa39428771f6816d9d6122fde5380ca4beea444bdecfa9f6bb4b60bebfbc70'
            || '289b7ec6eaa127fad4ef308504881d05d9d4d039e6db99e51fa27cf8c4ac5665'
            || 'f4292244432aff97ab9423a7fc93a039655b59c38f0ccc92ffeff47d85845dd1'
            || '6fa87e4ffe2ce6e0a30143144e0811a1f7537e82bd3af2352ad7d2bbeb86d391';
      K := tp_tab();
      K.extend(64);
      for i in 1 .. 64
      loop
        K(i) := to_number( substr( K_str, i * 8 - 7, 8 ), fmt1 );
      end loop;
      t_idx := 1;
      while t_idx <= t_len + t_pad_len
      loop
        if t_len - t_idx + 1 >= t_chunksize
        then
          t_msg_buf := utl_raw.substr( p_msg, t_idx, t_chunksize );
          t_idx := t_idx + t_chunksize;
        else
          if t_idx <= t_len
          then
            t_msg_buf := utl_raw.substr( p_msg, t_idx );
            t_idx := t_len + 1;
          else
            t_msg_buf := '';
          end if;
          if nvl( length( t_msg_buf ), 0 ) + t_pad_len * 2 <= 32766
          then
            t_msg_buf := t_msg_buf || t_pad;
            t_idx := t_idx + t_pad_len;
          end if;
        end if;
        for i in 1 .. length( t_msg_buf ) / 128
        loop
          t_block := substr( t_msg_buf, i * 128 - 127, 128 );
          a := Ht(1);
          b := Ht(2);
          c := Ht(3);
          d := Ht(4);
          for j in 0 .. 63
          loop
            if j <= 15
            then
              F := bitand( bitxor( D, bitand( B, bitxor( C, D ) ) ), bmax32 );
              g := j;
            elsif j <= 31
            then
              F := bitand( bitxor( C, bitand( D, bitxor( B, C ) ) ), bmax32 );
              g := mod( 5*j + 1, 16 );
            elsif j <= 47
            then
              F := bitand( bitxor( B, bitxor( C, D ) ), bmax32 );
              g := mod( 3*j + 5, 16 );
            else
              F := bitand( bitxor( C, bitor( B, - D  - 1 ) ), bmax32 );
              g := mod( 7*j, 16 );
            end if;
            e := D;
            D := C;
            C := B;
            h := utl_raw.cast_to_binary_integer( substr( t_block, g * 8 + 1, 8 ), utl_raw.little_endian );
            B := bitand( B + rol32( bitand( A + F + k( j + 1 ) + h, bmax32 ), s( j + 1 ) ), bmax32 );
            A := e;
          end loop;
          Ht(1) := bitand( Ht(1) + a, bmax32 );
          Ht(2) := bitand( Ht(2) + b, bmax32 );
          Ht(3) := bitand( Ht(3) + c, bmax32 );
          Ht(4) := bitand( Ht(4) + d, bmax32 );
        end loop;
      end loop;
  --
      for i in 1 .. 4
      loop
        t_md := t_md || utl_raw.reverse( to_char( Ht(i), fmt2 ) );
      end loop;
  --
      return t_md;
    end;
  --
    function sha1( p_val raw )
    return raw
    is
      t_val raw(32767);
      t_len pls_integer;
      t_padding raw(128);
      type tp_n is table of integer index by pls_integer;
      w tp_n;
      tw tp_n;
      th tp_n;
      c_ffffffff integer := to_number( 'ffffffff', 'xxxxxxxx' );
      c_5A827999 integer := to_number( '5A827999', 'xxxxxxxx' );
      c_6ED9EBA1 integer := to_number( '6ED9EBA1', 'xxxxxxxx' );
      c_8F1BBCDC integer := to_number( '8F1BBCDC', 'xxxxxxxx' );
      c_CA62C1D6 integer := to_number( 'CA62C1D6', 'xxxxxxxx' );
  --
      function radd( x integer, y integer )
      return integer
      is
      begin
        return x + y;
      end;
  --
    begin
      th(0) := to_number( hextoraw( '67452301' ), 'xxxxxxxx' );
      th(1) := to_number( hextoraw( 'EFCDAB89' ), 'xxxxxxxx' );
      th(2) := to_number( hextoraw( '98BADCFE' ), 'xxxxxxxx' );
      th(3) := to_number( hextoraw( '10325476' ), 'xxxxxxxx' );
      th(4) := to_number( hextoraw( 'C3D2E1F0' ), 'xxxxxxxx' );
  --
      t_len := nvl( utl_raw.length( p_val ), 0 );
      if mod( t_len, 64 ) < 55
      then
        t_padding :=  utl_raw.concat( hextoraw( '80' ), utl_raw.copies( hextoraw( '00' ), 55 - mod( t_len, 64 ) ) );
      elsif mod( t_len, 64 ) = 55
      then
        t_padding :=  hextoraw( '80' );
      else
        t_padding :=  utl_raw.concat( hextoraw( '80' ), utl_raw.copies( hextoraw( '00' ), 119 - mod( t_len, 64 ) ) );
      end if;
      t_padding := utl_raw.concat( t_padding
                                 , hextoraw( '00000000' )
                                 , utl_raw.cast_from_binary_integer( t_len * 8 ) -- only 32 bits number!!
                                 );
      t_val := utl_raw.concat( p_val, t_padding );
      for c in 0 .. utl_raw.length( t_val ) / 64 - 1
      loop
        for i in 0 .. 15
        loop
          w(i) := to_number( utl_raw.substr( t_val, c*64 + i*4 + 1, 4 ), 'xxxxxxxx' );
        end loop;
        for i in 16 .. 79
        loop
          w(i) := rol32( bitxor( bitxor( w(i-3), w(i-8) ), bitxor( w(i-14), w(i-16) ) ), 1 );
        end loop;
  --
        for i in 0 .. 4
        loop
          tw(i) := th(i);
        end loop;
  --
        for i in 0 .. 19
        loop
          tw(4-mod(i,5)) := tw(4-mod(i,5)) + rol32( tw(4-mod(i+4,5)), 5 )
                          + bitor( bitand( tw(4-mod(i+3,5)), tw(4-mod(i+2,5)) )
                                 , bitand( c_ffffffff - tw(4-mod(i+3,5)), tw(4-mod(i+1,5)) )
                                 )
                          + w(i) + c_5A827999;
          tw(4-mod(i+3,5)) := rol32( tw( 4-mod(i+3,5)), 30 );
        end loop;
        for i in 20 .. 39
        loop
          tw(4-mod(i,5)) := tw(4-mod(i,5)) + rol32( tw(4-mod(i+4,5)), 5 )
                          + bitxor( bitxor( tw(4-mod(i+3,5)), tw(4-mod(i+2,5)) )
                                  , tw(4-mod(i+1,5))
                                  )
                          + w(i) + c_6ED9EBA1;
          tw(4-mod(i+3,5)) := rol32( tw( 4-mod(i+3,5)), 30 );
        end loop;
        for i in 40 .. 59
        loop
          tw(4-mod(i,5)) := tw(4-mod(i,5)) + rol32( tw(4-mod(i+4,5)), 5 )
                          + bitor( bitand( tw(4-mod(i+3,5)), tw(4-mod(i+2,5)) )
                                 , bitor( bitand( tw(4-mod(i+3,5)), tw(4-mod(i+1,5)) )
                                                , bitand( tw(4-mod(i+2,5)), tw(4-mod(i+1,5)) )
                                                )
                                 )
                          + w(i) + c_8F1BBCDC;
          tw(4-mod(i+3,5)) := rol32( tw( 4-mod(i+3,5)), 30 );
        end loop;
        for i in 60 .. 79
        loop
          tw(4-mod(i,5)) := tw(4-mod(i,5)) + rol32( tw(4-mod(i+4,5)), 5 )
                          + bitxor( bitxor( tw(4-mod(i+3,5)), tw(4-mod(i+2,5)) )
                                  , tw(4-mod(i+1,5))
                                  )
                          + w(i) + c_CA62C1D6;
          tw(4-mod(i+3,5)) := rol32( tw( 4-mod(i+3,5)), 30 );
        end loop;
  --
        for i in 0 .. 4
        loop
          th(i) := bitand( th(i) + tw(i), bmax32 );
        end loop;
  --
      end loop;
  --
      return utl_raw.concat( to_char( th(0), 'fm0000000X' )
                           , to_char( th(1), 'fm0000000X' )
                           , to_char( th(2), 'fm0000000X' )
                           , to_char( th(3), 'fm0000000X' )
                           , to_char( th(4), 'fm0000000X' )
                           );
    end;
  --
    function sha256( p_msg raw, p_256 boolean )
    return raw
    is
      t_md varchar2(128);
      fmt1 varchar2(10) := 'xxxxxxxx';
      fmt2 varchar2(10) := 'fm0xxxxxxx';
      t_len pls_integer;
      t_pad_len pls_integer;
      t_pad varchar2(144);
      t_msg_buf varchar2(32766);
      t_idx pls_integer;
      t_chunksize pls_integer := 16320; -- 255 * 64
      t_block varchar2(128);
      type tp_tab is table of number;
      Ht tp_tab;
      K tp_tab;
      w tp_tab;
      H_str varchar2(64);
      K_str varchar2(512);
      a number;
      b number;
      c number;
      d number;
      e number;
      f number;
      g number;
      h number;
      s0 number;
      s1 number;
      maj number;
      ch number;
      t1 number;
      t2 number;
      tmp number;
    begin
      t_len := nvl( utl_raw.length( p_msg ), 0 );
      t_pad_len := 64 - mod( t_len, 64 );
      if t_pad_len < 9
      then
        t_pad_len := 64 + t_pad_len;
      end if;
      t_pad := rpad( '8', t_pad_len * 2 - 8, '0' ) || to_char( t_len * 8, 'fm0XXXXXXX' );
  --
      if p_256
      then
        H_str := '6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19';
      else
        H_str := 'c1059ed8367cd5073070dd17f70e5939ffc00b316858151164f98fa7befa4fa4';
      end if;
      Ht := tp_tab();
      Ht.extend(8);
      for i in 1 .. 8
      loop
        Ht(i) := to_number( substr( H_str, i * 8 - 7, 8 ), fmt1 );
      end loop;
  --
      K_str := '428a2f9871374491b5c0fbcfe9b5dba53956c25b59f111f1923f82a4ab1c5ed5'
            || 'd807aa9812835b01243185be550c7dc372be5d7480deb1fe9bdc06a7c19bf174'
            || 'e49b69c1efbe47860fc19dc6240ca1cc2de92c6f4a7484aa5cb0a9dc76f988da'
            || '983e5152a831c66db00327c8bf597fc7c6e00bf3d5a7914706ca635114292967'
            || '27b70a852e1b21384d2c6dfc53380d13650a7354766a0abb81c2c92e92722c85'
            || 'a2bfe8a1a81a664bc24b8b70c76c51a3d192e819d6990624f40e3585106aa070'
            || '19a4c1161e376c082748774c34b0bcb5391c0cb34ed8aa4a5b9cca4f682e6ff3'
            || '748f82ee78a5636f84c878148cc7020890befffaa4506cebbef9a3f7c67178f2';
      K := tp_tab();
      K.extend(64);
      for i in 1 .. 64
      loop
        K(i) := to_number( substr( K_str, i * 8 - 7, 8 ), fmt1 );
      end loop;
  --
      t_idx := 1;
      while t_idx <= t_len + t_pad_len
      loop
        if t_len - t_idx + 1 >= t_chunksize
        then
          t_msg_buf := utl_raw.substr( p_msg, t_idx, t_chunksize );
          t_idx := t_idx + t_chunksize;
        else
          if t_idx <= t_len
          then
            t_msg_buf := utl_raw.substr( p_msg, t_idx );
            t_idx := t_len + 1;
          else
            t_msg_buf := '';
          end if;
          if nvl( length( t_msg_buf ), 0 ) + t_pad_len * 2 <= 32766
          then
            t_msg_buf := t_msg_buf || t_pad;
            t_idx := t_idx + t_pad_len;
          end if;
        end if;
  --
        for i in 1 .. length( t_msg_buf ) / 128
        loop
  --
          a := Ht(1);
          b := Ht(2);
          c := Ht(3);
          d := Ht(4);
          e := Ht(5);
          f := Ht(6);
          g := Ht(7);
          h := Ht(8);
  --
          t_block := substr( t_msg_buf, i * 128 - 127, 128 );
          w := tp_tab();
          w.extend( 64 );
          for j in 1 .. 16
          loop
            w(j) := to_number( substr( t_block, j * 8  - 7, 8 ), fmt1 );
          end loop;
  --
          for j in 17 .. 64
          loop
            tmp := w(j-15);
            s0 := bitxor( bitxor( ror32( tmp, 7), ror32( tmp, 18 ) ), shr( tmp, 3 ) );
            tmp := w(j-2);
            s1 := bitxor( bitxor( ror32( tmp, 17), ror32( tmp, 19 ) ), shr( tmp, 10 ) );
            w(j) := bitand( w(j-16) + s0 + w(j-7) + s1, bmax32 );
          end loop;
  --
          for j in 1 .. 64
          loop
            s0 := bitxor( bitxor( ror32( a, 2 ), ror32( a, 13 ) ), ror32( a, 22 ) );
            maj := bitxor( bitxor( bitand( a, b ), bitand( a, c ) ), bitand( b, c ) );
            t2 := bitand( s0 + maj, bmax32 );
            s1 := bitxor( bitxor( ror32( e, 6 ), ror32( e, 11 ) ), ror32( e, 25 ) );
            ch := bitxor( bitand( e, f ), bitand( - e - 1, g ) );
            t1 := h + s1 + ch + K(j) + w(j);
            h := g;
            g := f;
            f := e;
            e := d + t1;
            d := c;
            c := b;
            b := a;
            a := t1 + t2;
          end loop;
  --
          Ht(1) := bitand( Ht(1) + a, bmax32 );
          Ht(2) := bitand( Ht(2) + b, bmax32 );
          Ht(3) := bitand( Ht(3) + c, bmax32 );
          Ht(4) := bitand( Ht(4) + d, bmax32 );
          Ht(5) := bitand( Ht(5) + e, bmax32 );
          Ht(6) := bitand( Ht(6) + f, bmax32 );
          Ht(7) := bitand( Ht(7) + g, bmax32 );
          Ht(8) := bitand( Ht(8) + h, bmax32 );
  --
        end loop;
      end loop;
      for i in 1 .. case when p_256 then 8 else 7 end
      loop
        t_md := t_md || to_char( Ht(i), fmt2 );
      end loop;
      return t_md;
    end;
  --
    function sha512( p_msg raw, p_512 boolean )
    return raw
    is
      t_md varchar2(128);
      fmt1 varchar2(20) := 'xxxxxxxxxxxxxxxx';
      fmt2 varchar2(20) := 'fm0xxxxxxxxxxxxxxx';
      t_len pls_integer;
      t_pad_len pls_integer;
      t_pad varchar2(288);
      t_msg_buf varchar2(32766);
      t_idx pls_integer;
      t_chunksize pls_integer := 16256; -- 127 * 128
      t_block varchar2(256);
      type tp_tab is table of number;
      Ht tp_tab;
      K tp_tab;
      w tp_tab;
      H_str varchar2(128);
      K_str varchar2(1280);
      a number;
      b number;
      c number;
      d number;
      e number;
      f number;
      g number;
      h number;
      s0 number;
      s1 number;
      maj number;
      ch number;
      t1 number;
      t2 number;
      tmp number;
    begin
      t_len := nvl( utl_raw.length( p_msg ), 0 );
      t_pad_len := 128 - mod( t_len, 128 );
      if t_pad_len < 17
      then
        t_pad_len := 128 + t_pad_len;
      end if;
      t_pad := rpad( '8', t_pad_len * 2 - 16, '0' ) || to_char( t_len * 8, 'fm0XXXXXXX' );
  --
      if p_512
      then
        H_str := '6a09e667f3bcc908bb67ae8584caa73b3c6ef372fe94f82ba54ff53a5f1d36f1'
              || '510e527fade682d19b05688c2b3e6c1f1f83d9abfb41bd6b5be0cd19137e2179';
      else
        H_str := 'cbbb9d5dc1059ed8629a292a367cd5079159015a3070dd17152fecd8f70e5939'
              || '67332667ffc00b318eb44a8768581511db0c2e0d64f98fa747b5481dbefa4fa4';
      end if;
      Ht := tp_tab();
      Ht.extend(8);
      for i in 1 .. 8
      loop
        Ht(i) := to_number( substr( H_str, i * 16 - 15, 16 ), fmt1 );
      end loop;
  --
      K_str := '428a2f98d728ae227137449123ef65cdb5c0fbcfec4d3b2fe9b5dba58189dbbc'
            || '3956c25bf348b53859f111f1b605d019923f82a4af194f9bab1c5ed5da6d8118'
            || 'd807aa98a303024212835b0145706fbe243185be4ee4b28c550c7dc3d5ffb4e2'
            || '72be5d74f27b896f80deb1fe3b1696b19bdc06a725c71235c19bf174cf692694'
            || 'e49b69c19ef14ad2efbe4786384f25e30fc19dc68b8cd5b5240ca1cc77ac9c65'
            || '2de92c6f592b02754a7484aa6ea6e4835cb0a9dcbd41fbd476f988da831153b5'
            || '983e5152ee66dfaba831c66d2db43210b00327c898fb213fbf597fc7beef0ee4'
            || 'c6e00bf33da88fc2d5a79147930aa72506ca6351e003826f142929670a0e6e70'
            || '27b70a8546d22ffc2e1b21385c26c9264d2c6dfc5ac42aed53380d139d95b3df'
            || '650a73548baf63de766a0abb3c77b2a881c2c92e47edaee692722c851482353b'
            || 'a2bfe8a14cf10364a81a664bbc423001c24b8b70d0f89791c76c51a30654be30'
            || 'd192e819d6ef5218d69906245565a910f40e35855771202a106aa07032bbd1b8'
            || '19a4c116b8d2d0c81e376c085141ab532748774cdf8eeb9934b0bcb5e19b48a8'
            || '391c0cb3c5c95a634ed8aa4ae3418acb5b9cca4f7763e373682e6ff3d6b2b8a3'
            || '748f82ee5defb2fc78a5636f43172f6084c87814a1f0ab728cc702081a6439ec'
            || '90befffa23631e28a4506cebde82bde9bef9a3f7b2c67915c67178f2e372532b'
            || 'ca273eceea26619cd186b8c721c0c207eada7dd6cde0eb1ef57d4f7fee6ed178'
            || '06f067aa72176fba0a637dc5a2c898a6113f9804bef90dae1b710b35131c471b'
            || '28db77f523047d8432caab7b40c724933c9ebe0a15c9bebc431d67c49c100d4c'
            || '4cc5d4becb3e42b6597f299cfc657e2a5fcb6fab3ad6faec6c44198c4a475817';
      K := tp_tab();
      K.extend(80);
      for i in 1 .. 80
      loop
        K(i) := to_number( substr( K_str, i * 16 - 15, 16 ), fmt1 );
      end loop;
  --
      t_idx := 1;
      while t_idx <= t_len + t_pad_len
      loop
        if t_len - t_idx + 1 >= t_chunksize
        then
          t_msg_buf := utl_raw.substr( p_msg, t_idx, t_chunksize );
          t_idx := t_idx + t_chunksize;
        else
          if t_idx <= t_len
          then
            t_msg_buf := utl_raw.substr( p_msg, t_idx );
            t_idx := t_len + 1;
          else
            t_msg_buf := '';
          end if;
          if nvl( length( t_msg_buf ), 0 ) + t_pad_len * 2 <= 32766
          then
            t_msg_buf := t_msg_buf || t_pad;
            t_idx := t_idx + t_pad_len;
          end if;
        end if;
  --
        for i in 1 .. length( t_msg_buf ) / 256
        loop
  --
          a := Ht(1);
          b := Ht(2);
          c := Ht(3);
          d := Ht(4);
          e := Ht(5);
          f := Ht(6);
          g := Ht(7);
          h := Ht(8);
  --
          t_block := substr( t_msg_buf, i * 256 - 255, 256 );
          w := tp_tab();
          w.extend( 80 );
          for j in 1 .. 16
          loop
            w(j) := to_number( substr( t_block, j * 16  - 15, 16 ), fmt1 );
          end loop;
  --
          for j in 17 .. 80
          loop
            tmp := w(j-15);
            s0 := bitxor( bitxor( ror64( tmp, 1), ror64( tmp, 8 ) ), shr( tmp, 7 ) );
            tmp := w(j-2);
            s1 := bitxor( bitxor( ror64( tmp, 19), ror64( tmp, 61 ) ), shr( tmp, 6 ) );
            w(j) := bitand( w(j-16) + s0 + w(j-7) + s1, bmax64 );
          end loop;
  --
          for j in 1 .. 80
          loop
            s0 := bitxor( bitxor( ror64( a, 28 ), ror64( a, 34 ) ), ror64( a, 39 ) );
            maj := bitxor( bitxor( bitand( a, b ), bitand( a, c ) ), bitand( b, c ) );
            t2 := bitand( s0 + maj, bmax64 );
            s1 := bitxor( bitxor( ror64( e, 14 ), ror64( e, 18 ) ), ror64( e, 41 ) );
            ch := bitxor( bitand( e, f ), bitand( - e - 1, g ) );
            t1 := h + s1 + ch + K(j) + w(j);
            h := g;
            g := f;
            f := e;
            e := d + t1;
            d := c;
            c := b;
            b := a;
            a := t1 + t2;
          end loop;
  --
          Ht(1) := bitand( Ht(1) + a, bmax64 );
          Ht(2) := bitand( Ht(2) + b, bmax64 );
          Ht(3) := bitand( Ht(3) + c, bmax64 );
          Ht(4) := bitand( Ht(4) + d, bmax64 );
          Ht(5) := bitand( Ht(5) + e, bmax64 );
          Ht(6) := bitand( Ht(6) + f, bmax64 );
          Ht(7) := bitand( Ht(7) + g, bmax64 );
          Ht(8) := bitand( Ht(8) + h, bmax64 );
  --
        end loop;
      end loop;
      for i in 1 .. case when p_512 then 8 else 6 end
      loop
        t_md := t_md || to_char( Ht(i), fmt2 );
      end loop;
      return t_md;
    end;

    /**
     * Generates hash with raw values
     * See `oos_util_crypto.hash_str` to handle wrapping
     *
     * @example
     * select
     *   rawtohex(
     *     oos_util_crypto.hash(
     *       p_src => sys.utl_raw.cast_to_raw('hello'),
     *       p_typ => 4 -- oos_util_crypto.gc_hash_sh256
     *     )
     *   ) example
     * from dual
     * ;
     *
     * EXAMPLE
     * 2CF24DBA5FB0A30E26E83B2AC5B9E29E1B161E5C1FA7425E73043362938B9824
     *
     * @author Aton Scheffer
     * @created 4-Oct-2016
     * @param p_src
     * @param p_typ see `oos_util_crypto.gc_hash*` variables
     * @return
     */
    function hash(
      p_src raw,
      p_typ pls_integer)
    return raw
    is
    begin
      return case p_typ
               when gc_hash_md4 then md4( p_src )
               when gc_hash_md5 then md5( p_src )
               when gc_hash_sh1 then sha1( p_src )
               when gc_hash_sh224 then sha256( p_src, false )
               when gc_hash_sh256 then sha256( p_src, true )
               when gc_hash_sh384 then sha512( p_src, false )
               when gc_hash_sh512 then sha512( p_src, true )
               when gc_hash_ripemd160 then ripemd160( p_src )
             end;
    end;

    /**
     * Generates hash
     *
     *
     * @example
     * select
     *   oos_util_crypto.hash_str(
     *     p_src => 'hello',
     *     p_typ => 4 -- oos_util_crypto.gc_hash_md5
     *   ) example
     * from dual
     * ;
     *
     * EXAMPLE
     * 2CF24DBA5FB0A30E26E83B2AC5B9E29E1B161E5C1FA7425E73043362938B9824
     *
     * @author Martin D'Souza
     * @created 19-Jun-2017
     * @param p_src
     * @param p_typ see `oos_util_crypto.gc_hash*` variables
     * @return Hex hashed value as a string
     */
    function hash_str(
      p_src varchar2,
      p_typ pls_integer)
      return varchar2
    as
    begin
      return rawtohex(
        hash(
          p_src => sys.utl_raw.cast_to_raw(p_src),
          p_typ => p_typ)
        );
    end hash_str;

    /**
     * Generates mac
     * Note: see mac_str for string inputs
     *
     * @example
     * select
     *   rawtohex(
     *     oos_util_crypto.mac(
     *       p_src => utl_raw.cast_to_raw('hello'),
     *       p_typ => 3, -- oos_util_crypto.gc_hmac_sh256
     *       p_key => utl_raw.cast_to_raw('abc')
     *     )
     *   ) example
     * from dual
     * ;
     *
     * EXAMPLE
     * F3166A3A404599D2046ED2AAE479B37D54B51D2E85259C9E314042753BE7D813
     *
     * @author Aton Scheffer
     * @created 4-Oct-2016
     * @param p_src
     * @param p_typ see `oos_util_crypto.gc_hmac*` variables
     * @param p_key secret key
     * @return
     */
    function mac(
      p_src raw,
      p_typ pls_integer,
      p_key raw )
    return raw
    is
      t_key raw(128);
      t_len pls_integer;
      t_blocksize pls_integer := case
                                   when p_typ in ( gc_HMAC_SH384, gc_HMAC_SH512 )
                                     then 128
                                     else 64
                                 end;
      t_typ pls_integer := case p_typ
                             when gc_hmac_md4       then gc_hash_md4
                             when gc_hmac_md5       then gc_hash_md5
                             when gc_hmac_sh1       then gc_hash_sh1
                             when gc_hmac_sh224     then gc_hash_sh224
                             when gc_hmac_sh256     then gc_hash_sh256
                             when gc_hmac_sh384     then gc_hash_sh384
                             when gc_hmac_sh512     then gc_hash_sh512
                             when gc_hmac_ripemd160 then gc_hash_ripemd160
                           end;
    begin
      t_len := utl_raw.length( p_key );
      if t_len > t_blocksize
      then
        t_key := hash( p_key, t_typ );
        t_len := utl_raw.length( t_key );
      else
        t_key := p_key;
      end if;
      if t_len < t_blocksize
      then
        t_key := utl_raw.concat( t_key, utl_raw.copies( hextoraw( '00' ), t_blocksize - t_len ) );
      elsif t_len is null
      then
        t_key := utl_raw.copies( hextoraw( '00' ), t_blocksize );
      end if;
      return hash( utl_raw.concat( utl_raw.bit_xor( utl_raw.copies( hextoraw( '5c' ), t_blocksize ), t_key )
                                 , hash( utl_raw.concat( utl_raw.bit_xor( utl_raw.copies( hextoraw( '36' ), t_blocksize ), t_key )
                                                       , p_src
                                                       )
                                       , t_typ
                                       )
                                 )
                 , t_typ
                 );
    end;


    /**
     * Generates mac with string input / output
     *
     *
     * @example
     * select
     *   oos_util_crypto.mac_str(
     *     p_src => 'hello',
     *     p_typ => 3, -- oos_util_crypto.gc_hmac_sh256
     *     p_key => 'abc'
     *   ) example
     * from dual
     * ;
     *
     * EXAMPLE
     * F3166A3A404599D2046ED2AAE479B37D54B51D2E85259C9E314042753BE7D813
     *
     * @author Martin D'Souza
     * @created 19-Jun-2017
     * @param p_src
     * @param p_typ see `oos_util_crypto.gc_hmac*` variables
     * @param p_key secret key
     * @return mac hex value as varchar2
     */
    function mac_str(
      p_src varchar2,
      p_typ pls_integer,
      p_key varchar2 )
      return varchar2
    as
    begin
      return
        rawtohex(
          oos_util_crypto.mac(
            p_src => utl_raw.cast_to_raw(p_src),
            p_typ => p_typ,
            p_key => utl_raw.cast_to_raw(p_key)
         )
       );
    end mac_str;

  --
    function randombytes( number_bytes positive )
    return raw
    is
      type tp_arcfour_sbox is table of pls_integer index by pls_integer;
      type tp_arcfour is record
        ( s tp_arcfour_sbox
        , i pls_integer
        , j pls_integer
        );
      t_tmp pls_integer;
      t_s2 tp_arcfour_sbox;
      t_arcfour tp_arcfour;
      t_rv varchar2(32767);
      t_seed varchar2(3999);
    begin
      t_seed := utl_raw.cast_from_number( dbms_utility.get_cpu_time )
             || utl_raw.cast_from_number( extract( second from systimestamp ) )
             || utl_raw.cast_from_number( dbms_utility.get_time );
      for i in 0 .. 255
      loop
        t_arcfour.s(i) := i;
      end loop;
      t_seed := t_seed
             || utl_raw.cast_from_number( dbms_utility.get_time )
             || utl_raw.cast_from_number( extract( second from systimestamp ) )
             || utl_raw.cast_from_number( dbms_utility.get_cpu_time );
      for i in 0 .. 255
      loop
        t_s2(i) := to_number( substr( t_seed, mod( i, length( t_seed ) ) + 1, 1 ), 'XX' );
      end loop;
      t_arcfour.j := 0;
      for i in 0 .. 255
      loop
        t_arcfour.j := mod( t_arcfour.j + t_arcfour.s(i) + t_s2(i), 256 );
        t_tmp := t_arcfour.s(i);
        t_arcfour.s(i) := t_arcfour.s( t_arcfour.j );
        t_arcfour.s( t_arcfour.j ) := t_tmp;
      end loop;
      t_arcfour.i := 0;
      t_arcfour.j := 0;
  --
      for i in 1 .. 1536
      loop
        t_arcfour.i := bitand( t_arcfour.i + 1, 255 );
        t_arcfour.j := bitand( t_arcfour.j + t_arcfour.s( t_arcfour.i ), 255 );
        t_tmp := t_arcfour.s( t_arcfour.i );
        t_arcfour.s( t_arcfour.i ) := t_arcfour.s( t_arcfour.j );
        t_arcfour.s( t_arcfour.j ) := t_tmp;
      end loop;
  --
      for i in 1 .. number_bytes
      loop
        t_arcfour.i := bitand( t_arcfour.i + 1, 255 );
        t_arcfour.j := bitand( t_arcfour.j + t_arcfour.s( t_arcfour.i ), 255 );
        t_tmp := t_arcfour.s( t_arcfour.i );
        t_arcfour.s( t_arcfour.i ) := t_arcfour.s( t_arcfour.j );
        t_arcfour.s( t_arcfour.j ) := t_tmp;
        t_rv := t_rv || to_char( t_arcfour.s( bitand( t_arcfour.s( t_arcfour.i ) + t_arcfour.s( t_arcfour.j ), 255 ) ), 'fm0x' );
      end loop;
      return t_rv;
    end;
  --
    procedure aes_encrypt_key
      ( key varchar2
      , p_encrypt_key out nocopy tp_aes_tab
      )
    is
      rcon tp_aes_tab;
      t_r number;
      SS varchar2(512);
      s1 number;
      s2 number;
      s3 number;
      t number;
      Nk pls_integer;
      n pls_integer;
      r pls_integer;
    begin
      SS := '637c777bf26b6fc53001672bfed7ab76ca82c97dfa5947f0add4a2af9ca472c0'
         || 'b7fd9326363ff7cc34a5e5f171d8311504c723c31896059a071280e2eb27b275'
         || '09832c1a1b6e5aa0523bd6b329e32f8453d100ed20fcb15b6acbbe394a4c58cf'
         || 'd0efaafb434d338545f9027f503c9fa851a3408f929d38f5bcb6da2110fff3d2'
         || 'cd0c13ec5f974417c4a77e3d645d197360814fdc222a908846eeb814de5e0bdb'
         || 'e0323a0a4906245cc2d3ac629195e479e7c8376d8dd54ea96c56f4ea657aae08'
         || 'ba78252e1ca6b4c6e8dd741f4bbd8b8a703eb5664803f60e613557b986c11d9e'
         || 'e1f8981169d98e949b1e87e9ce5528df8ca1890dbfe6426841992d0fb054bb16';
      for i in 0 .. 255
      loop
        s1 := to_number( substr( SS, i * 2 + 1, 2 ), 'XX' );
        s2 := s1 * 2;
        if s2 >= 256
        then
          s2 := bitxor( s2, 283 );
        end if;
        s3 := bitxor( s1, s2 );
        p_encrypt_key(i) := s1;
        t := bitor( bitor( bitor( shl( s2, 24 ), shl( s1, 16 ) ), shl( s1, 8 ) ), s3 );
        p_encrypt_key( 256 + i ) := t;
        t := rol32( t, 24 );
        p_encrypt_key( 512 + i ) := t;
        t := rol32( t, 24 );
        p_encrypt_key( 768 + i ) := t;
        t := rol32( t, 24 );
        p_encrypt_key( 1024 + i ) := t;
      end loop;
  --
      t_r := 1;
      rcon(0) := shl( t_r, 24 );
      for i in 1 .. 9
      loop
        t_r := t_r * 2;
        if t_r >= 256
        then
          t_r := bitxor( t_r, 283 );
        end if;
        rcon(i) := shl( t_r, 24 );
      end loop;
      rcon(7) := - rcon(7);
      Nk := length( key ) / 8;
      for i in 0 .. Nk - 1
      loop
        p_encrypt_key( 1280 + i ) := to_number( substr( key, i * 8 + 1, 8 ), 'xxxxxxxx' );
      end loop;
      n := 0;
      r := 0;
      for i in Nk .. Nk * 4 + 27
      loop
        t := p_encrypt_key( 1280 + i - 1 );
        if n = 0
        then
          n := Nk;
          t := bitor( bitor( shl( p_encrypt_key( bitand( shr( t, 16 ), 255 ) ), 24 )
                           , shl( p_encrypt_key( bitand( shr( t, 8  ), 255 ) ), 16 )
                           )
                    , bitor( shl( p_encrypt_key( bitand( t           , 255 ) ), 8 )
                           ,      p_encrypt_key( bitand( shr( t, 24 ), 255 ) )
                           )
                    );
          t := bitxor( t, rcon( r ) );
          r := r + 1;
        elsif ( Nk = 8 and n = 4 )
        then
          t := bitor( bitor( shl( p_encrypt_key( bitand( shr( t, 24 ), 255 ) ), 24 )
                           , shl( p_encrypt_key( bitand( shr( t, 16 ), 255 ) ), 16 )
                           )
                    , bitor( shl( p_encrypt_key( bitand( shr( t, 8  ), 255 ) ), 8 )
                           ,      p_encrypt_key( bitand( t           , 255 ) )
                           )
                    );
        end if;
        n := n -1;
        p_encrypt_key( 1280 + i ) := bitand( bitxor( p_encrypt_key( 1280 + i - Nk ), t ), bmax32 );
      end loop;
    end;
  --
    procedure aes_decrypt_key
      ( key varchar2
      , p_decrypt_key out nocopy tp_aes_tab
      )
  is
      Se tp_aes_tab;
      rek tp_aes_tab;
      rcon tp_aes_tab;
      SS varchar2(512);
      s1 number;
      s2 number;
      s3 number;
      i2 number;
      i4 number;
      i8 number;
      i9 number;
      ib number;
      id number;
      ie number;
      t number;
      Nk pls_integer;
      Nw pls_integer;
      n pls_integer;
      r pls_integer;
    begin
      SS := '637c777bf26b6fc53001672bfed7ab76ca82c97dfa5947f0add4a2af9ca472c0'
         || 'b7fd9326363ff7cc34a5e5f171d8311504c723c31896059a071280e2eb27b275'
         || '09832c1a1b6e5aa0523bd6b329e32f8453d100ed20fcb15b6acbbe394a4c58cf'
         || 'd0efaafb434d338545f9027f503c9fa851a3408f929d38f5bcb6da2110fff3d2'
         || 'cd0c13ec5f974417c4a77e3d645d197360814fdc222a908846eeb814de5e0bdb'
         || 'e0323a0a4906245cc2d3ac629195e479e7c8376d8dd54ea96c56f4ea657aae08'
         || 'ba78252e1ca6b4c6e8dd741f4bbd8b8a703eb5664803f60e613557b986c11d9e'
         || 'e1f8981169d98e949b1e87e9ce5528df8ca1890dbfe6426841992d0fb054bb16';
      for i in 0 .. 255
      loop
        s1 := to_number( substr( SS, i * 2 + 1, 2 ), 'XX' );
        i2 := i * 2;
        if i2 >= 256
        then
          i2 := bitxor( i2, 283 );
        end if;
        i4 := i2 * 2;
        if i4 >= 256
        then
          i4 := bitxor( i4, 283 );
        end if;
        i8 := i4 * 2;
        if i8 >= 256
        then
          i8 := bitxor( i8, 283 );
        end if;
        i9 := bitxor( i8, i );
        ib := bitxor( i9, i2 );
        id := bitxor( i9, i4 );
        ie := bitxor( bitxor( i8, i4 ), i2 );
        Se(i) := s1;
        p_decrypt_key( s1 ) := i;
        t := bitor( bitor( bitor( shl( ie, 24 ), shl( i9, 16 ) ), shl( id, 8 ) ), ib );
        p_decrypt_key( 256 + s1 ) := t;
        t := rol32( t, 24 );
        p_decrypt_key( 512 + s1 ) := t;
        t := rol32( t, 24 );
        p_decrypt_key( 768 + s1 ) := t;
        t := rol32( t, 24 );
        p_decrypt_key( 1024 + s1 ) := t;
      end loop;
  --
      t := 1;
      rcon(0) := shl( t, 24 );
      for i in 1 .. 9
      loop
        t := t * 2;
        if t >= 256
        then
          t := bitxor( t, 283 );
        end if;
        rcon(i) := shl( t, 24 );
      end loop;
      rcon(7) := - rcon(7);
      Nk := length( key ) / 8;
      Nw := 4 * ( Nk + 7 );
      for i in 0 .. Nk - 1
      loop
        rek(i) := to_number( substr( key, i * 8 + 1, 8 ), 'xxxxxxxx' );
      end loop;
      n := 0;
      r := 0;
      for i in Nk .. Nw - 1
      loop
        t := rek(i - 1);
        if n = 0
        then
          n := Nk;
          t := bitor( bitor( shl( Se( bitand( shr( t, 16 ), 255 ) ), 24 )
                           , shl( Se( bitand( shr( t, 8  ), 255 ) ), 16 )
                           )
                    , bitor( shl( Se( bitand( t           , 255 ) ), 8 )
                           ,      Se( bitand( shr( t, 24 ), 255 ) )
                           )
                    );
          t := bitxor( t, rcon( r ) );
          r := r + 1;
        elsif ( Nk = 8 and n = 4 )
        then
          t := bitor( bitor( shl( Se( bitand( shr( t, 24 ), 255 ) ), 24 )
                           , shl( Se( bitand( shr( t, 16 ), 255 ) ), 16 )
                           )
                    , bitor( shl( Se( bitand( shr( t, 8  ), 255 ) ), 8 )
                           ,      Se( bitand( t           , 255 ) )
                           )
                    );
        end if;
        n := n -1;
        rek(i) := bitand( bitxor( rek( i - Nk ), t ), bmax32 );
      end loop;
      for i in 0 .. 3
      loop
        p_decrypt_key( 1280 + i ) := rek(Nw - 4 + i);
      end loop;
      for i in 1 .. Nk + 5
      loop
        for j in 0 .. 3
        loop
          t:= rek( Nw - i * 4 - 4 + j );
          t := bitxor( bitxor( p_decrypt_key( 256 + bitand( Se( bitand( shr( t, 24 ), 255 ) ), 255 ) )
                             , p_decrypt_key( 512 + bitand( Se( bitand( shr( t, 16 ), 255 ) ), 255 ) )
                             )
                     , bitxor( p_decrypt_key( 768 + bitand( Se( bitand( shr( t, 8 ), 255 ) ), 255 ) )
                             , p_decrypt_key( 1024 + bitand( Se( bitand( t, 255 ) ), 255 ) )
                             )
                     );
          p_decrypt_key( 1280 + i * 4 + j ) := t;
        end loop;
      end loop;
      for i in Nw - 4 .. Nw - 1
      loop
        p_decrypt_key( 1280 + i ) := rek(i - Nw + 4);
      end loop;
    end;
  --
    function aes_encrypt
      ( src varchar2
      , klen pls_integer
      , p_decrypt_key tp_aes_tab
      )
    return raw
    is
      t0 number;
      t1 number;
      t2 number;
      t3 number;
      a0 number;
      a1 number;
      a2 number;
      a3 number;
      k pls_integer := 0;
  --
      function grv( a number, b number, c number, d number, v number )
      return varchar2
      is
        t number;
        rv varchar2(256);
      begin
        t := bitxor( p_decrypt_key( bitand( shr( a, 24 ), 255 ) ), shr( v, 24 ) );
        rv := substr( to_char( t, '0xxxxxxx' ), -2 );
        t := bitxor( p_decrypt_key( bitand( shr( b, 16 ), 255 ) ), shr( v, 16 ) );
        rv := rv || substr( to_char( t, '0xxxxxxx' ), -2 );
        t := bitxor( p_decrypt_key( bitand( shr( c, 8 ), 255 ) ), shr( v, 8 ) );
        rv := rv || substr( to_char( t, '0xxxxxxx' ), -2 );
        t := bitxor( p_decrypt_key( bitand( d, 255 ) ), v );
        return rv || substr( to_char( t, '0xxxxxxx' ), -2 );
      end;
    begin
      t0 := bitxor( to_number( substr( src,  1, 8 ), 'xxxxxxxx' ), p_decrypt_key( 1280 ) );
      t1 := bitxor( to_number( substr( src,  9, 8 ), 'xxxxxxxx' ), p_decrypt_key( 1281 ) );
      t2 := bitxor( to_number( substr( src, 17, 8 ), 'xxxxxxxx' ), p_decrypt_key( 1282 ) );
      t3 := bitxor( to_number( substr( src, 25, 8 ), 'xxxxxxxx' ), p_decrypt_key( 1283 ) );
      for i in 1 .. klen / 4 + 5
      loop
        k := k + 4;
        a0 := bitxor( bitxor( bitxor( p_decrypt_key( 256 + bitand( shr( t0, 24 ), 255 ) )
                                    , p_decrypt_key( 512 + bitand( shr( t1, 16 ), 255 ) )
                                    )
                            , bitxor( p_decrypt_key( 768 + bitand( shr( t2, 8 ), 255 ) )
                                    , p_decrypt_key( 1024 + bitand(    t3     , 255 ) )
                                    )
                            )
                    , p_decrypt_key( 1280 + i * 4 )
                    );
        a1 := bitxor( bitxor( bitxor( p_decrypt_key( 256 + bitand( shr( t1, 24 ), 255 ) )
                                    , p_decrypt_key( 512 + bitand( shr( t2, 16 ), 255 ) )
                                    )
                            , bitxor( p_decrypt_key( 768 + bitand( shr( t3, 8 ), 255 ) )
                                    , p_decrypt_key( 1024 + bitand(     t0     , 255 ) )
                                    )
                            )
                    , p_decrypt_key( 1280 + i * 4 + 1 )
                    );
        a2 := bitxor( bitxor( bitxor( p_decrypt_key( 256 + bitand( shr( t2, 24 ), 255 ) )
                                    , p_decrypt_key( 512 + bitand( shr( t3, 16 ), 255 ) )
                                    )
                            , bitxor( p_decrypt_key( 768 + bitand( shr( t0, 8 ), 255 ) )
                                    , p_decrypt_key( 1024 + bitand(     t1     , 255 ) )
                                    )
                            )
                    , p_decrypt_key( 1280 + i * 4 + 2 )
                    );
        a3 := bitxor( bitxor( bitxor( p_decrypt_key( 256 + bitand( shr( t3, 24 ), 255 ) )
                                    , p_decrypt_key( 512 + bitand( shr( t0, 16 ), 255 ) )
                                    )
                            , bitxor( p_decrypt_key( 768 + bitand( shr( t1, 8 ), 255 ) )
                                    , p_decrypt_key( 1024 + bitand(     t2     , 255 ) )
                                    )
                            )
                    , p_decrypt_key( 1280 + i * 4 + 3 )
                    );
        t0 := a0; t1 := a1; t2 := a2; t3 := a3;
      end loop;
      k := k + 4;
      return grv( t0, t1, t2, t3, p_decrypt_key( 1280 + k ) )
          || grv( t1, t2, t3, t0, p_decrypt_key( 1280 + k + 1 ) )
          || grv( t2, t3, t0, t1, p_decrypt_key( 1280 + k + 2 ) )
          || grv( t3, t0, t1, t2, p_decrypt_key( 1280 + k + 3 ) );
    end;
  --
    function aes_decrypt
      ( src varchar2
      , klen pls_integer
      , p_decrypt_key tp_aes_tab
      )
    return raw
    is
      t0 number;
      t1 number;
      t2 number;
      t3 number;
      a0 number;
      a1 number;
      a2 number;
      a3 number;
      k pls_integer := 0;
  --
      function grv( a number, b number, c number, d number, v number )
      return varchar2
      is
        t number;
        rv varchar2(256);
      begin
        t := bitxor( p_decrypt_key( bitand( shr( a, 24 ), 255 ) ), shr( v, 24 ) );
        rv := substr( to_char( t, '0xxxxxxx' ), -2 );
        t := bitxor( p_decrypt_key( bitand( shr( b, 16 ), 255 ) ), shr( v, 16 ) );
        rv := rv || substr( to_char( t, '0xxxxxxx' ), -2 );
        t := bitxor( p_decrypt_key( bitand( shr( c, 8 ), 255 ) ), shr( v, 8 ) );
        rv := rv || substr( to_char( t, '0xxxxxxx' ), -2 );
        t := bitxor( p_decrypt_key( bitand( d, 255 ) ), v );
        return rv || substr( to_char( t, '0xxxxxxx' ), -2 );
      end;
    begin
      t0 := bitxor( to_number( substr( src,  1, 8 ), 'xxxxxxxx' ), p_decrypt_key( 1280 ) );
      t1 := bitxor( to_number( substr( src,  9, 8 ), 'xxxxxxxx' ), p_decrypt_key( 1281 ) );
      t2 := bitxor( to_number( substr( src, 17, 8 ), 'xxxxxxxx' ), p_decrypt_key( 1282 ) );
      t3 := bitxor( to_number( substr( src, 25, 8 ), 'xxxxxxxx' ), p_decrypt_key( 1283 ) );
      for i in 1 .. klen / 4 + 5
      loop
        k := k + 4;
        a0 := bitxor( bitxor( bitxor( p_decrypt_key( 256 + bitand( shr( t0, 24 ), 255 ) )
                                    , p_decrypt_key( 512 + bitand( shr( t3, 16 ), 255 ) )
                                    )
                            , bitxor( p_decrypt_key( 768 + bitand( shr( t2, 8 ), 255 ) )
                                    , p_decrypt_key( 1024 + bitand(     t1     , 255 ) )
                                    )
                            )
                    , p_decrypt_key( 1280 + i * 4 )
                    );
        a1 := bitxor( bitxor( bitxor( p_decrypt_key( 256 + bitand( shr( t1, 24 ), 255 ) )
                                    , p_decrypt_key( 512 + bitand( shr( t0, 16 ), 255 ) )
                                    )
                            , bitxor( p_decrypt_key( 768 + bitand( shr( t3, 8 ), 255 ) )
                                    , p_decrypt_key( 1024 + bitand(     t2     , 255 ) )
                                    )
                            )
                    , p_decrypt_key( 1280 + i * 4 + 1 )
                    );
        a2 := bitxor( bitxor( bitxor( p_decrypt_key( 256 + bitand( shr( t2, 24 ), 255 ) )
                                    , p_decrypt_key( 512 + bitand( shr( t1, 16 ), 255 ) )
                                    )
                            , bitxor( p_decrypt_key( 768 + bitand( shr( t0, 8 ), 255 ) )
                                    , p_decrypt_key( 1024 + bitand(     t3     , 255 ) )
                                    )
                            )
                    , p_decrypt_key( 1280 + i * 4 + 2 )
                    );
        a3 := bitxor( bitxor( bitxor( p_decrypt_key( 256 + bitand( shr( t3, 24 ), 255 ) )
                                    , p_decrypt_key( 512 + bitand( shr( t2, 16 ), 255 ) )
                                    )
                            , bitxor( p_decrypt_key( 768 + bitand( shr( t1, 8 ), 255 ) )
                                    , p_decrypt_key( 1024 + bitand(     t0     , 255 ) )
                                    )
                            )
                    , p_decrypt_key( 1280 + i * 4 + 3 )
                    );
        t0 := a0; t1 := a1; t2 := a2; t3 := a3;
      end loop;
      k := k + 4;
      return grv( t0, t3, t2, t1, p_decrypt_key( 1280 + k ) )
          || grv( t1, t0, t3, t2, p_decrypt_key( 1280 + k + 1 ) )
          || grv( t2, t1, t0, t3, p_decrypt_key( 1280 + k + 2 ) )
          || grv( t3, t2, t1, t0, p_decrypt_key( 1280 + k + 3 ) );
    end;
  --
    procedure deskey( p_key raw, p_keys out tp_crypto, p_encrypt boolean )
    is
      bytebit tp_crypto := tp_crypto( 128, 64, 32, 16, 8, 4, 2, 1 );
      bigbyte tp_crypto := tp_crypto( to_number( '800000', 'XXXXXX' ), to_number( '400000', 'XXXXXX' ), to_number( '200000', 'XXXXXX' ), to_number( '100000', 'XXXXXX' )
                                    , to_number( '080000', 'XXXXXX' ), to_number( '040000', 'XXXXXX' ), to_number( '020000', 'XXXXXX' ), to_number( '010000', 'XXXXXX' )
                                    , to_number( '008000', 'XXXXXX' ), to_number( '004000', 'XXXXXX' ), to_number( '002000', 'XXXXXX' ), to_number( '001000', 'XXXXXX' )
                                    , to_number( '000800', 'XXXXXX' ), to_number( '000400', 'XXXXXX' ), to_number( '000200', 'XXXXXX' ), to_number( '000100', 'XXXXXX' )
                                    , to_number( '000080', 'XXXXXX' ), to_number( '000040', 'XXXXXX' ), to_number( '000020', 'XXXXXX' ), to_number( '000010', 'XXXXXX' )
                                    , to_number( '000008', 'XXXXXX' ), to_number( '000004', 'XXXXXX' ), to_number( '000002', 'XXXXXX' ), to_number( '000001', 'XXXXXX' )
                                    );
      pcl tp_crypto := tp_crypto( 56, 48, 40, 32, 24, 16,  8
                                ,  0, 57, 49, 41, 33, 25, 17
                                ,  9,  1, 58, 50, 42, 34, 26
                                , 18, 10,  2, 59, 51, 43, 35
                                , 62, 54, 46, 38, 30, 22, 14
                                ,  6, 61, 53, 45, 37, 29, 21
                                , 13,  5, 60, 52, 44, 36, 28
                                , 20, 12,  4, 27, 19, 11, 3
                                );
      pc2 tp_crypto := tp_crypto( 13, 16, 10, 23,  0,  4
                                ,  2, 27, 14,  5, 20,  9
                                , 22, 18, 11, 3 , 25,  7
                                , 15,  6, 26, 19, 12,  1
                                , 40, 51, 30, 36, 46, 54
                                , 29, 39, 50, 44, 32, 47
                                , 43, 48, 38, 55, 33, 52
                                , 45, 41, 49, 35, 28, 31
                                );
      totrot tp_crypto := tp_crypto( 1, 2, 4, 6, 8, 10, 12, 14
                                   , 15, 17, 19, 21, 23, 25, 27, 28
                                   );
      t_key tp_crypto := tp_crypto();
      pclm tp_crypto := tp_crypto();
      pcr tp_crypto := tp_crypto();
      kn tp_crypto := tp_crypto();
      t_l pls_integer;
      t_m pls_integer;
      t_n pls_integer;
      raw0 number;
      raw1 number;
      t_tmp number;
      rawi pls_integer;
      knli pls_integer;
    begin
  --
      if SP1 is null
      then
          SP1 := tp_crypto(
          to_number( '01010400', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '00010000', 'xxxxxxxx' ), to_number( '01010404', 'xxxxxxxx' ),
          to_number( '01010004', 'xxxxxxxx' ), to_number( '00010404', 'xxxxxxxx' ), to_number( '00000004', 'xxxxxxxx' ), to_number( '00010000', 'xxxxxxxx' ),
          to_number( '00000400', 'xxxxxxxx' ), to_number( '01010400', 'xxxxxxxx' ), to_number( '01010404', 'xxxxxxxx' ), to_number( '00000400', 'xxxxxxxx' ),
          to_number( '01000404', 'xxxxxxxx' ), to_number( '01010004', 'xxxxxxxx' ), to_number( '01000000', 'xxxxxxxx' ), to_number( '00000004', 'xxxxxxxx' ),
          to_number( '00000404', 'xxxxxxxx' ), to_number( '01000400', 'xxxxxxxx' ), to_number( '01000400', 'xxxxxxxx' ), to_number( '00010400', 'xxxxxxxx' ),
          to_number( '00010400', 'xxxxxxxx' ), to_number( '01010000', 'xxxxxxxx' ), to_number( '01010000', 'xxxxxxxx' ), to_number( '01000404', 'xxxxxxxx' ),
          to_number( '00010004', 'xxxxxxxx' ), to_number( '01000004', 'xxxxxxxx' ), to_number( '01000004', 'xxxxxxxx' ), to_number( '00010004', 'xxxxxxxx' ),
          to_number( '00000000', 'xxxxxxxx' ), to_number( '00000404', 'xxxxxxxx' ), to_number( '00010404', 'xxxxxxxx' ), to_number( '01000000', 'xxxxxxxx' ),
          to_number( '00010000', 'xxxxxxxx' ), to_number( '01010404', 'xxxxxxxx' ), to_number( '00000004', 'xxxxxxxx' ), to_number( '01010000', 'xxxxxxxx' ),
          to_number( '01010400', 'xxxxxxxx' ), to_number( '01000000', 'xxxxxxxx' ), to_number( '01000000', 'xxxxxxxx' ), to_number( '00000400', 'xxxxxxxx' ),
          to_number( '01010004', 'xxxxxxxx' ), to_number( '00010000', 'xxxxxxxx' ), to_number( '00010400', 'xxxxxxxx' ), to_number( '01000004', 'xxxxxxxx' ),
          to_number( '00000400', 'xxxxxxxx' ), to_number( '00000004', 'xxxxxxxx' ), to_number( '01000404', 'xxxxxxxx' ), to_number( '00010404', 'xxxxxxxx' ),
          to_number( '01010404', 'xxxxxxxx' ), to_number( '00010004', 'xxxxxxxx' ), to_number( '01010000', 'xxxxxxxx' ), to_number( '01000404', 'xxxxxxxx' ),
          to_number( '01000004', 'xxxxxxxx' ), to_number( '00000404', 'xxxxxxxx' ), to_number( '00010404', 'xxxxxxxx' ), to_number( '01010400', 'xxxxxxxx' ),
          to_number( '00000404', 'xxxxxxxx' ), to_number( '01000400', 'xxxxxxxx' ), to_number( '01000400', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ),
          to_number( '00010004', 'xxxxxxxx' ), to_number( '00010400', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '01010004', 'xxxxxxxx' )
      );
          SP2 := tp_crypto(
          to_number( '80108020', 'xxxxxxxx' ), to_number( '80008000', 'xxxxxxxx' ), to_number( '00008000', 'xxxxxxxx' ), to_number( '00108020', 'xxxxxxxx' ),
          to_number( '00100000', 'xxxxxxxx' ), to_number( '00000020', 'xxxxxxxx' ), to_number( '80100020', 'xxxxxxxx' ), to_number( '80008020', 'xxxxxxxx' ),
          to_number( '80000020', 'xxxxxxxx' ), to_number( '80108020', 'xxxxxxxx' ), to_number( '80108000', 'xxxxxxxx' ), to_number( '80000000', 'xxxxxxxx' ),
          to_number( '80008000', 'xxxxxxxx' ), to_number( '00100000', 'xxxxxxxx' ), to_number( '00000020', 'xxxxxxxx' ), to_number( '80100020', 'xxxxxxxx' ),
          to_number( '00108000', 'xxxxxxxx' ), to_number( '00100020', 'xxxxxxxx' ), to_number( '80008020', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ),
          to_number( '80000000', 'xxxxxxxx' ), to_number( '00008000', 'xxxxxxxx' ), to_number( '00108020', 'xxxxxxxx' ), to_number( '80100000', 'xxxxxxxx' ),
          to_number( '00100020', 'xxxxxxxx' ), to_number( '80000020', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '00108000', 'xxxxxxxx' ),
          to_number( '00008020', 'xxxxxxxx' ), to_number( '80108000', 'xxxxxxxx' ), to_number( '80100000', 'xxxxxxxx' ), to_number( '00008020', 'xxxxxxxx' ),
          to_number( '00000000', 'xxxxxxxx' ), to_number( '00108020', 'xxxxxxxx' ), to_number( '80100020', 'xxxxxxxx' ), to_number( '00100000', 'xxxxxxxx' ),
          to_number( '80008020', 'xxxxxxxx' ), to_number( '80100000', 'xxxxxxxx' ), to_number( '80108000', 'xxxxxxxx' ), to_number( '00008000', 'xxxxxxxx' ),
          to_number( '80100000', 'xxxxxxxx' ), to_number( '80008000', 'xxxxxxxx' ), to_number( '00000020', 'xxxxxxxx' ), to_number( '80108020', 'xxxxxxxx' ),
          to_number( '00108020', 'xxxxxxxx' ), to_number( '00000020', 'xxxxxxxx' ), to_number( '00008000', 'xxxxxxxx' ), to_number( '80000000', 'xxxxxxxx' ),
          to_number( '00008020', 'xxxxxxxx' ), to_number( '80108000', 'xxxxxxxx' ), to_number( '00100000', 'xxxxxxxx' ), to_number( '80000020', 'xxxxxxxx' ),
          to_number( '00100020', 'xxxxxxxx' ), to_number( '80008020', 'xxxxxxxx' ), to_number( '80000020', 'xxxxxxxx' ), to_number( '00100020', 'xxxxxxxx' ),
          to_number( '00108000', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '80008000', 'xxxxxxxx' ), to_number( '00008020', 'xxxxxxxx' ),
          to_number( '80000000', 'xxxxxxxx' ), to_number( '80100020', 'xxxxxxxx' ), to_number( '80108020', 'xxxxxxxx' ), to_number( '00108000', 'xxxxxxxx' )
      );
          SP3 := tp_crypto(
          to_number( '00000208', 'xxxxxxxx' ), to_number( '08020200', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '08020008', 'xxxxxxxx' ),
          to_number( '08000200', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '00020208', 'xxxxxxxx' ), to_number( '08000200', 'xxxxxxxx' ),
          to_number( '00020008', 'xxxxxxxx' ), to_number( '08000008', 'xxxxxxxx' ), to_number( '08000008', 'xxxxxxxx' ), to_number( '00020000', 'xxxxxxxx' ),
          to_number( '08020208', 'xxxxxxxx' ), to_number( '00020008', 'xxxxxxxx' ), to_number( '08020000', 'xxxxxxxx' ), to_number( '00000208', 'xxxxxxxx' ),
          to_number( '08000000', 'xxxxxxxx' ), to_number( '00000008', 'xxxxxxxx' ), to_number( '08020200', 'xxxxxxxx' ), to_number( '00000200', 'xxxxxxxx' ),
          to_number( '00020200', 'xxxxxxxx' ), to_number( '08020000', 'xxxxxxxx' ), to_number( '08020008', 'xxxxxxxx' ), to_number( '00020208', 'xxxxxxxx' ),
          to_number( '08000208', 'xxxxxxxx' ), to_number( '00020200', 'xxxxxxxx' ), to_number( '00020000', 'xxxxxxxx' ), to_number( '08000208', 'xxxxxxxx' ),
          to_number( '00000008', 'xxxxxxxx' ), to_number( '08020208', 'xxxxxxxx' ), to_number( '00000200', 'xxxxxxxx' ), to_number( '08000000', 'xxxxxxxx' ),
          to_number( '08020200', 'xxxxxxxx' ), to_number( '08000000', 'xxxxxxxx' ), to_number( '00020008', 'xxxxxxxx' ), to_number( '00000208', 'xxxxxxxx' ),
          to_number( '00020000', 'xxxxxxxx' ), to_number( '08020200', 'xxxxxxxx' ), to_number( '08000200', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ),
          to_number( '00000200', 'xxxxxxxx' ), to_number( '00020008', 'xxxxxxxx' ), to_number( '08020208', 'xxxxxxxx' ), to_number( '08000200', 'xxxxxxxx' ),
          to_number( '08000008', 'xxxxxxxx' ), to_number( '00000200', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '08020008', 'xxxxxxxx' ),
          to_number( '08000208', 'xxxxxxxx' ), to_number( '00020000', 'xxxxxxxx' ), to_number( '08000000', 'xxxxxxxx' ), to_number( '08020208', 'xxxxxxxx' ),
          to_number( '00000008', 'xxxxxxxx' ), to_number( '00020208', 'xxxxxxxx' ), to_number( '00020200', 'xxxxxxxx' ), to_number( '08000008', 'xxxxxxxx' ),
          to_number( '08020000', 'xxxxxxxx' ), to_number( '08000208', 'xxxxxxxx' ), to_number( '00000208', 'xxxxxxxx' ), to_number( '08020000', 'xxxxxxxx' ),
          to_number( '00020208', 'xxxxxxxx' ), to_number( '00000008', 'xxxxxxxx' ), to_number( '08020008', 'xxxxxxxx' ), to_number( '00020200', 'xxxxxxxx' )
      );
          SP4 := tp_crypto(
          to_number( '00802001', 'xxxxxxxx' ), to_number( '00002081', 'xxxxxxxx' ), to_number( '00002081', 'xxxxxxxx' ), to_number( '00000080', 'xxxxxxxx' ),
          to_number( '00802080', 'xxxxxxxx' ), to_number( '00800081', 'xxxxxxxx' ), to_number( '00800001', 'xxxxxxxx' ), to_number( '00002001', 'xxxxxxxx' ),
          to_number( '00000000', 'xxxxxxxx' ), to_number( '00802000', 'xxxxxxxx' ), to_number( '00802000', 'xxxxxxxx' ), to_number( '00802081', 'xxxxxxxx' ),
          to_number( '00000081', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '00800080', 'xxxxxxxx' ), to_number( '00800001', 'xxxxxxxx' ),
          to_number( '00000001', 'xxxxxxxx' ), to_number( '00002000', 'xxxxxxxx' ), to_number( '00800000', 'xxxxxxxx' ), to_number( '00802001', 'xxxxxxxx' ),
          to_number( '00000080', 'xxxxxxxx' ), to_number( '00800000', 'xxxxxxxx' ), to_number( '00002001', 'xxxxxxxx' ), to_number( '00002080', 'xxxxxxxx' ),
          to_number( '00800081', 'xxxxxxxx' ), to_number( '00000001', 'xxxxxxxx' ), to_number( '00002080', 'xxxxxxxx' ), to_number( '00800080', 'xxxxxxxx' ),
          to_number( '00002000', 'xxxxxxxx' ), to_number( '00802080', 'xxxxxxxx' ), to_number( '00802081', 'xxxxxxxx' ), to_number( '00000081', 'xxxxxxxx' ),
          to_number( '00800080', 'xxxxxxxx' ), to_number( '00800001', 'xxxxxxxx' ), to_number( '00802000', 'xxxxxxxx' ), to_number( '00802081', 'xxxxxxxx' ),
          to_number( '00000081', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '00802000', 'xxxxxxxx' ),
          to_number( '00002080', 'xxxxxxxx' ), to_number( '00800080', 'xxxxxxxx' ), to_number( '00800081', 'xxxxxxxx' ), to_number( '00000001', 'xxxxxxxx' ),
          to_number( '00802001', 'xxxxxxxx' ), to_number( '00002081', 'xxxxxxxx' ), to_number( '00002081', 'xxxxxxxx' ), to_number( '00000080', 'xxxxxxxx' ),
          to_number( '00802081', 'xxxxxxxx' ), to_number( '00000081', 'xxxxxxxx' ), to_number( '00000001', 'xxxxxxxx' ), to_number( '00002000', 'xxxxxxxx' ),
          to_number( '00800001', 'xxxxxxxx' ), to_number( '00002001', 'xxxxxxxx' ), to_number( '00802080', 'xxxxxxxx' ), to_number( '00800081', 'xxxxxxxx' ),
          to_number( '00002001', 'xxxxxxxx' ), to_number( '00002080', 'xxxxxxxx' ), to_number( '00800000', 'xxxxxxxx' ), to_number( '00802001', 'xxxxxxxx' ),
          to_number( '00000080', 'xxxxxxxx' ), to_number( '00800000', 'xxxxxxxx' ), to_number( '00002000', 'xxxxxxxx' ), to_number( '00802080', 'xxxxxxxx' )
      );
          SP5 := tp_crypto(
          to_number( '00000100', 'xxxxxxxx' ), to_number( '02080100', 'xxxxxxxx' ), to_number( '02080000', 'xxxxxxxx' ), to_number( '42000100', 'xxxxxxxx' ),
          to_number( '00080000', 'xxxxxxxx' ), to_number( '00000100', 'xxxxxxxx' ), to_number( '40000000', 'xxxxxxxx' ), to_number( '02080000', 'xxxxxxxx' ),
          to_number( '40080100', 'xxxxxxxx' ), to_number( '00080000', 'xxxxxxxx' ), to_number( '02000100', 'xxxxxxxx' ), to_number( '40080100', 'xxxxxxxx' ),
          to_number( '42000100', 'xxxxxxxx' ), to_number( '42080000', 'xxxxxxxx' ), to_number( '00080100', 'xxxxxxxx' ), to_number( '40000000', 'xxxxxxxx' ),
          to_number( '02000000', 'xxxxxxxx' ), to_number( '40080000', 'xxxxxxxx' ), to_number( '40080000', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ),
          to_number( '40000100', 'xxxxxxxx' ), to_number( '42080100', 'xxxxxxxx' ), to_number( '42080100', 'xxxxxxxx' ), to_number( '02000100', 'xxxxxxxx' ),
          to_number( '42080000', 'xxxxxxxx' ), to_number( '40000100', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '42000000', 'xxxxxxxx' ),
          to_number( '02080100', 'xxxxxxxx' ), to_number( '02000000', 'xxxxxxxx' ), to_number( '42000000', 'xxxxxxxx' ), to_number( '00080100', 'xxxxxxxx' ),
          to_number( '00080000', 'xxxxxxxx' ), to_number( '42000100', 'xxxxxxxx' ), to_number( '00000100', 'xxxxxxxx' ), to_number( '02000000', 'xxxxxxxx' ),
          to_number( '40000000', 'xxxxxxxx' ), to_number( '02080000', 'xxxxxxxx' ), to_number( '42000100', 'xxxxxxxx' ), to_number( '40080100', 'xxxxxxxx' ),
          to_number( '02000100', 'xxxxxxxx' ), to_number( '40000000', 'xxxxxxxx' ), to_number( '42080000', 'xxxxxxxx' ), to_number( '02080100', 'xxxxxxxx' ),
          to_number( '40080100', 'xxxxxxxx' ), to_number( '00000100', 'xxxxxxxx' ), to_number( '02000000', 'xxxxxxxx' ), to_number( '42080000', 'xxxxxxxx' ),
          to_number( '42080100', 'xxxxxxxx' ), to_number( '00080100', 'xxxxxxxx' ), to_number( '42000000', 'xxxxxxxx' ), to_number( '42080100', 'xxxxxxxx' ),
          to_number( '02080000', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '40080000', 'xxxxxxxx' ), to_number( '42000000', 'xxxxxxxx' ),
          to_number( '00080100', 'xxxxxxxx' ), to_number( '02000100', 'xxxxxxxx' ), to_number( '40000100', 'xxxxxxxx' ), to_number( '00080000', 'xxxxxxxx' ),
          to_number( '00000000', 'xxxxxxxx' ), to_number( '40080000', 'xxxxxxxx' ), to_number( '02080100', 'xxxxxxxx' ), to_number( '40000100', 'xxxxxxxx' )
      );
          SP6 := tp_crypto(
          to_number( '20000010', 'xxxxxxxx' ), to_number( '20400000', 'xxxxxxxx' ), to_number( '00004000', 'xxxxxxxx' ), to_number( '20404010', 'xxxxxxxx' ),
          to_number( '20400000', 'xxxxxxxx' ), to_number( '00000010', 'xxxxxxxx' ), to_number( '20404010', 'xxxxxxxx' ), to_number( '00400000', 'xxxxxxxx' ),
          to_number( '20004000', 'xxxxxxxx' ), to_number( '00404010', 'xxxxxxxx' ), to_number( '00400000', 'xxxxxxxx' ), to_number( '20000010', 'xxxxxxxx' ),
          to_number( '00400010', 'xxxxxxxx' ), to_number( '20004000', 'xxxxxxxx' ), to_number( '20000000', 'xxxxxxxx' ), to_number( '00004010', 'xxxxxxxx' ),
          to_number( '00000000', 'xxxxxxxx' ), to_number( '00400010', 'xxxxxxxx' ), to_number( '20004010', 'xxxxxxxx' ), to_number( '00004000', 'xxxxxxxx' ),
          to_number( '00404000', 'xxxxxxxx' ), to_number( '20004010', 'xxxxxxxx' ), to_number( '00000010', 'xxxxxxxx' ), to_number( '20400010', 'xxxxxxxx' ),
          to_number( '20400010', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '00404010', 'xxxxxxxx' ), to_number( '20404000', 'xxxxxxxx' ),
          to_number( '00004010', 'xxxxxxxx' ), to_number( '00404000', 'xxxxxxxx' ), to_number( '20404000', 'xxxxxxxx' ), to_number( '20000000', 'xxxxxxxx' ),
          to_number( '20004000', 'xxxxxxxx' ), to_number( '00000010', 'xxxxxxxx' ), to_number( '20400010', 'xxxxxxxx' ), to_number( '00404000', 'xxxxxxxx' ),
          to_number( '20404010', 'xxxxxxxx' ), to_number( '00400000', 'xxxxxxxx' ), to_number( '00004010', 'xxxxxxxx' ), to_number( '20000010', 'xxxxxxxx' ),
          to_number( '00400000', 'xxxxxxxx' ), to_number( '20004000', 'xxxxxxxx' ), to_number( '20000000', 'xxxxxxxx' ), to_number( '00004010', 'xxxxxxxx' ),
          to_number( '20000010', 'xxxxxxxx' ), to_number( '20404010', 'xxxxxxxx' ), to_number( '00404000', 'xxxxxxxx' ), to_number( '20400000', 'xxxxxxxx' ),
          to_number( '00404010', 'xxxxxxxx' ), to_number( '20404000', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '20400010', 'xxxxxxxx' ),
          to_number( '00000010', 'xxxxxxxx' ), to_number( '00004000', 'xxxxxxxx' ), to_number( '20400000', 'xxxxxxxx' ), to_number( '00404010', 'xxxxxxxx' ),
          to_number( '00004000', 'xxxxxxxx' ), to_number( '00400010', 'xxxxxxxx' ), to_number( '20004010', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ),
          to_number( '20404000', 'xxxxxxxx' ), to_number( '20000000', 'xxxxxxxx' ), to_number( '00400010', 'xxxxxxxx' ), to_number( '20004010', 'xxxxxxxx' )
      );
          SP7 := tp_crypto(
          to_number( '00200000', 'xxxxxxxx' ), to_number( '04200002', 'xxxxxxxx' ), to_number( '04000802', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ),
          to_number( '00000800', 'xxxxxxxx' ), to_number( '04000802', 'xxxxxxxx' ), to_number( '00200802', 'xxxxxxxx' ), to_number( '04200800', 'xxxxxxxx' ),
          to_number( '04200802', 'xxxxxxxx' ), to_number( '00200000', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '04000002', 'xxxxxxxx' ),
          to_number( '00000002', 'xxxxxxxx' ), to_number( '04000000', 'xxxxxxxx' ), to_number( '04200002', 'xxxxxxxx' ), to_number( '00000802', 'xxxxxxxx' ),
          to_number( '04000800', 'xxxxxxxx' ), to_number( '00200802', 'xxxxxxxx' ), to_number( '00200002', 'xxxxxxxx' ), to_number( '04000800', 'xxxxxxxx' ),
          to_number( '04000002', 'xxxxxxxx' ), to_number( '04200000', 'xxxxxxxx' ), to_number( '04200800', 'xxxxxxxx' ), to_number( '00200002', 'xxxxxxxx' ),
          to_number( '04200000', 'xxxxxxxx' ), to_number( '00000800', 'xxxxxxxx' ), to_number( '00000802', 'xxxxxxxx' ), to_number( '04200802', 'xxxxxxxx' ),
          to_number( '00200800', 'xxxxxxxx' ), to_number( '00000002', 'xxxxxxxx' ), to_number( '04000000', 'xxxxxxxx' ), to_number( '00200800', 'xxxxxxxx' ),
          to_number( '04000000', 'xxxxxxxx' ), to_number( '00200800', 'xxxxxxxx' ), to_number( '00200000', 'xxxxxxxx' ), to_number( '04000802', 'xxxxxxxx' ),
          to_number( '04000802', 'xxxxxxxx' ), to_number( '04200002', 'xxxxxxxx' ), to_number( '04200002', 'xxxxxxxx' ), to_number( '00000002', 'xxxxxxxx' ),
          to_number( '00200002', 'xxxxxxxx' ), to_number( '04000000', 'xxxxxxxx' ), to_number( '04000800', 'xxxxxxxx' ), to_number( '00200000', 'xxxxxxxx' ),
          to_number( '04200800', 'xxxxxxxx' ), to_number( '00000802', 'xxxxxxxx' ), to_number( '00200802', 'xxxxxxxx' ), to_number( '04200800', 'xxxxxxxx' ),
          to_number( '00000802', 'xxxxxxxx' ), to_number( '04000002', 'xxxxxxxx' ), to_number( '04200802', 'xxxxxxxx' ), to_number( '04200000', 'xxxxxxxx' ),
          to_number( '00200800', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '00000002', 'xxxxxxxx' ), to_number( '04200802', 'xxxxxxxx' ),
          to_number( '00000000', 'xxxxxxxx' ), to_number( '00200802', 'xxxxxxxx' ), to_number( '04200000', 'xxxxxxxx' ), to_number( '00000800', 'xxxxxxxx' ),
          to_number( '04000002', 'xxxxxxxx' ), to_number( '04000800', 'xxxxxxxx' ), to_number( '00000800', 'xxxxxxxx' ), to_number( '00200002', 'xxxxxxxx' )
      );
          SP8 := tp_crypto(
          to_number( '10001040', 'xxxxxxxx' ), to_number( '00001000', 'xxxxxxxx' ), to_number( '00040000', 'xxxxxxxx' ), to_number( '10041040', 'xxxxxxxx' ),
          to_number( '10000000', 'xxxxxxxx' ), to_number( '10001040', 'xxxxxxxx' ), to_number( '00000040', 'xxxxxxxx' ), to_number( '10000000', 'xxxxxxxx' ),
          to_number( '00040040', 'xxxxxxxx' ), to_number( '10040000', 'xxxxxxxx' ), to_number( '10041040', 'xxxxxxxx' ), to_number( '00041000', 'xxxxxxxx' ),
          to_number( '10041000', 'xxxxxxxx' ), to_number( '00041040', 'xxxxxxxx' ), to_number( '00001000', 'xxxxxxxx' ), to_number( '00000040', 'xxxxxxxx' ),
          to_number( '10040000', 'xxxxxxxx' ), to_number( '10000040', 'xxxxxxxx' ), to_number( '10001000', 'xxxxxxxx' ), to_number( '00001040', 'xxxxxxxx' ),
          to_number( '00041000', 'xxxxxxxx' ), to_number( '00040040', 'xxxxxxxx' ), to_number( '10040040', 'xxxxxxxx' ), to_number( '10041000', 'xxxxxxxx' ),
          to_number( '00001040', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ), to_number( '10040040', 'xxxxxxxx' ),
          to_number( '10000040', 'xxxxxxxx' ), to_number( '10001000', 'xxxxxxxx' ), to_number( '00041040', 'xxxxxxxx' ), to_number( '00040000', 'xxxxxxxx' ),
          to_number( '00041040', 'xxxxxxxx' ), to_number( '00040000', 'xxxxxxxx' ), to_number( '10041000', 'xxxxxxxx' ), to_number( '00001000', 'xxxxxxxx' ),
          to_number( '00000040', 'xxxxxxxx' ), to_number( '10040040', 'xxxxxxxx' ), to_number( '00001000', 'xxxxxxxx' ), to_number( '00041040', 'xxxxxxxx' ),
          to_number( '10001000', 'xxxxxxxx' ), to_number( '00000040', 'xxxxxxxx' ), to_number( '10000040', 'xxxxxxxx' ), to_number( '10040000', 'xxxxxxxx' ),
          to_number( '10040040', 'xxxxxxxx' ), to_number( '10000000', 'xxxxxxxx' ), to_number( '00040000', 'xxxxxxxx' ), to_number( '10001040', 'xxxxxxxx' ),
          to_number( '00000000', 'xxxxxxxx' ), to_number( '10041040', 'xxxxxxxx' ), to_number( '00040040', 'xxxxxxxx' ), to_number( '10000040', 'xxxxxxxx' ),
          to_number( '10040000', 'xxxxxxxx' ), to_number( '10001000', 'xxxxxxxx' ), to_number( '10001040', 'xxxxxxxx' ), to_number( '00000000', 'xxxxxxxx' ),
          to_number( '10041040', 'xxxxxxxx' ), to_number( '00041000', 'xxxxxxxx' ), to_number( '00041000', 'xxxxxxxx' ), to_number( '00001040', 'xxxxxxxx' ),
          to_number( '00001040', 'xxxxxxxx' ), to_number( '00040040', 'xxxxxxxx' ), to_number( '10000000', 'xxxxxxxx' ), to_number( '10041000', 'xxxxxxxx' )
      );
      end if;
  --
      t_key.extend(8);
      for i in 1 .. 8
      loop
       t_key(i) := to_number( utl_raw.substr( p_key, i, 1 ), 'XX' );
      end loop;
      pclm.extend(56);
      for j in 1 .. 56
      loop
        pclm(j) := sign( bitand( t_key( trunc( pcl( j ) / 8 ) + 1 ), bytebit( bitand( pcl( j ), 7 ) + 1 ) ) );
      end loop;
      kn.extend(32);
      pcr.extend(56);
      for i in 0 .. 15
      loop
        t_m := case when p_encrypt then i else 15 - i end * 2;
        t_n := t_m + 1;
        kn(t_m+1) := 0;
        kn(t_n+1) := 0;
        for j in 0 .. 27
        loop
          t_l := j + totrot(i+1);
          if t_l < 28
          then
            pcr(j+1) := pclm( t_l + 1 );
          else
            pcr(j+1) := pclm( t_l - 28 + 1 );
          end if;
        end loop;
        for j in 28 .. 55
        loop
          t_l := j + totrot(i+1);
          if t_l < 56
          then
            pcr(j+1) := pclm( t_l + 1 );
          else
            pcr(j+1) := pclm( t_l - 28 + 1 );
          end if;
        end loop;
        for j in 0 .. 23
        loop
          if pcr( pc2( j + 1 ) + 1 ) != 0
          then
            kn( t_m + 1 ) := bitor32( kn( t_m + 1 ), bigbyte( j + 1 ) );
          end if;
          if pcr( pc2( j + 24 + 1 ) + 1 ) != 0
          then
            kn( t_n + 1 ) := bitor32( kn( t_n + 1 ), bigbyte( j + 1 ) );
          end if;
        end loop;
      end loop;
  --
      p_keys := tp_crypto();
      p_keys.extend(32);
      rawi := 1;
      knli := 1;
      for i in 0 .. 15
      loop
        raw0 := kn(rawi);
        rawi := rawi + 1;
        raw1 := kn(rawi);
        rawi := rawi + 1;
        t_tmp := bitand( raw0, to_number( 'fc0000', 'xxxxxx' ) ) * 64;
        t_tmp := bitor32( t_tmp, bitand( raw0, to_number( '0fc0', 'xxxx' ) ) * 1024 );
        t_tmp := bitor32( t_tmp, bitand( raw1, to_number( 'fc0000', 'xxxxxx' ) ) / 1024 );
        t_tmp := bitor32( t_tmp, bitand( raw1, to_number( '0fc0', 'xxxx' ) ) / 64 );
        p_keys(knli) := t_tmp;
        knli := knli + 1;
        t_tmp := bitand( raw0, to_number( '03f000', 'xxxxxx' ) ) * 4096;
        t_tmp := bitor32( t_tmp, bitand( raw0, to_number( '3f', 'xx' ) ) * 65536 );
        t_tmp := bitor32( t_tmp, bitand( raw1, to_number( '03f000', 'xxxxxx' ) ) / 16 );
        t_tmp := bitor32( t_tmp, bitand( raw1, to_number( '3f', 'xx' ) ) );
        p_keys(knli) := t_tmp;
        knli := knli + 1;
      end loop;
    end;
  --
    function des( p_block varchar2, p_keys tp_crypto )
    return varchar2
    is
      t_left  integer;
      t_right integer;
      t_tmp   integer;
      t_fval  integer;
    begin
      t_left := to_number( substr( p_block, 1, 8 ), 'XXXXXXXX' );
      t_right := to_number( substr( p_block, 9, 8 ), 'XXXXXXXX' );
      t_tmp := bitand( bitxor32( shr( t_left, 4 ), t_right ), to_number( '0f0f0f0f', 'xxxxxxxx' ) );
      t_right := bitxor32( t_right, t_tmp );
      t_left := bitxor32( t_left, shl( t_tmp, 4 ) );
      t_tmp := bitand( bitxor32( shr( t_left, 16 ), t_right ), to_number( '0000ffff', 'xxxxxxxx' ) );
      t_right := bitxor32( t_right, t_tmp );
      t_left := bitxor32( t_left, shl( t_tmp, 16 ) );
      t_tmp := bitand( bitxor32( shr( t_right, 2 ), t_left ), to_number( '33333333', 'xxxxxxxx' ) );
      t_right := bitxor32( t_right, shl( t_tmp, 2 ) );
      t_left := bitxor32( t_left, t_tmp );
      t_tmp := bitand( bitxor32( shr( t_right, 8 ), t_left ), to_number( '00ff00ff', 'xxxxxxxx' ) );
      t_right := bitxor32( t_right, shl( t_tmp, 8 ) );
      t_right := t_right * 2 + sign( bitand( t_right, 2147483648 ) );
      t_left := bitxor32( t_left, t_tmp );
      t_tmp := bitand( bitxor32( t_right , t_left ), to_number( 'aaaaaaaa', 'xxxxxxxx' ) );
      t_right := bitxor32( t_right, t_tmp );
      t_left := bitxor32( t_left, t_tmp );
      t_left := t_left * 2 + sign( bitand( t_left, 2147483648 ) );
  --
      for i in 1 .. 8
      loop
        t_tmp := bitor32( shl( t_right, 28 ), shr( t_right, 4 ) );
        t_tmp := bitxor32( t_tmp, p_keys( i * 4 - 3 ) );
        t_fval := SP7( bitand( t_tmp, 63 ) + 1 );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP5( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP3( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP1( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := bitxor32( t_right, p_keys( i * 4 - 2 ) );
        t_fval := bitor32( t_fval, SP8( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP6( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP4( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP2( bitand( t_tmp, 63 ) + 1 ) );
        t_left := bitxor32( t_left, t_fval );
        t_tmp := bitor32( shl( t_left, 28 ), shr( t_left, 4 ) );
        t_tmp := bitxor32( t_tmp, p_keys( i * 4 - 1 ) );
        t_fval := SP7( bitand( t_tmp, 63 ) + 1 );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP5( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP3( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP1( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := bitxor32( t_left, p_keys( i * 4 ) );
        t_fval := bitor32( t_fval, SP8( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP6( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP4( bitand( t_tmp, 63 ) + 1 ) );
        t_tmp := shr( t_tmp, 8 );
        t_fval := bitor32( t_fval, SP2( bitand( t_tmp, 63 ) + 1 ) );
        t_right := bitxor32( t_right, t_fval );
      end loop;
  --
      t_right := shl( t_right, 31 ) + shr( t_right, 1 );
      t_tmp := bitand( bitxor32( t_right , t_left ), to_number( 'aaaaaaaa', 'xxxxxxxx' ) );
      t_right := bitxor32( t_right, t_tmp );
      t_left := bitxor32( t_left, t_tmp );
      t_left := shl( t_left, 31 ) + shr( t_left, 1 );
      t_tmp := bitand( bitxor32( shr( t_left, 8 ), t_right ), to_number( '00ff00ff', 'xxxxxxxx' ) );
      t_right := bitxor32( t_right, t_tmp );
      t_left := bitxor32( t_left, shl( t_tmp, 8 ) );
      t_tmp := bitand( bitxor32( shr( t_left, 2 ), t_right ), to_number( '33333333', 'xxxxxxxx' ) );
      t_right := bitxor32( t_right, t_tmp );
      t_left := bitxor32( t_left, shl( t_tmp, 2 ) );
      t_tmp := bitand( bitxor32( shr( t_right, 16 ), t_left ), to_number( '0000ffff', 'xxxxxxxx' ) );
      t_right := bitxor32( t_right, shl( t_tmp, 16 ) );
      t_left := bitxor32( t_left, t_tmp );
      t_tmp := bitand( bitxor32( shr( t_right, 4 ), t_left ), to_number( '0f0f0f0f', 'xxxxxxxx' ) );
      t_right := bitxor32( t_right, shl( t_tmp, 4 ) );
      t_left := bitxor32( t_left, t_tmp );
  --
      return to_char( t_right, 'fm0XXXXXXX' ) || to_char( t_left, 'fm0XXXXXXX' );
    end;
  --
    function encrypt__rc4( src raw, key raw )
    return raw
    is
      type tp_arcfour_sbox is table of pls_integer index by pls_integer;
      type tp_arcfour is record
        (  s tp_arcfour_sbox
        ,  i pls_integer
        ,  j pls_integer
        );
      t_tmp pls_integer;
      t_s2 tp_arcfour_sbox;
      t_arcfour tp_arcfour;
      t_encr raw(32767);
    begin
      for  i in 0 .. 255
      loop
        t_arcfour.s(i) :=  i;
      end  loop;
      for  i in 0 .. 255
      loop
        t_s2(i) := to_number( utl_raw.substr( key, mod( i, utl_raw.length( key ) ) + 1, 1 ), 'XX' );
      end  loop;
      t_arcfour.j  := 0;
      for  i in 0 .. 255
      loop
        t_arcfour.j := mod( t_arcfour.j +  t_arcfour.s(i) + t_s2(i), 256 );
        t_tmp := t_arcfour.s(i);
        t_arcfour.s(i) :=  t_arcfour.s( t_arcfour.j );
        t_arcfour.s( t_arcfour.j ) := t_tmp;
      end  loop;
      t_arcfour.i  := 0;
      t_arcfour.j  := 0;
  --
      for  i in 1 .. utl_raw.length( src )
      loop
        t_arcfour.i := bitand( t_arcfour.i + 1, 255 );
        t_arcfour.j := bitand( t_arcfour.j + t_arcfour.s(  t_arcfour.i ), 255 );
        t_tmp := t_arcfour.s( t_arcfour.i  );
        t_arcfour.s( t_arcfour.i ) := t_arcfour.s( t_arcfour.j );
        t_arcfour.s( t_arcfour.j ) := t_tmp;
        t_encr := utl_raw.concat( t_encr
                                , to_char( t_arcfour.s( bitand( t_arcfour.s( t_arcfour.i ) + t_arcfour.s( t_arcfour.j ), 255 ) ), 'fm0x' )
                                );
      end  loop;
      return utl_raw.bit_xor( src, t_encr );
    end;
  --
    function encrypt( src raw, typ pls_integer, key raw, iv raw := null )
    return raw
    is
      t_keys tp_crypto;
      t_keys2 tp_crypto;
      t_keys3 tp_crypto;
      t_encrypt_key tp_aes_tab;
      t_idx pls_integer;
      t_len pls_integer;
      t_tmp varchar2(32766);
      t_tmp2 varchar2(32766);
      t_encr raw(32767);
      t_plain raw(32767);
      t_padding raw(65);
      t_pad pls_integer;
      t_iv raw(64);
      t_raw raw(64);
      t_bs pls_integer := 8;
      t_bs2 pls_integer;
      function encr( p raw )
      return raw
      is
        tmp raw(100);
      begin
        case bitand( typ, 15 )
          when gc_encrypt_3des then
            tmp := des( des( des( p, t_keys ), t_keys2 ), t_keys3 );
          when gc_encrypt_des then
            tmp := des( p, t_keys );
          when gc_encrypt_3des_2key then
            tmp := des( des( des( p, t_keys ), t_keys2 ), t_keys3 );
          when gc_encrypt_aes then
            tmp := aes_encrypt( p, utl_raw.length( key ), t_encrypt_key );
          when gc_encrypt_aes128 then
            tmp := aes_encrypt( p, 16, t_encrypt_key );
          when gc_encrypt_aes192 then
            tmp := aes_encrypt( p, 24, t_encrypt_key );
          when gc_encrypt_aes256 then
            tmp := aes_encrypt( p, 32, t_encrypt_key );
          else
            tmp := p;
        end case;
        return tmp;
      end;
    begin
      if bitand( typ, 255 ) = gc_ENCRYPT_RC4
      then
        return encrypt__rc4( src, key );
      end if;
      case bitand( typ, 15 )
        when gc_encrypt_3des then
          deskey( utl_raw.substr( key, 1, 8 ), t_keys, true );
          deskey( utl_raw.substr( key, 9, 8 ), t_keys2, false );
          deskey( utl_raw.substr( key, 17, 8 ), t_keys3, true );
        when gc_encrypt_des then
          deskey( utl_raw.substr( key, 1, 8 ), t_keys, true );
        when gc_encrypt_3des_2key then
          deskey( utl_raw.substr( key, 1, 8 ), t_keys, true );
          deskey( utl_raw.substr( key, 9, 8 ), t_keys2, false );
          t_keys3 := t_keys;
        when gc_encrypt_aes then
          t_bs := 16;
          aes_encrypt_key( key, t_encrypt_key  );
        when gc_encrypt_aes128 then
          t_bs := 16;
          aes_encrypt_key( key, t_encrypt_key  );
        when gc_encrypt_aes192 then
          t_bs := 16;
          aes_encrypt_key( key, t_encrypt_key  );
        when gc_encrypt_aes256 then
          t_bs := 16;
          aes_encrypt_key( key, t_encrypt_key  );
        else
          null;
      end case;
      case bitand( typ, 61440 )
        when gc_PAD_NONE then
          t_pad := mod( utl_raw.length( src ), t_bs );
          if t_pad > 0
          then
            t_padding := utl_raw.copies( '00', t_bs - t_pad );
          end if;
        when gc_pad_pkcs5 then
          t_pad := t_bs - mod( utl_raw.length( src ), t_bs );
          t_padding := utl_raw.copies( to_char( t_pad, 'fm0X' ), t_pad );
        when gc_pad_oneandzeroes then -- OneAndZeroes Padding, ISO/IEC 7816-4
          t_pad := t_bs - 1 - mod( utl_raw.length( src ), t_bs );
          if t_pad = 0
          then
            t_padding := '80';
          else
            t_padding := utl_raw.concat( '80', utl_raw.copies( '00', t_pad ) );
          end if;
        when gc_pad_ansi_x923 then -- ANSI X.923
          t_pad := t_bs - 1 - mod( utl_raw.length( src ), t_bs );
          if t_pad = 0
          then
            t_pad := t_bs;
          end if;
          t_padding := utl_raw.concat( utl_raw.copies( '00', t_pad ), to_char( t_pad, 'fm0X' ) );
        when gc_PAD_ZERO then -- zero padding
          t_pad := mod( utl_raw.length( src ), t_bs );
          if t_pad > 0
          then
            t_padding := utl_raw.copies( '00', t_bs - t_pad );
          end if;
        when gc_PAD_ORCL then -- zero padding
          t_pad := mod( utl_raw.length( src ), t_bs );
          if t_pad > 0
          then
            t_padding := utl_raw.copies( '00', t_bs - t_pad );
          end if;
        else
          null;
      end case;
      t_bs2 := t_bs * 2;
      t_plain := utl_raw.concat( src, t_padding );
      t_idx := 1;
      t_len := utl_raw.length( t_plain );
      t_iv := coalesce( iv, utl_raw.copies( '0', t_bs ) );
      while t_idx <= t_len
      loop
        t_tmp := rawtohex( utl_raw.substr( t_plain, t_idx, least( 16376, t_len - t_idx + 1 ) ) );
        t_idx := t_idx + 16376;
        t_tmp2 := null;
        for i in 0 .. trunc( length( t_tmp ) / t_bs2 ) - 1
        loop
          case bitand( typ, 3840 )
            when gc_chain_cbc then
              t_raw := utl_raw.bit_xor( substr( t_tmp, i * t_bs2 + 1, t_bs2 ), t_iv );
              t_raw := encr( t_raw );
              t_iv := t_raw;
            when gc_chain_cfb then
              t_iv := encr( t_iv );
              t_raw := utl_raw.bit_xor( substr( t_tmp, i * t_bs2 + 1, t_bs2 ), t_iv );
              t_iv := t_raw;
            when gc_chain_ecb then
              t_raw := encr( substr( t_tmp, i * t_bs2 + 1, t_bs2 ) );
            when gc_chain_ofb then
  $IF DBMS_DB_VERSION.VER_LE_10 $THEN
              t_raw := encr( substr( t_tmp, i * t_bs2 + 1, t_bs2 ) );
  $ELSIF DBMS_DB_VERSION.VER_LE_11 $THEN
              t_raw := encr( substr( t_tmp, i * t_bs2 + 1, t_bs2 ) );
  $ELSE
              t_iv := encr( t_iv );
              t_raw := utl_raw.bit_xor( substr( t_tmp, i * t_bs2 + 1, t_bs2 ), t_iv );
  $end
            when gc_CHAIN_OFB_REAL then
              t_iv := encr( t_iv );
              t_raw := utl_raw.bit_xor( substr( t_tmp, i * t_bs2 + 1, t_bs2 ), t_iv );
            else
              null;
          end case;
          t_tmp2 := t_tmp2 || t_raw;
        end loop;
        t_encr := utl_raw.concat( t_encr, hextoraw( t_tmp2 ) );
      end loop;
      case bitand( typ, 61440 )
        when gc_PAD_NONE then
          t_encr := utl_raw.substr( t_encr, 1, utl_raw.length( src ) );
        when gc_PAD_ORCL then
          t_encr := utl_raw.concat( t_encr, to_char( t_bs - mod( utl_raw.length( src ) - 1, t_bs ), 'fm0X' ) );
        else
          null;
      end case;
      return t_encr;
    end;
  --
    function decrypt( src raw, typ pls_integer, key raw, iv raw := null )
    return raw
    is
      t_keys tp_crypto;
      t_keys2 tp_crypto;
      t_keys3 tp_crypto;
      t_decrypt_key tp_aes_tab;
      t_idx pls_integer;
      t_len pls_integer;
      t_tmp varchar2(32766);
      t_tmp2 varchar2(32766);
      t_decr raw(32767);
      t_pad pls_integer;
      t_iv raw(64);
      t_raw raw(64);
      t_bs pls_integer := 8;
      t_bs2 pls_integer;
      t_fb boolean;
      function decr( p raw )
      return raw
      is
        tmp raw(100);
      begin
        case bitand( typ, 15 )
          when gc_encrypt_3des then
            tmp := des( des( des( p, t_keys3 ), t_keys2 ), t_keys );
          when gc_encrypt_des then
            tmp := des( p, t_keys );
          when gc_encrypt_3des_2key then
            tmp := des( des( des( p, t_keys3 ), t_keys2 ), t_keys );
          when gc_encrypt_aes then
            tmp := aes_decrypt( p, utl_raw.length( key ), t_decrypt_key );
          when gc_encrypt_aes128 then
            tmp := aes_decrypt( p, 16, t_decrypt_key );
          when gc_encrypt_aes192 then
            tmp := aes_decrypt( p, 24, t_decrypt_key );
          when gc_encrypt_aes256 then
            tmp := aes_decrypt( p, 32, t_decrypt_key );
          else
            tmp := p;
        end case;
        return tmp;
      end;
    begin
      if bitand( typ, 255 ) = gc_ENCRYPT_RC4
      then
        return encrypt__rc4( src, key );
      end if;
  $if dbms_db_version.ver_le_10 $then
      t_fb := bitand( typ, 3840 ) in ( gc_CHAIN_CFB, gc_CHAIN_OFB_REAL );
  $elsif dbms_db_version.ver_le_11 $then
      t_fb := bitand( typ, 3840 ) in ( gc_CHAIN_CFB, gc_CHAIN_OFB_REAL );
  $else
      t_fb := bitand( typ, 3840 ) in ( gc_CHAIN_CFB, gc_CHAIN_OFB, gc_CHAIN_OFB_REAL );
  $END
      case bitand( typ, 15 )
        when gc_encrypt_3des then
          deskey( utl_raw.substr( key, 1, 8 ), t_keys, t_fb );
          deskey( utl_raw.substr( key, 9, 8 ), t_keys2, not t_fb );
          deskey( utl_raw.substr( key, 17, 8 ), t_keys3, t_fb );
        when gc_encrypt_des then
          deskey( utl_raw.substr( key, 1, 8 ), t_keys, t_fb );
        when gc_encrypt_3des_2key then
          deskey( utl_raw.substr( key, 1, 8 ), t_keys, t_fb );
          deskey( utl_raw.substr( key, 9, 8 ), t_keys2, not t_fb );
          t_keys3 := t_keys;
        when gc_encrypt_aes then
          t_bs := 16;
          aes_decrypt_key( key, t_decrypt_key  );
        when gc_encrypt_aes128 then
          t_bs := 16;
          aes_decrypt_key( key, t_decrypt_key  );
        when gc_encrypt_aes192 then
          t_bs := 16;
          aes_decrypt_key( key, t_decrypt_key  );
        when gc_encrypt_aes256 then
          t_bs := 16;
          aes_decrypt_key( key, t_decrypt_key  );
        else
          null;
      end case;
      t_idx := 1;
      t_len := utl_raw.length( src );
      t_iv := coalesce( iv, utl_raw.copies( '0', t_bs ) );
      t_bs2 := t_bs * 2;
      while t_idx <= t_len
      loop
        t_tmp := utl_raw.substr( src, t_idx, least( 16376, t_len - t_idx + 1 ) );
        if (   bitand( typ, 61440 ) = gc_PAD_NONE
           and mod( utl_raw.length( t_tmp ), t_bs ) != 0
           )
        then
          t_tmp := utl_raw.concat( t_tmp, utl_raw.copies( '00', t_bs - mod( utl_raw.length( t_tmp ), t_bs ) ) );
        end if;
        t_idx := t_idx + 16376;
        t_tmp2 := null;
        for i in 0 .. length( t_tmp ) / t_bs2 - 1
        loop
          case bitand( typ, 3840 )
           when gc_CHAIN_CBC then
              t_raw := decr( substr( t_tmp, i * t_bs2 + 1, t_bs2 ) );
              t_raw := utl_raw.bit_xor( t_raw, t_iv );
              t_iv := substr( t_tmp, i * t_bs2 + 1, t_bs2 );
            when gc_CHAIN_CFB then
              t_raw := decr( t_iv );
              t_iv := substr( t_tmp, i * t_bs2 + 1, t_bs2 );
              t_raw := utl_raw.bit_xor( t_raw, t_iv );
            when gc_CHAIN_OFB then
  $IF DBMS_DB_VERSION.VER_LE_10 $THEN
              t_raw := decr( substr( t_tmp, i * t_bs2 + 1, t_bs2 ) );
  $ELSIF DBMS_DB_VERSION.VER_LE_11 $THEN
              t_raw := decr( substr( t_tmp, i * t_bs2 + 1, t_bs2 ) );
  $ELSE
              t_iv := decr( t_iv );
              t_raw := utl_raw.bit_xor( substr( t_tmp, i * t_bs2 + 1, t_bs2 ), t_iv );
  $end
            when gc_CHAIN_OFB_REAL then
              t_iv := decr( t_iv );
              t_raw := utl_raw.bit_xor( substr( t_tmp, i * t_bs2 + 1, t_bs2 ), t_iv );
            when gc_CHAIN_ECB then
              t_raw := decr( substr( t_tmp, i * t_bs2 + 1, t_bs2 ) );
          end case;
          t_tmp2 := t_tmp2 || t_raw;
        end loop;
        t_decr := utl_raw.concat( t_decr, hextoraw( t_tmp2 ) );
      end loop;
      case bitand( typ, 61440 )
        when gc_PAD_PKCS5 then
          t_pad := to_number( utl_raw.substr( t_decr, -1 ), 'XX' );
          t_pad := utl_raw.length( t_decr ) - t_pad;
          t_decr := utl_raw.substr( t_decr, 1, t_pad );
        when gc_PAD_OneAndZeroes then -- OneAndZeroes Padding, ISO/IEC 7816-4
          t_pad := length( t_tmp2 ) - instr( t_tmp2, '80', -1 ) + 1;
          t_pad := utl_raw.length( t_decr ) - t_pad / 2;
          t_decr := utl_raw.substr( t_decr, 1, t_pad );
        when gc_PAD_ANSI_X923 then -- ANSI X.923
          t_pad := to_number( utl_raw.substr( t_decr, -1 ), 'XX' );
          t_pad := utl_raw.length( t_decr ) - t_pad - 1;
          t_decr := utl_raw.substr( t_decr, 1, t_pad );
        when gc_PAD_ZERO then -- zero padding
          t_pad := length( t_tmp2 ) - length( rtrim( t_tmp2, '0' ) );
          t_pad := trunc( t_pad / 2 );
          if t_pad > 0
          then
            t_pad := utl_raw.length( t_decr ) - t_pad;
            t_decr := utl_raw.substr( t_decr, 1, t_pad );
          end if;
        when gc_PAD_ORCL then -- zero padding
          t_pad := length( t_tmp2 ) - length( rtrim( t_tmp2, '0' ) );
          t_pad := trunc( t_pad / 2 );
          if t_pad > 0
          then
            t_pad := utl_raw.length( t_decr ) - t_pad;
            t_decr := utl_raw.substr( t_decr, 1, t_pad );
          end if;
        when gc_PAD_NONE then
          t_decr := utl_raw.substr( t_decr, 1, t_len );
        else
          null;
      end case;
      return t_decr;
    end;
  --

end oos_util_crypto;
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

  function timestamp2epoch(
    p_timestamp in timestamp)
    return pls_integer;

end oos_util_date;
/

create or replace package body oos_util_date
as
  /*!
   * For epoch dates use http://www.epochconverter.com/ to test
   */


  /**
   * Coverts date to Unix Epoch time
   *
   * @example
   *
   * select oos_util_date.date2epoch(sysdate)
   * from dual;
   *
   * OOS_UTIL_DATE.DATE2EPOCH(SYSDATE)
   * ---------------------------------
   *                        1461663997
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
        - (to_number(substr (tz_offset (sessiontimezone), 1, 3))+0) * 3600); -- Note: Was +1 but was causing 1 hour behind (#123)
  end date2epoch;


  /**
   * Converts Unix linux time to Oracle date
   *
   * @issue 18
   *
   * @example
   *
   * select oos_util_date.epoch2date(1461663982)
   * from dual;
   *
   * OOS_UTIL_DATE.EPOCH2DATE(1461663982)
   * ------------------------------------
   * 26-APR-2016 12:46:22
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
      + ((p_epoch + ((to_number(substr(tz_offset(sessiontimezone), 1, 3))+0) * 3600)) / 86400); -- Note: Was +1 but was causing 1 hour ahead (#123)
  end epoch2date;


  /*!
   * Coverts timestamp to Unix Epoch time
   *
   * @private Currently used for crypto. Needs more testing to make puplically available.
   *
   * @example
   *
   * select oos_util_date.timestamp2epoch(current_timestamp)
   * from dual;
   *
   * OOS_UTIL_DATE.TIMESTAMP2EPOCH(CURRENT_TIMESTAMP)
   * ---------------------------------
   * 1474277938
   *
   * @author Adrian Png
   * @created 22-Sep-2016
   * @param p_timestamp Timestamp to convert to Epoch format
   * @return Unix Epoch time
   */
  function timestamp2epoch(
    p_timestamp in timestamp)
    return pls_integer
  as
    c_start_time constant  timestamp with time zone := timestamp '1970-01-01 00:00:00 +00:00';
  begin
    return extract(day from (p_timestamp - c_start_time)) * 86400
      + extract(hour from (p_timestamp - c_start_time)) * 3600
      + extract(minute from (p_timestamp - c_start_time)) * 60
      + extract(second from (p_timestamp - c_start_time))
    ;
  end timestamp2epoch;


end oos_util_date;
/

prompt oos_util_lob
create or replace package oos_util_lob
as
  -- CONSTANTS
  /**
   * @constant gc_unit_b B
   * @constant gc_unit_kb KB
   * @constant gc_unit_mb MB
   * @constant gc_unit_gb GB
   * @constant gc_unit_tb TB
   * @constant gc_unit_pb PB
   * @constant gc_unit_eb EB
   * @constant gc_unit_zb ZB
   * @constant gc_unit_yb YB
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
    p_blob in blob,
    p_blob_csid in integer default dbms_lob.default_csid)
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

  -- procedure write_file(
  --   p_text in clob,
  --   p_path in varchar2,
  --   p_filename in varchar2);

  -- function read_file(
  --   p_path in varchar2,
  --   p_filename in varchar2)
  --   return clob;

end oos_util_lob;
/

create or replace package body oos_util_lob
as

  /**
   * Convers clob to blob
   *
   * @issue #12
   *
   * declare
   *   l_blob blob;
   *   l_clob clob;
   * begin
   *   l_blob := oos_util_lob.clob2blob(l_clob);
   * end;
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
   * declare
   *   l_blob blob;
   *   l_clob clob;
   * begin
   *   l_clob := oos_util_lob.blob2clob(l_blob);
   * end;
   *
   * @author Martin D'Souza
   * @created 02-Mar-2014
   * @param p_blob blob to be converted to clob
   * @param p_blob_csid Encoding to use. See https://docs.oracle.com/database/121/NLSPG/ch2charset.htm#NLSPG169 (table 2-4) for different charsets. Can use `nls_charset_id(<charset>)` to get the clob_csid
   * @return clob
   */
  function blob2clob(
    p_blob in blob,
    p_blob_csid in integer default dbms_lob.default_csid)
    return clob
  as
    l_clob clob;
    l_dest_offset integer := 1;
    l_src_offset integer := 1;
    l_lang_context integer := dbms_lob.default_lang_ctx;
    l_warning integer;
  begin
    oos_util.assert(p_blob_csid is not null, 'p_blob_csid is required: ' || p_blob_csid);
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
      blob_csid => p_blob_csid,
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
   * select
   *   oos_util_lob.get_file_size(2048) "2kb",
   *   oos_util_lob.get_file_size(3145728) "3mb",
   *   oos_util_lob.get_file_size(3145728, 'kb') "3mb_kb"
   * from dual;
   *
   * 2kb        3mb        3mb_kb
   * ---------- ---------- ----------
   * 2.0 KB     3.0 MB     3,072.0 KB
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
    l_units := nvl(upper(p_units),
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
   * Oracle's replace function handles clobs but runs into 32k issues
   *
   * Notes:
   *  - Source: http://dbaora.com/ora-22828-input-pattern-or-replacement-parameters-exceed-32k-size-limit/
   *
   * @issue #29
   *
   *
   * declare
   *   l_clob clob;
   * begin
   *   l_clob := 'foo bar foo';
   *
   *   l_clob := oos_util_lob.replace_clob(
   *     p_str => l_clob,
   *     p_search => 'foo',
   *     p_replace => 'hello'
   *   );
   *
   *   dbms_output.put_line(l_clob);
   * end;
   * /
   *
   * hello bar hello
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
    l_pos pls_integer := 1;
    l_return clob := p_str;
  begin
    while l_pos > 0 loop
      l_pos := instr(l_return, p_search, l_pos);

      if l_pos > 0 then
        l_return := substr(l_return, 1, l_pos-1)
            || p_replace
            || substr(l_return, l_pos+length(p_search));

        -- Move forward past the replaced string
        l_pos := l_pos + length(p_replace);
      end if;

    end loop;

    return l_return;
  end replace_clob;

  /*!
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
  -- Disabled for 1.0.0 See #156
  -- procedure write_file(
  --   p_text in clob,
  --   p_path in varchar2,
  --   p_filename in varchar2)
  -- as
  --   l_tmp_lob blob;
  -- begin
  --
  --   -- exit if any parameter is null
  --   oos_util.assert(p_text is not null, 'p_text required parameter');
  --   oos_util.assert(p_path is not null, 'p_path required parameter');
  --   oos_util.assert(p_filename is not null, 'p_filename required parameter');
  --
  --   -- convert a clob to a blob
  --   l_tmp_lob := clob2blob(p_text);
  --
  --   -- write a blob to a file
  --   declare
  --     l_lob_len pls_integer;
  --     l_fh utl_file.file_type;
  --     l_pos pls_integer := 1;
  --     l_buffer raw(32767);
  --     l_amount pls_integer := 32767;
  --   begin
  --     l_fh := utl_file.fopen(
  --       location => p_path,
  --       filename => p_filename,
  --       open_mode =>'wb',
  --       max_linesize => 32767);
  --
  --     l_lob_len := dbms_lob.getlength(l_tmp_lob);
  --
  --     while l_pos < l_lob_len loop
  --       dbms_lob.read(
  --         lob_loc => l_tmp_lob,
  --         amount => l_amount,
  --         offset => l_pos,
  --         buffer => l_buffer);
  --
  --       utl_file.put_raw(
  --         file => l_fh,
  --         buffer => l_buffer,
  --         autoflush => false);
  --
  --       l_pos := l_pos + l_amount;
  --     end loop;
  --
  --     utl_file.fclose(l_fh);
  --     dbms_lob.freetemporary(l_tmp_lob);
  --   end;
  --
  -- end write_file;

  /*!
   *
   * Read a content of a file (p_filename) from a database server file system
   * directory (p_path) and return it as a temporary clob. The caller is
   * responsible to free the clob (dbms_lob.freetemporary()). p_path is an
   * Oracle directory object.
   *
   * @issue #56
   *
   * @author Jani Hur <webmaster@jani-hur.net>
   * @created 05-Apr-2016
   * @param p_path
   * @param p_filename
   * @return clob
   */
  -- See #156
  -- function read_file(
  --   p_path in varchar2,
  --   p_filename in varchar2)
  --   return clob
  -- as
  --   l_src_bfile bfile;
  --   l_tmp_lob clob;
  --
  --   l_dest_offset integer := 1;
  --   l_src_offset integer := 1;
  --   l_lang_context integer := dbms_lob.default_lang_ctx;
  --   l_warning integer := dbms_lob.no_warning;
  -- begin
  --   -- exit if any parameter is null
  --   oos_util.assert(p_path is not null, 'p_path required parameter');
  --   oos_util.assert(p_filename is not null, 'p_filename required parameter');
  --
  --   l_src_bfile := bfilename(upper(p_path), p_filename);
  --
  --   dbms_lob.open(l_src_bfile, dbms_lob.lob_readonly);
  --
  --   dbms_lob.createtemporary(
  --     lob_loc => l_tmp_lob,
  --     cache => false);
  --
  --   dbms_lob.loadclobfromfile(
  --     dest_lob     => l_tmp_lob
  --    ,src_bfile    => l_src_bfile
  --    ,amount       => dbms_lob.lobmaxsize
  --    ,dest_offset  => l_dest_offset
  --    ,src_offset   => l_src_offset
  --    ,bfile_csid   => dbms_lob.default_csid
  --    ,lang_context => l_lang_context
  --    ,warning      => l_warning
  --   );
  --
  --   dbms_lob.close(l_src_bfile);
  --
  --   oos_util.assert(l_warning = dbms_lob.no_warning, 'failed to load clob from a file: ' || l_warning);
  --
  --   return l_tmp_lob;
  -- end read_file;

end oos_util_lob;
/

prompt oos_util_string
create or replace package oos_util_string
as

  -- TYPES

  -- CONSTANTS
  /**
   * @constant gc_default_delimiter Default delimiter for delimited strings
   * @constant gc_cr Carriage Return
   * @constant gc_lf Line Feed
   * @constant gc_crlf Use for new lines.
   */
  gc_default_delimiter constant varchar2(1) := ',';
  gc_cr constant varchar2(1) := chr(13);
  gc_lf constant varchar2(1) := chr(10);
  gc_crlf constant varchar2(2) := gc_cr || gc_lf;

  function to_char(
    p_val in number)
    return varchar2
    deterministic;

  function to_char(
    p_val in date)
    return varchar2
    deterministic;

  function to_char(
    p_val in timestamp)
    return varchar2
    deterministic;

  function to_char(
    p_val in timestamp with time zone)
    return varchar2
    deterministic;

  function to_char(
    p_val in timestamp with local time zone)
    return varchar2;

  function to_char(
    p_val in boolean)
    return varchar2
    deterministic;

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
    p_str in clob,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2_arr;

  function string_to_table(
    p_str in varchar2,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2_arr;

  function listunagg(
    p_str in varchar2,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2 pipelined;

  function listunagg(
    p_str in clob,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2 pipelined;

  function reverse(
    p_str in varchar2)
    return varchar2;

  function ordinal(
    p_num in number)
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
   * @example
   *
   * select oos_util_string.to_char(123)
   * from dual;
   *
   * OOS_UTIL_STRING.TO_CHAR(123)---
   * 123
   *
   * @author Martin D'Souza
   * @created 07-Jun-2014
   * @param p_val Number
   * @return string value for p_val
   */
  function to_char(
    p_val in number)
    return varchar2
    deterministic
  as
  begin
    return sys.standard.to_char(p_val);
  end to_char;

  /**
   * See first `to_char`
   *
   * @example
   * select oos_util_string.to_char(sysdate)
   * from dual;
   *
   * OOS_UTIL_STRING.TO_CHAR(SYSDATE)---
   * 26-APR-2016 13:57:51
   *
   * @param p_val Date
   * @return string value for p_val
   */
  function to_char(
    p_val in date)
    return varchar2
    deterministic
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_date_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @example
   * select oos_util_string.to_char(systimestamp)
   * from dual;
   *
   * OOS_UTIL_STRING.TO_CHAR(SYSTIMESTAMP)---
   * 26-APR-2016 13:58:24:851908000 -06:00
   *
   * @param p_val Timestamp
   * @return string value for p_val
   */
  function to_char(
    p_val in timestamp)
    return varchar2
    deterministic
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_timestamp_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @example
   * TODO
   * @param p_val Timestamp with TZ
   * @return string value for p_val
   */
  function to_char(
    p_val in timestamp with time zone)
    return varchar2
    deterministic
  as
  begin
    return sys.standard.to_char(p_val, oos_util.gc_timestamp_tz_format);
  end to_char;

  /**
   * See first `to_char`
   *
   * @example
   * TODO
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
   * @example
   * begin
   *   dbms_output.put_line(oos_util_string.to_char(true));
   *   dbms_output.put_line(oos_util_string.to_char(false));
   * end;
   * /
   *
   * TRUE
   * FALSE
   *
   * @param p_val Boolean
   * @return string value for p_val
   */
  function to_char(
    p_val in boolean)
    return varchar2
    deterministic
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
   * @example
   * select
   *   oos_util_string.truncate(
   *     p_str => comments,
   *     p_length => 20,
   *     p_by_word => 'N'
   *   ) by_word_n,
   *   oos_util_string.truncate(
   *     p_str => comments,
   *     p_length => 20,
   *     p_by_word => 'Y'
   *   ) by_word_y
   * from apex_dictionary
   * where 1=1
   *   and rownum <= 5
   * ;
   *
   * BY_WORD_N            BY_WORD_Y
   * -------------------- --------------------
   * List of APEX buil... List of APEX...
   * Identifies the th... Identifies the...
   * Identifies the na... Identifies the...
   * Identifies the th... Identifies the...
   * Identifies a work... Identifies a...
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

    -- #122 return null if string is null. Doing first since no need to do extra work if null.
    if l_str is null then
      return null;
    end if;

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
   * @example
   * declare
   *   l_str clob := 'abc,def,ghi';
   *   l_arr oos_util.tab_vc2_arr;
   * begin
   *   l_arr := oos_util_string.string_to_table(p_str => l_str);
   *
   *   for i in 1..l_arr.count loop
   *     dbms_output.put_line('i: ' || i || ' ' || l_arr(i));
   *   end loop;
   * end;
   * /
   *
   * i: 1 abc
   * i: 2 def
   * i: 3 ghi
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_str String containing delimited text
   * @param p_delim Delimiter
   * @return Array of string
   */
  function string_to_table(
    p_str in clob,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2_arr
  is
    l_last_pos pls_integer;
    l_pos pls_integer;

    l_return oos_util.tab_vc2_arr;
    l_delimiter_len pls_integer := length(p_delim);

  begin

    if p_str is not null then
      l_last_pos := 1 - l_delimiter_len; -- If the delimeter length = 1 (most cases) this should be 0. If not need to move back "n" chars
      l_pos := 0;

      while true loop
        l_pos := l_pos + 1;
        l_pos := dbms_lob.instr(p_str, p_delim, l_pos, 1);

        if l_pos = 0 then
          l_return(l_return.count + 1) := substr(p_str, l_last_pos + l_delimiter_len); -- Get everything to the end.
          exit;
        else
          l_return(l_return.count + 1) := dbms_lob.substr(p_str, l_pos - (l_last_pos+l_delimiter_len), l_last_pos + l_delimiter_len);
        end if; -- l_pos = 0

        l_last_pos := l_pos;
      end loop;
    end if; -- p_str is not null

    return l_return;
  end string_to_table;

  /**
   * See `string_to_table (p_str clob)` for notes
   *
   * @issue  #32
   *
   * @example
   * -- See previous example
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_str String containing delimited text
   * @param p_delim Delimiter
   * @return Array of string
   */
  function string_to_table(
    p_str in varchar2,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2_arr
  is
    l_clob clob;
    l_return oos_util.tab_vc2_arr;
  begin
    l_clob := p_str;
    return string_to_table(p_str => l_clob, p_delim => p_delim);
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
   * @param p_str String containing delimited text
   * @param p_delim Delimiter
   * @return pipelined table
   */
  function listunagg(
    p_str in varchar2,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2 pipelined
  is
    l_arr oos_util.tab_vc2_arr;
  begin
    l_arr := string_to_table(p_str => p_str, p_delim => p_delim);

    for i in 1 .. l_arr.count loop
      pipe row (l_arr(i));
    end loop;
  end listunagg;


  /**
   * Converts delimited string to queriable table
   *
   * @issue #4
   *
   * @example
   * See previous example
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_str String (clob) containing delimited text
   * @param p_delim Delimiter
   * @return pipelined table
   */
  function listunagg(
    p_str in clob,
    p_delim in varchar2 default gc_default_delimiter)
    return oos_util.tab_vc2 pipelined
  is
    l_arr oos_util.tab_vc2_arr;
  begin
    l_arr := string_to_table(p_str => p_str, p_delim => p_delim);

    for i in 1 .. l_arr.count loop
      pipe row (l_arr(i));
    end loop;
  end listunagg;


  /**
   * Returns the input string in its reverse order
   *
   * @issue #55
   *
   * @example
   * begin
   *   dbms_output.put_line(oos_util_string.reverse('OraOpenSource'));
   * end;
   * /
   *
   * ecruoSnepOarO
   *
   * @author Tim Nanos
   * @created 31-Mar-2016
   * @param p_str String
   * @return String
   */
  function reverse(
    p_str in varchar2)
    return varchar2
  is
    l_string varchar2(32767);
  begin
    if p_str is not null then
      for i in 1..length(p_str) loop
        l_string := substr(p_str, i, 1) || l_string;
      end loop;
    end if;

    return l_string;
  end reverse;

  /**
   * Returns the input number with the ordinal attached, in english.
   * e.g. 1st, 2nd, 3rd, 4th, etc
   *
   * Notes:
   * - Logic taken from: http://stackoverflow.com/a/13627586/3476713
   *
   * @issue #53
   *
   * @example
   * select oos_util_string.ordinal(level)
   * from dual
   * connect by level <= 10;
   *
   * @author Trent Schafer
   * @created 1-Aug-2016
   * @param p_num Number
   * @return String
   */
  function ordinal(
    p_num in number)
    return varchar2
  is
    l_mod10 number;
    l_mod100 number;

    l_ordinal varchar2(2);
  begin
    l_mod10 := mod(p_num, 10);
    l_mod100 := mod(p_num, 100);

    if l_mod10 = 1 and l_mod100 != 11
    then
      l_ordinal := 'st';
    elsif l_mod10 = 2 and l_mod100 != 12
    then
      l_ordinal := 'nd';
    elsif l_mod10 = 3 and l_mod100 != 13
    then
      l_ordinal := 'rd';
    else
      l_ordinal := 'th';
    end if;

    return p_num || l_ordinal;
  end ordinal;

end oos_util_string;
/

prompt oos_util_totp
/**
 * References:
 * - https://community.oracle.com/thread/3905510
 * - http://jacob.jkrall.net/totp/
 */
create or replace package oos_util_totp
as


  function generate_secret(p_length number default 16) return varchar2;

  function format_key_uri(
    p_type number default null
    , p_label_accountname varchar2
    , p_label_issuer varchar2
    , p_secret varchar2
    , p_issuer varchar2 default null
    , p_algorithm varchar2 default null
    , p_digits number default null
    , p_counter number default null
    , p_period number default null
  ) return varchar2;

  function generate_otp(p_secret varchar2, p_offset number default 0) return varchar2;

  function validate_otp(
    p_secret varchar2
    , p_otp number
    , p_skew number default 30
  ) return number;
end oos_util_totp;
/

create or replace package body oos_util_totp
as
  /**
   * A PL/SQL implementation of the Google Authnticator's Time-based One-Time
   * Password algorithm. The code in this package is based on the work [1] by
   * "Rabbit" from ATEX Media Solutions Pty Ltd. For more information about
   * Google Authenticator, please see reference [2].
   *
   * [1] - <https://community.oracle.com/thread/3905510>
   * [2] - <https://github.com/google/google-authenticator/wiki>
   *
   * @issue 108
   *
   * @author Adrian Png
   * @created 17-Aug-2016
   *
   */

  gc_base32 constant varchar2(32) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  gc_step constant number := 30;

  function to_binary(p_num number) return varchar2
  is
    l_szbin varchar2(8);
    l_nrem number := p_num;
  begin
    if p_num = 0 then
      return '0';
    end if;

    while l_nrem > 0 loop
      l_szbin := mod(l_nrem, 2) || l_szbin;
      l_nrem := trunc(l_nrem / 2 );
    end loop;
    return l_szbin;
  end to_binary;

  /**
   * Generates a sixteen-character alphanumeric, Base32-encoded [1] string.
   *
   * [1] - <https://en.wikipedia.org/wiki/Base32>
   *
   * @example
   * select generate_secret
   * from dual;
   *
   *
   * @param p_length number
   * @return sixteen-character alphanumeric string
   */
  function generate_secret (p_length number default 16) return varchar2
  is
    l_secret varchar2(32767);
  begin
    for i in 1..p_length loop
      l_secret := l_secret || substr(gc_base32, dbms_random.value(1, (length(gc_base32) - 1)), 1);
    end loop;

    return l_secret;
  end generate_secret;

  /**
   * Returns a URI that can be used to create a QR Code for setting up a entry
   * in Google Authenticator by scanning [1]. After obtaining the URI, create
   * a QR Code to make it easier to create an entry in Google Authenticator.
   *
   * [1] - <https://github.com/google/google-authenticator/wiki/Key-Uri-Format>
   *
   * @example
   * select
   *   oos_util_totp.format_key_uri(
   *     p_label_accountname => 'adrian.png@wonderland.com'
   *     , p_label_issuer => 'Superworld'
   *     , p_secret => 'JBSWY3DPEHPK3PXP'
   *     , p_issuer => 'Superworld'
   *   )
   * from dual;
   *
   *
   * @param p_type number (currently not supported)
   * @param p_label_accountname varchar2
   * @param p_label_issuer varchar2
   * @param p_secret varchar2
   * @param p_issuer varchar2
   * @param p_algorithm varchar2 (currently not supported)
   * @param p_digits number (currently not supported)
   * @param p_counter number (currently not supported)
   * @param p_period number (currently not supported)
   * @return URI string
   */
  function format_key_uri(
    p_type number default null
    , p_label_accountname varchar2
    , p_label_issuer varchar2
    , p_secret varchar2
    , p_issuer varchar2 default null
    , p_algorithm varchar2 default null
    , p_digits number default null
    , p_counter number default null
    , p_period number default null
  ) return varchar2
  is
    l_url varchar2(32767);
    l_issuer varchar2(32767);
    l_label varchar2(32767);
  begin
    l_url := 'otpauth://#TYPE#/#LABEL#?secret=#SECRET#&issuer=#ISSUER#';

    l_label :=
      case
        when p_label_issuer is not null then '#ISSUER#:#ACCOUNTNAME#'
        else '#ACCOUNTNAME#'
      end;

    -- Set the issuer. Only use either issue supplied. Remove  illegal characters;
    l_issuer := regexp_replace(coalesce(p_label_issuer, p_issuer), ':|;', '');

    l_label := replace(l_label, '#ISSUER#', l_issuer);
    l_label := replace(l_label, '#ACCOUNTNAME#', p_label_accountname);

    l_url := replace(l_url, '#TYPE#', 'totp');
    l_url := replace(l_url, '#LABEL#', utl_url.escape(url => l_label));
    l_url := replace(l_url, '#SECRET#', p_secret);
    l_url := replace(l_url, '#ISSUER#', utl_url.escape(url => l_issuer));

    return l_url;
  end format_key_uri;

  /**
   * Generates a six-digit number
   *
   * @todo Support for SHA-2 for Oracle 12c compilation.
   * @todo Pass MAC type as a parameter.
   *
   * @example
   * select generate_otp(p_secret => 'JBSWY3DPEHPK3PXP')
   * from dual;
   *
   * select generate_otp(p_secret => 'JBSWY3DPEHPK3PXP', p_offset => -30)
   * from dual;
   *
   *
   * @param p_secret varchar2
   * @param p_offset number
   * @return six-digit number as a string
   */
  function generate_otp(p_secret varchar2, p_offset number default 0) return varchar2
  is
    l_szbits varchar2(500);
    l_sztmp varchar2(500);
    l_sztmp2 varchar2(500);
    l_npos number;
    l_nepoch number(38);
    l_szepoch varchar2(16);
    l_rhmac raw(100);
    l_noffset number;
    l_npart1 number;
    l_npart2 number := 2147483647;
    l_current_timestamp timestamp with local time zone;
  begin
    for c in 1..length(p_secret) loop
      l_npos := instr(gc_base32, substr(p_secret, c, 1)) - 1;
      l_szbits := l_szbits || lpad(to_binary(l_npos), 5, '0');
    end loop;

    l_npos := 1;

    while l_npos < length(l_szbits) loop
      select
        ltrim(
          to_char(
            bin_to_num(
              to_number(substr(l_szbits, l_npos, 1))
              , to_number(substr(l_szbits, l_npos + 1, 1))
              , to_number(substr(l_szbits, l_npos + 2, 1))
              , to_number(substr(l_szbits, l_npos + 3, 1))
            )
            , 'x'
          )
        )
      into l_sztmp2
      from dual;

      l_sztmp := l_sztmp || l_sztmp2;

      l_npos := l_npos + 4;
    end loop;

    l_current_timestamp := current_timestamp;
    l_nepoch := extract(day from (l_current_timestamp - timestamp '1970-01-01 00:00:00 +00:00')) * 86400
      + extract(hour from (l_current_timestamp - timestamp '1970-01-01 00:00:00 +00:00')) * 3600
      + extract(minute from (l_current_timestamp - timestamp '1970-01-01 00:00:00 +00:00')) * 60
      + extract(second from (l_current_timestamp - timestamp '1970-01-01 00:00:00 +00:00'))
      + p_offset;

    l_szepoch := lpad(
      ltrim(
        to_char(
          floor(l_nepoch / gc_step)
          , 'xxxxxxxxxxxxxxxx'
        )
      )
      , 16
      , '0'
    );

    -- Original code
    -- l_rhmac := dbms_crypto.mac(
    --   src => hextoraw(l_szepoch)
    --   , typ => dbms_crypto.hmac_sh1
    --   , key => hextoraw(l_sztmp)
    -- );
    l_rhmac := oos_util_crypto.mac(
      p_src => hextoraw(l_szepoch)
      , p_typ => oos_util_crypto.gc_hmac_sh1
      , p_key => hextoraw(l_sztmp)
    );

    l_noffset := to_number(substr(rawtohex(l_rhmac), -1, 1), 'x');

    l_npart1 := to_number(substr(rawtohex(l_rhmac), l_noffset * 2 + 1, 8), 'xxxxxxxx');

    return substr(bitand(l_npart1, l_npart2), -6, 6);
  end generate_otp;

  /**
   * Validate an OTP. The skew parameter allows for a customizable degree of
   * tolerance for clocks that are not in sync.
   *
   * @todo Support for SHA-2 for Oracle 12c compilation.
   * @todo Pass MAC type as a parameter.
   *
   * @example
   * begin
   *   if oos_util_totp.validate_otp(
   *     p_secret => 'JBSWY3DPEHPK3PXP'
   *     , p_otp => 123456
   *     , p_skew => 30
   *   ) = 1 then
   *     dbms_output.put_line('Valid');
   *   else
   *     dbms_output.put_line('Failed');
   *   end if;
   * end;
   *
   *
   * @param p_secret varchar2
   * @param p_otp number
   * @param p_skew number
   * @return number
   */
  function validate_otp(
    p_secret varchar2
    , p_otp number
    , p_skew number default 30
  ) return number
  as
    l_ticks number;
    l_offset number;
  begin
    l_ticks := floor(p_skew / gc_step);
    l_offset := -(l_ticks * gc_step);

    while(l_offset <= l_ticks * gc_step) loop
      if p_otp = generate_otp(p_secret => p_secret, p_offset => l_offset) then
        return 1;
      else
        l_offset := l_offset + gc_step;
      end if;
    end loop;

    return 0;
  end validate_otp;
end oos_util_totp;
/

prompt oos_util_validation
create or replace package oos_util_validation
as

  function is_number(p_str in varchar2)
    return boolean
    deterministic;

  function is_date(
    p_str in varchar2,
    p_date_format in varchar2)
    return boolean
    deterministic;


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
   * @example
   * begin
   *   dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_number('123')));
   *   dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_number('abc')));
   * end;
   * /
   *
   * TRUE
   * FALSE
   *
   * @author Trent Schafer
   * @created 05-Sep-2015
   * @param p_str String to validate
   * @return True of p_str is number
   */
  function is_number(p_str in varchar2)
    return boolean
    deterministic
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
   * @example
   * begin
   *   dbms_output.put_line(oos_util_string.to_char(
   *     oos_util_validation.is_date('01-JAN-2015', 'DD-MON-YYYY')));
   *   dbms_output.put_line(oos_util_string.to_char(
   *     oos_util_validation.is_date('not-a-date', 'DD-MON-YYYY')));
   * end;
   * /
   *
   * TRUE
   * FALSE
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
    deterministic
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
   * @example
   * select
   *   oos_util_web.get_mime_type('file.xls') xls,
   *   oos_util_web.get_mime_type('file.txt') txt,
   *   oos_util_web.get_mime_type('file.swf') swf
   * from dual;
   *
   * XLS                        TXT          SWF
   * -------------------------- ------------ ------------------------------
   * application/vnd.ms-excel   text/plain   application/x-shockwave-flash
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
   * Will call `apex_application.stop_apex_engine` if called from within an APEX application
   *
   * @issue #2
   * @issue #47: cache support
   *
   * @example
   *
   * oos_util_web.download_file(
   *   p_filename => 'my_file.zip',
   *   p_blob => l_file):
   *
   *
   * @author Martin Giffy D'Souza
   * @created 28-Dec-2015
   * @param p_filename Filename
   * @param p_mime_type mime-type of file. If null will be automatically resolved via p_filename
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
   * @example
   * oos_util_web.download_file(
   *   p_filename => 'my_file.txt',
   *   p_clob => l_file):
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
    into oos_util_values(cat, name, value) values('mime-type', 'mpd','application/dash+xml')
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
    into oos_util_values(cat, name, value) values('mime-type', 'geojson','application/geo+json')
    into oos_util_values(cat, name, value) values('mime-type', 'gml','application/gml+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'gpx','application/gpx+xml')
    into oos_util_values(cat, name, value) values('mime-type', 'gxf','application/gxf')
    into oos_util_values(cat, name, value) values('mime-type', 'gz','application/gzip')
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
    into oos_util_values(cat, name, value) values('mime-type', 'gdoc','application/vnd.google-apps.document')
    into oos_util_values(cat, name, value) values('mime-type', 'gslides','application/vnd.google-apps.presentation')
    into oos_util_values(cat, name, value) values('mime-type', 'gsheet','application/vnd.google-apps.spreadsheet')
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
    into oos_util_values(cat, name, value) values('mime-type', 'rng','application/xml')
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
    into oos_util_values(cat, name, value) values('mime-type', '3gpp','video/3gpp')
    into oos_util_values(cat, name, value) values('mime-type', 'adp','audio/adpcm')
    into oos_util_values(cat, name, value) values('mime-type', 'au','audio/basic')
    into oos_util_values(cat, name, value) values('mime-type', 'snd','audio/basic')
    into oos_util_values(cat, name, value) values('mime-type', 'mid','audio/midi')
    into oos_util_values(cat, name, value) values('mime-type', 'midi','audio/midi')
    into oos_util_values(cat, name, value) values('mime-type', 'kar','audio/midi')
    into oos_util_values(cat, name, value) values('mime-type', 'rmi','audio/midi')
    into oos_util_values(cat, name, value) values('mime-type', 'mp3','audio/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'm4a','audio/mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'mp4a','audio/mp4')
    into oos_util_values(cat, name, value) values('mime-type', 'mpga','audio/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'mp2','audio/mpeg')
    into oos_util_values(cat, name, value) values('mime-type', 'mp2a','audio/mpeg')
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
    into oos_util_values(cat, name, value) values('mime-type', 'apng','image/apng')
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
    into oos_util_values(cat, name, value) values('mime-type', 'markdown','text/markdown')
    into oos_util_values(cat, name, value) values('mime-type', 'md','text/markdown')
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
    into oos_util_values(cat, name, value) values('mime-type', 'slim','text/slim')
    into oos_util_values(cat, name, value) values('mime-type', 'slm','text/slim')
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

