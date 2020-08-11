# OOS_UTIL_VALIDATION






 
- [IS_NUMBER Function](#is_number)
 
- [IS_DATE Function](#is_date)
 
- [IS_EQUAL Function](#is_equal)
 
- [IS_EQUAL-1 Function](#is_equal-1)
 
- [IS_EQUAL-2 Function](#is_equal-2)
 
- [IS_EQUAL-3 Function](#is_equal-3)
 
- [IS_EQUAL-4 Function](#is_equal-4)
 
- [IS_EQUAL-5 Function](#is_equal-5)
 
- [IS_EQUAL-6 Function](#is_equal-6)












 
## IS_NUMBER Function<a name="is_number"></a>


<p>
<p>Checks if string is numeric</p>
</p>

### Syntax
```plsql
function is_number(p_str in varchar2)
  return boolean
  deterministic
```

### Parameters
Name | Description
--- | ---
`p_str` | String to validate
*return* | True of p_str is number
 
 


### Example
```plsql
begin
  dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_number('123')));
  dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_number('abc')));
end;
/

TRUE
FALSE
```



 
## IS_DATE Function<a name="is_date"></a>


<p>
<p>Checks if string is a valid date</p>
</p>

### Syntax
```plsql
function is_date(
  p_str in varchar2,
  p_date_format in varchar2)
  return boolean
  deterministic
```

### Parameters
Name | Description
--- | ---
`p_str` | 
`p_date_format` | 
*return* | True if date is valid
 
 


### Example
```plsql
begin
  dbms_output.put_line(oos_util_string.to_char(
    oos_util_validation.is_date('01-JAN-2015', 'DD-MON-YYYY')));
  dbms_output.put_line(oos_util_string.to_char(
    oos_util_validation.is_date('not-a-date', 'DD-MON-YYYY')));
end;
/

TRUE
FALSE
```



 
## IS_EQUAL Function<a name="is_equal"></a>


<p>
<p>Checks if two values are equal.<br />Overloaded to handle all types</p><p>Truth Table</p><table>
<thead>
<tr>
<th>A</th>
<th>B</th>
<th>Result</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>null</code></td>
<td><code>null</code></td>
<td><code>true</code></td>
</tr>
<tr>
<td><code>1</code></td>
<td><code>null</code></td>
<td><code>false</code></td>
</tr>
<tr>
<td><code>null</code></td>
<td><code>1</code></td>
<td><code>false</code></td>
</tr>
<tr>
<td><code>1</code></td>
<td><code>2</code></td>
<td><code>false</code></td>
</tr>
<tr>
<td><code>1</code></td>
<td><code>1</code></td>
<td><code>true</code></td>
</tr>
</tbody>
</table>

</p>

### Syntax
```plsql
function is_equal(
  p_vala in varchar2,
  p_valb in varchar2)
  return boolean
```

### Parameters
Name | Description
--- | ---
`p_vala` | 
`p_valb` | 
*return* | boolean Returns true if both the same or both null
 
 


### Example
```plsql

set serveroutput on;

declare
  l_x number;
  l_y number;
begin
  dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_equal(1,1)));
  dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_equal(null,1)));
  -- Note: can't pass in null, null as it will error out for too many overloaded functions
  dbms_output.put_line(oos_util_string.to_char(oos_util_validation.is_equal(l_x,l_y)));
end;
/

TRUE
FALSE
TRUE
```



 
## IS_EQUAL-1 Function<a name="is_equal-1"></a>


<p>
<p>See first <code>is_equal</code></p>
</p>

### Syntax
```plsql
function is_equal(
  p_vala in number,
  p_valb in number)
  return boolean
```

### Parameters
Name | Description
--- | ---
`p_vala` | 
`p_valb` | 
*return* | boolean Returns true if both the same or both null
 
 





 
## IS_EQUAL-2 Function<a name="is_equal-2"></a>


<p>
<p>See first <code>is_equal</code></p>
</p>

### Syntax
```plsql
function is_equal(
  p_vala in date,
  p_valb in date)
  return boolean
```

### Parameters
Name | Description
--- | ---
`p_vala` | 
`p_valb` | 
*return* | boolean Returns true if both the same or both null
 
 





 
## IS_EQUAL-3 Function<a name="is_equal-3"></a>


<p>
<p>See first <code>is_equal</code></p>
</p>

### Syntax
```plsql
function is_equal(
  p_vala in timestamp,
  p_valb in timestamp)
  return boolean
```

### Parameters
Name | Description
--- | ---
`p_vala` | 
`p_valb` | 
*return* | boolean Returns true if both the same or both null
 
 





 
## IS_EQUAL-4 Function<a name="is_equal-4"></a>


<p>
<p>See first <code>is_equal</code></p>
</p>

### Syntax
```plsql
function is_equal(
  p_vala in timestamp with time zone,
  p_valb in timestamp with time zone)
  return boolean
```

### Parameters
Name | Description
--- | ---
`p_vala` | 
`p_valb` | 
*return* | boolean Returns true if both the same or both null
 
 





 
## IS_EQUAL-5 Function<a name="is_equal-5"></a>


<p>
<p>See first <code>is_equal</code></p>
</p>

### Syntax
```plsql
function is_equal(
  p_vala in timestamp with local time zone,
  p_valb in timestamp with local time zone)
  return boolean
```

### Parameters
Name | Description
--- | ---
`p_vala` | 
`p_valb` | 
*return* | boolean Returns true if both the same or both null
 
 





 
## IS_EQUAL-6 Function<a name="is_equal-6"></a>


<p>
<p>See first <code>is_equal</code></p>
</p>

### Syntax
```plsql
function is_equal(
  p_vala in boolean,
  p_valb in boolean)
  return boolean
```

### Parameters
Name | Description
--- | ---
`p_vala` | 
`p_valb` | 
*return* | boolean Returns true if both the same or both null
 
 





 
