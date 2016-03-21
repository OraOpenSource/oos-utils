# OOS_UTIL_STRING

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
<p>Related Tickets:</p><ul>
<li>#11</li>
</ul>

</p>
Author: Martin D&#x27;Souza

### Syntax
```plsql
function tochar(
  p_val in number)
  return varchar2
```

 


### Parameters
Name | Description
--- | ---
p_value | 
*return* | varchar2 value for p_value
 
 





 
## <a name="truncate_string"></a>TRUNCATE_STRING Function


<p>
<p>Truncates a string to ensure that it is not longer than p_length<br />If string is &gt; than p_length then an ellipsis (...) will be appended to string</p><p>Supports following modes:</p><ul>
<li>By length (default): Will perform a hard parse at p_length</li>
<li>By word: Will truncate at logical word break</li>
</ul>
<p>Notes:<br /> -</p><p>Related Tickets:</p><ul>
<li>#5</li>
</ul>

</p>
Author: Martin D&#x27;Souza

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
p_str | String to truncate
p_length | Max length of final string
p_by_word | Y/N. If Y then will truncate to last word possible
p_ellipsis | ellipsis &quot;...&quot; default
*return* | Trimmed string
 
 





 
## <a name="sprintf"></a>SPRINTF Function


<p>
<p>Does string replacement similar to C&#39;s sprintf</p><p>Notes:</p><ul>
<li>Uses the following replacement algorithm (in following order)<ul>
<li>Replaces %s<n> with p_s<n></li>
<li>Occurrences of %s (no number) are replaced with p_s1..p_s10 in order that they appear in text</li>
<li>%% is escaped to %</li>
</ul>
</li>
<li>As this function could be useful for non-logging purposes will not apply a NO_OP to it for conditional compilation</li>
</ul>
<p>Related Tickets:</p><ul>
<li>#8</li>
</ul>

</p>
Author: Martin D&#x27;Souza

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
p_str | Messsage to format using %s and %d replacement strings
p_s1 | 
p_s2 | 
p_s3 | 
p_s4 | 
p_s5 | 
p_s6 | 
p_s7 | 
p_s8 | 
p_s9 | 
p_s10 | 
*return* | p_msg with strings replaced
 
 





 
## <a name="string_to_table"></a>STRING_TO_TABLE Function


<p>
<p>Converts delimited string to array</p><p>Notes:</p><ul>
<li>Similar to apex_util.string_to_table but handles clobs</li>
</ul>
<p>Related Tickets:</p><ul>
<li>#32</li>
</ul>

</p>
Author: Martin Giffy D&#x27;Souza

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
p_string | String containing delimited text
p_delimiter | Delimiter
*return* | Array of string
 
 





 
## <a name="string_to_table"></a>STRING_TO_TABLE Function


<p>
<p>See string_to_table (p_string clob) for notes</p><p>Notes:</p><p>Related Tickets:</p><ul>
<li>#32</li>
</ul>

</p>
Author: Martin Giffy D&#x27;Souza

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
p_string | String containing delimited text
p_delimiter | Delimiter
*return* | Array of string
 
 





 
## <a name="listunagg"></a>LISTUNAGG Function


<p>
<p>Converts delimited string to queriable table</p><p>Notes:</p><ul>
<li>Text between delimiters must be &lt;= 4000 characters</li>
</ul>
<p>Example:<br /> select rownum, column_value<br /> from table(oos_util_string.listunagg(&#39;abc,def&#39;));</p><p>Related Tickets:</p><ul>
<li>#4</li>
</ul>

</p>
Author: Martin Giffy D&#x27;Souza

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
p_string | String containing delimited text
p_delimiter | Delimiter
*return* | pipelined table
 
 





 
## <a name="listunagg"></a>LISTUNAGG Function


<p>
<p>Converts delimited string to queriable table</p><p>Notes:</p><ul>
<li>Text between delimiters must be &lt;= 4000 characters</li>
</ul>
<p>Example:<br /> select rownum, column_value<br /> from table(oos_util_string.listunagg(&#39;abc,def&#39;));</p><p>Related Tickets:</p><ul>
<li>#4</li>
</ul>

</p>
Author: Martin Giffy D&#x27;Souza

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
p_string | String (clob) containing delimited text
p_delimiter | Delimiter
*return* | pipelined table
 
 





 
