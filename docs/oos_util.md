# OOS_UTIL

- [Data Types](#types)

- [Constants](#constants)



- [ASSERT Procedure](#assert)
- [SLEEP Procedure](#sleep)
- [ASSOC_ARR2NESTED_TABLE Function](#assoc_arr2nested_table)
- [ASSOC_ARR2NESTED_TABLE-1 Function](#assoc_arr2nested_table-1)

## Types<a name="types"></a>

Name | Code | Description
--- | --- | ---
tab_num | <pre>type tab_num is table of number;</pre> | `number` nested table
tab_num_arr | <pre>type tab_num_arr is table of number index by pls_integer;</pre> | `number` associated array
tab_vc2 | <pre>type tab_vc2 is table of varchar2(32767);</pre> | `varchar2` nested table
tab_vc2_arr | <pre>type tab_vc2_arr is table of varchar2(32767) index by pls_integer;</pre> | `varchar2` associated array



## Constants<a name="constants"></a>

Name | Code | Description
--- | --- | ---
gc_date_format | <pre>gc_date_format constant varchar2(255) := 'YYYY-MM-DD HH24:MI:SS';</pre> | default date format
gc_timestamp_format | <pre>gc_timestamp_format constant varchar2(255) := gc_date_format || ':FF';</pre> | default timestamp format
gc_timestamp_tz_format | <pre>gc_timestamp_tz_format constant varchar2(255) := gc_timestamp_format || ' TZR';</pre> | default timestamp (with TZ) format
gc_version_major | <pre>gc_version_major constant pls_integer := 1;</pre> | Version number major 1.0.0
gc_version_minor | <pre>gc_version_minor constant pls_integer := 0;</pre> | Verison number minor 0.1.0
gc_version_patch | <pre>gc_version_patch constant pls_integer := 0;</pre> | Version number patch 0.0.1
gc_version | <pre>gc_version constant varchar2(30) := gc_version_major || '.' || gc_version_minor || '.' || gc_version_patch;</pre> | String represenation of MAJOR.MINOR.PATCH: Note documented version is just an example.
gc_vals_cat_mime_type | <pre>gc_vals_cat_mime_type constant oos_util_values.cat%type := 'mime-type';</pre> | 






 
## ASSERT Procedure<a name="assert"></a>


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
 
 


### Example
```plsql

oos_util.assert(1=2, 'this assertion did not pass');

-- Results in

Error starting at line : 1 in command -
exec oos_util.assert(1=2, 'this assertion did not pass')
Error report -
ORA-06550: line 1, column 7:
PLS-00306: wrong number or types of arguments in call to 'ASSERT'
ORA-06550: line 1, column 7:
PL/SQL: Statement ignored
06550. 00000 -  "line %s, column %s:\n%s"
*Cause:    Usually a PL/SQL compilation error.
*Action:
```



 
## SLEEP Procedure<a name="sleep"></a>


<p>
<p>Sleep procedure for n seconds</p><p>Notes:</p><ul>
<li>It is recommended that you use Oracle&#39;s lock procedures: <a href="http://psoug.org/reference/sleep.html">http://psoug.org/reference/sleep.html</a><ul>
<li>In instances where you do not have access use this sleep method instead</li>
</ul>
</li>
<li>This implementation may tie up CPU so only use for development purposes</li>
<li>This is a custom implementation of sleep and as a result the times are not 100% accurate</li>
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
 
 


### Example
```plsql
begin
  dbms_output.put_line(oos_util_string.to_char(sysdate));
  oos_util.sleep(5);
  dbms_output.put_line(oos_util_string.to_char(sysdate));
end;
/

26-APR-2016 14:29:02
26-APR-2016 14:29:07
```



 
## ASSOC_ARR2NESTED_TABLE Function<a name="assoc_arr2nested_table"></a>


<p>
<p><strong>TODO</strong>: This will probably be renamed in final 1.1.0 release</p><p>Converts an Associated Array to Nested Table<br />See <a href="https://oracle-base.com/articles/8i/collections-8i">https://oracle-base.com/articles/8i/collections-8i</a> for different array types and how to leverage Nested Tables for things like Multiset and Member functions.</p>
</p>

### Syntax
```plsql
function assoc_arr2nested_table(
  p_assoc_arr in oos_util.tab_vc2_arr)
  return oos_util.tab_vc2
```

### Parameters
Name | Description
--- | ---
`p_assoc_arr` | Associated Array(vc2) to be converted to Nested Table
*return* | Nested Table (vc2)
 
 


### Example
```plsql
declare
  -- Associative Arrays
  l_arr1 oos_util.tab_vc2_arr;
  l_arr2 oos_util.tab_vc2_arr;

  -- Nested Tables
  l_nt1 oos_util.tab_vc2;
  l_nt2 oos_util.tab_vc2;
  l_result oos_util.tab_vc2;
begin
  l_arr1(1) := 'abc';
  l_arr1(2) := 'def';
  l_arr2(1) := 'ghi';

  l_nt1 := oos_util.assoc_arr2nested_table(l_arr1);
  l_nt2 := oos_util.assoc_arr2nested_table(l_arr2);

  dbms_output.put_line('*Multiset Union*');
  l_result := l_nt1 multiset union l_nt2;
  for i in 1..l_result.count loop
    dbms_output.put_line(l_result(i));
  end loop;
  dbms_output.put_line('');

  dbms_output.put_line('*Subset*');
  dbms_output.put_line(oos_util_string.to_char(l_nt1 submultiset of l_nt2));
  dbms_output.put_line('');

  dbms_output.put_line('*Member Of*');
  dbms_output.put_line(oos_util_string.to_char('def' member of l_nt1));

end;
/

*Multiset Union*
abc
def
ghi

*Subset*
FALSE

*Member Of*
TRUE

PL/SQL procedure successfully completed.
```



 
## ASSOC_ARR2NESTED_TABLE-1 Function<a name="assoc_arr2nested_table-1"></a>


<p>
<p>See previous function for details and examples.<br />This is an overloaded function for number table</p>
</p>

### Syntax
```plsql
function assoc_arr2nested_table(
  p_assoc_arr in oos_util.tab_num_arr)
  return oos_util.tab_num
```

### Parameters
Name | Description
--- | ---
`p_assoc_arr` | p_assoc_arr Associated Array(num) to be converted to Nested Table
*return* | Nested Table (num)
 
 





 
