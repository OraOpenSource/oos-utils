# OOS_UTIL_STRING

- [TOCHAR Function](#tochar)
- [TOCHAR Function](#tochar)
- [TOCHAR Function](#tochar)
- [TOCHAR Function](#tochar)
- [TOCHAR Function](#tochar)
- [TOCHAR Function](#tochar)
- [TRUNCATE_STRING Function](#truncate_string)
- [SPRINTF Function](#sprintf)
- [STRING_TO_TABLE Function](#string_to_table)
- [STRING_TO_TABLE Function](#string_to_table)
- [LISTUNAGG Function](#listunagg)
- [LISTUNAGG Function](#listunagg)








 
## <a name="tochar"></a>TOCHAR Function


<p>
<p>Converts parameter to varchar2</p><p>Notes:</p><ul>
<li>Need to call this tochar instead of to_char since there will be a conflict when calling it</li>
<li>Code copied from Logger: <a href="https://github.com/OraOpenSource/Logger">https://github.com/OraOpenSource/Logger</a></li>
</ul>

</p>

### Syntax
```plsql
function tochar(
  p_val in number)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_value` | 
*return* | varchar2 value for p_value
 
 





 
## <a name="tochar"></a>TOCHAR Function


<p>
<p>See first <code>tochar</code></p>
</p>

### Syntax
```plsql
function tochar(
  p_val in date)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_val` | Date
 
 





 
## <a name="tochar"></a>TOCHAR Function


<p>
<p>See first <code>tochar</code></p>
</p>

### Syntax
```plsql
function tochar(
  p_val in timestamp)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_val` | Timestamp
 
 





 
## <a name="tochar"></a>TOCHAR Function


<p>
<p>See first <code>tochar</code></p>
</p>

### Syntax
```plsql
function tochar(
  p_val in timestamp with time zone)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_val` | Timestamp with TZ
 
 





 
## <a name="tochar"></a>TOCHAR Function


<p>
<p>See first <code>tochar</code></p>
</p>

### Syntax
```plsql
function tochar(
  p_val in timestamp with local time zone)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_val` | Timestamp with local TZ
 
 





 
## <a name="tochar"></a>TOCHAR Function


<p>
<p>See first <code>tochar</code></p>
</p>

### Syntax
```plsql
function tochar(
  p_val in boolean)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_val` | Boolean
 
 





 
## <a name="truncate_string"></a>TRUNCATE_STRING Function


<p>
<p>Truncates a string to ensure that it is not longer than <code>p_length</code><br />If string is &gt; than <code>p_length</code> then an ellipsis (...) will be appended to string</p><p>Supports following modes:</p><ul>
<li>By length (default): Will perform a hard parse at <code>p_length</code></li>
<li>By word: Will truncate at logical word break</li>
</ul>

</p>

### Syntax
```plsql
function truncate_string(
  p_str in varchar2,
  p_length in pls_integer,
  p_by_word in varchar2 default &#x27;N&#x27;,
  p_ellipsis in varchar2 default &#x27;...&#x27;)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_str` | String to truncate
`p_length` | Max length of final string
`p_by_word` | Y/N. If Y then will truncate to last word possible
`p_ellipsis` | ellipsis &quot;...&quot; default
*return* | Trimmed string
 
 





 
## <a name="sprintf"></a>SPRINTF Function


<p>
<p>Does string replacement similar to C&#39;s sprintf</p><p>Notes:</p><ul>
<li>Uses the following replacement algorithm (in following order)<ul>
<li>Replaces <code>%s&lt;n&gt;</code> with <code>p_s&lt;n&gt;</code></li>
<li>Occurrences of <code>%s</code> (no number) are replaced with <code>p_s1..p_s10</code> in order that they appear in text</li>
<li><code>%%</code> is escaped to <code>%</code></li>
</ul>
</li>
</ul>

</p>

### Syntax
```plsql
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
```

### Parameters
Name | Description
--- | ---
`p_str` | Messsage to format using %s and %d replacement strings
`p_s1..10` | Replacement strings
*return* | p_msg with strings replaced
 
 


### Example
```plsql
select oos_util_string.sprintf('hello %s', 'martin') demo
from dual;

DEMO
------------------------------
hello martin

select oos_util_string.sprintf('%s2, %s1', 'Firstname', 'Lastname') demo
from dual;

DEMO
------------------------------
Lastname, Firstname
```



 
## <a name="string_to_table"></a>STRING_TO_TABLE Function


<p>
<p>Converts delimited string to array</p><p>Notes:</p><ul>
<li>Similar to <code>apex_util.string_to_table</code> but handles clobs</li>
</ul>

</p>

### Syntax
```plsql
function string_to_table(
  p_string in clob,
  p_delimiter in varchar2 default gc_default_delimiter)
  return tab_vc2_arr
```

### Parameters
Name | Description
--- | ---
`p_string` | String containing delimited text
`p_delimiter` | Delimiter
*return* | Array of string
 
 





 
## <a name="string_to_table"></a>STRING_TO_TABLE Function


<p>
<p>See <code>string_to_table (p_string clob)</code> for notes</p>
</p>

### Syntax
```plsql
function string_to_table(
  p_string in varchar2,
  p_delimiter in varchar2 default gc_default_delimiter)
  return tab_vc2_arr
```

### Parameters
Name | Description
--- | ---
`p_string` | String containing delimited text
`p_delimiter` | Delimiter
*return* | Array of string
 
 





 
## <a name="listunagg"></a>LISTUNAGG Function


<p>
<p>Converts delimited string to queriable table</p><p>Notes:</p><ul>
<li>Text between delimiters must be <code>&lt;= 4000</code> characters</li>
</ul>

</p>

### Syntax
```plsql
function listunagg(
  p_string in varchar2,
  p_delimiter in varchar2 default gc_default_delimiter)
  return tab_vc2 pipelined
```

### Parameters
Name | Description
--- | ---
`p_string` | String containing delimited text
`p_delimiter` | Delimiter
*return* | pipelined table
 
 


### Example
```plsql
 select rownum, column_value
 from table(oos_util_string.listunagg('abc,def'));

     ROWNUM COLUMN_VAL
---------- ----------
         1 abc
         2 def
```



 
## <a name="listunagg"></a>LISTUNAGG Function


<p>
<p>Converts delimited string to queriable table</p><p>See above for example</p>
</p>

### Syntax
```plsql
function listunagg(
  p_string in clob,
  p_delimiter in varchar2 default gc_default_delimiter)
  return tab_vc2 pipelined
```

### Parameters
Name | Description
--- | ---
`p_string` | String (clob) containing delimited text
`p_delimiter` | Delimiter
*return* | pipelined table
 
 





 
