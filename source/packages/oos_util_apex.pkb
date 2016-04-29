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
   *
   * @example
   *
   * begin
   *   oos_util_apex.create_session(
   *     p_app_id => :app_id,
   *     p_user_name => :app_user,
   *     p_page_id => :app_page_id);
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
   * Join an existing APEX session
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
