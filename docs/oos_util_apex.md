# OOS_UTIL_APEX

- [IS_DEVELOPER Function](#is_developer)
- [IS_DEVELOPER_YN Function](#is_developer_yn)
- [IS_SESSION_VALID Function](#is_session_valid)
- [IS_SESSION_VALID_YN Function](#is_session_valid_yn)
- [CREATE_SESSION Procedure](#create_session)
- [JOIN_SESSION Procedure](#join_session)
- [TRIM_PAGE_ITEMS Procedure](#trim_page_items)
- [IS_PAGE_ITEM_RENDERED Function](#is_page_item_rendered)








 
## IS_DEVELOPER Function<a name="is_developer"></a>


<p>
<p>Returns true/false if APEX developer is enable<br />Supports both APEX 4 and 5</p><p>Can be used in APEX to declaratively determine if in development mode.</p>
</p>

### Syntax
```plsql
function is_developer
  return boolean
```

### Parameters
Name | Description
--- | ---
*return* | boolan True: Developer has an active session in Application Builder
 
 


### Example
```plsql
begin
  if oos_util_apex.is_developer then
    dbms_output.put_line('Developer mode');
  else
    dbms_output.put_line('Non-Dev mode');
  end if;
end;
```



 
## IS_DEVELOPER_YN Function<a name="is_developer_yn"></a>


<p>
<p>Returns Y/N if APEX developer is enable<br />See <code>is_developer</code> for details</p>
</p>

### Syntax
```plsql
function is_developer_yn
  return varchar2
```

### Parameters
Name | Description
--- | ---
*return* | Y or N
 
 


### Example
```plsql
begin
  if oos_util_apex.is_developer_yn = 'Y' then
    dbms_output.put_line('Developer mode');
  else
    dbms_output.put_line('Non-Dev mode');
  end if;
end;
```



 
## IS_SESSION_VALID Function<a name="is_session_valid"></a>


<p>
<p>Checks if APEX session is still active/valid</p>
</p>

### Syntax
```plsql
function is_session_valid(
  p_session_id in apex_workspace_sessions.apex_session_id%type)
  return boolean
```

### Parameters
Name | Description
--- | ---
`p_session_id` | APEX session ID
*return* | true/false
 
 


### Example
```plsql

begin
  if oos_util_apex.is_session_valid(p_session_id => :app_session) then
    dbms_output.put_line('Session is active');
  else
    dbms_output.put_line('Session is inactive');
  end if;
end;
```



 
## IS_SESSION_VALID_YN Function<a name="is_session_valid_yn"></a>


<p>
<p>Checks if session is still active</p>
</p>

### Syntax
```plsql
function is_session_valid_yn(
  p_session_id in apex_workspace_sessions.apex_session_id%type)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_session_id` | APEX session ID
*return* | Y/N
 
 


### Example
```plsql

begin
  if oos_util_apex.is_session_valid_yn(p_session_id => :app_session) = 'Y' then
    dbms_output.put_line('Session is active');
  else
    dbms_output.put_line('Session is inactive');
  end if;
end;
```



 
## CREATE_SESSION Procedure<a name="create_session"></a>


<p>
<p>Creates a new APEX session.<br />Useful when testing APEX functionality in PL/SQL or using apex_mail etc</p><p>Can only create one per Oracle session. To connect to a different APEX session, reconnect the Oracle session</p><p>Notes:</p><ul>
<li>Content taken from:<ul>
<li><a href="http://www.talkapex.com/2012/08/how-to-create-apex-session-in-plsql.html">http://www.talkapex.com/2012/08/how-to-create-apex-session-in-plsql.html</a></li>
<li><a href="http://apextips.blogspot.com.au/2014/10/debugging-parameterised-views-outside.html">http://apextips.blogspot.com.au/2014/10/debugging-parameterised-views-outside.html</a></li>
</ul>
</li>
</ul>

</p>

### Syntax
```plsql
procedure create_session(
  p_app_id in apex_applications.application_id%type,
  p_user_name in apex_workspace_sessions.user_name%type,
  p_page_id in apex_application_pages.page_id%type default null,
  p_session_id in apex_workspace_sessions.apex_session_id%type default null)
```

### Parameters
Name | Description
--- | ---
`p_app_id` | 
`p_user_name` | 
`p_page_id` | Page to try and register for post login. Recommended to leave null
`p_session_id` | Session to re-join. Recommended leave null
 
 


### Example
```plsql

begin
  oos_util_apex.create_session(
    p_app_id => :app_id,
    p_user_name => :app_user,
    p_page_id => :app_page_id);
  );
end;
```



 
## JOIN_SESSION Procedure<a name="join_session"></a>


<p>
<p>Join an existing APEX session</p><p>Notes:</p><ul>
<li><code>v(&#39;P1_X&#39;)</code> won&#39;t work. Use <code>apex_util.get_session_state(&#39;P1_X&#39;)</code> instead</li>
</ul>

</p>

### Syntax
```plsql
procedure join_session(
  p_session_id in apex_workspace_sessions.apex_session_id%type,
  p_app_id in apex_applications.application_id%type default null)
```

### Parameters
Name | Description
--- | ---
`p_session_id` | The session you want to join. Must be an existing active session.
`p_app_id` | Use if multiple applications are linked to the same session. If null, last used application will be used.
 
 


### Example
```plsql

begin
  oos_util_apex.join_session(
    p_session_id => :app_session,
    p_app_id => :app_id
  );
end;
```



 
## TRIM_PAGE_ITEMS Procedure<a name="trim_page_items"></a>


<p>
<p>Trims whitespace APEX page items (before and after).<br />Useful when submitting a page to trim all items.</p><p>Notes:</p><ul>
<li>Suggested to run submit page process application wide</li>
<li>Excludes inputs that users shouldn&#39;t modify and password fields<ul>
<li>Ex: select list, hidden values, files</li>
</ul>
</li>
</ul>

</p>

### Syntax
```plsql
procedure trim_page_items(
  p_page_id in apex_application_pages.page_id%type default apex_application.g_flow_step_id)
```

### Parameters
Name | Description
--- | ---
`p_page_id` | Items on this page will be trimmed.
 
 


### Example
```plsql

begin
  oos_util_apex.trim_page_items(p_page_id => :app_page_id);
end;
```



 
## IS_PAGE_ITEM_RENDERED Function<a name="is_page_item_rendered"></a>


<p>
<p>Returns true/false if page item was rendered</p><p>Notes:</p><ul>
<li>This should only run on a page submit process otherwise it won&#39;t work. An error is raised otherwise</li>
</ul>

</p>

### Syntax
```plsql
function is_page_item_rendered(
  p_item_name in apex_application_page_items.item_name%type)
  return boolean
```

### Parameters
Name | Description
--- | ---
*return* | true/false
 
 


### Example
```plsql
begin
  if oos_util_apex.is_page_item_rendered(p_item_name => 'P1_EMPNO') then
    dbms_output.put_line('P1_EMPNO rendered');
  else
    dbms_output.put_line('P1_EMPNO was not rendered');
  end if;
end;
```



 
