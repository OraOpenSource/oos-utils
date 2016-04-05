# OOS_UTIL

- [Constants](#constants)
- [LOG Procedure](#log)
- [ASSERT Procedure](#assert)
- [SLEEP Procedure](#sleep)


## <a name="constants"></a>Constants

Name | Code | Description
--- | --- | ---
gc_date_format | `gc_date_format constant varchar2(255) := 'DD-MON-YYYY HH24:MI:SS';` | default date format
gc_timestamp_format | `gc_timestamp_format constant varchar2(255) := gc_date_format || ':FF';` | default timestamp format
gc_timestamp_tz_format | `gc_timestamp_tz_format constant varchar2(255) := gc_timestamp_format || ' TZR';` | default timestamp (with TZ) format
gc_version | `gc_version constant varchar2(10) := '1.0.0';` | 





 
## <a name="log"></a>LOG Procedure


<p>
<p>Internal logging procedure.<br />Requires Logger to be installed only while developing.<br />-- TODO mdsouza: conditional compilation notes</p>
</p>

### Syntax
```plsql
procedure log(
  p_text in varchar2,
  p_scope in varchar2)
```

### Parameters
Name | Description
--- | ---
`p_message` | Item to log
`p_scope` | Logger scope
 
 





 
## <a name="assert"></a>ASSERT Procedure


<p>
<p>Validates assertion.<br />Will raise an application error if assertion is false</p>
</p>

### Syntax
```plsql
procedure assert(
  p_condition in boolean,
  p_msg in varchar2)
```

### Parameters
Name | Description
--- | ---
`p_condition` | Boolean condition to validate
`p_msg` | Message to include in application error if p_condition fails
 
 





 
## <a name="sleep"></a>SLEEP Procedure


<p>
<p>Sleep procedure for n seconds</p><p>Notes:</p><ul>
<li>It is recommended that you use Oracle&#39;s lock procedures: <a href="http://psoug.org/reference/sleep.html">http://psoug.org/reference/sleep.html</a></li>
<li>However in some instances you may not have access to them</li>
<li>This implementation may tie up CPU so only use for development purposes</li>
<li>If calling in SQLDeveloper may get &quot;IO Error: Socket read timed out&quot;. This is a JDBC driver setting, not a bug in this code.</li>
</ul>

</p>

### Syntax
```plsql
procedure sleep(
  p_seconds in simple_integer)
```

### Parameters
Name | Description
--- | ---
`p_seconds` | Number of seconds to sleep for
 
 





 
