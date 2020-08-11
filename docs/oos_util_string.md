# OOS_UTIL_STRING



- [Constants](#constants)



 
- [TO_CHAR Function](#to_char)
 
- [TO_CHAR-1 Function](#to_char-1)
 
- [TO_CHAR-2 Function](#to_char-2)
 
- [TO_CHAR-3 Function](#to_char-3)
 
- [TO_CHAR-4 Function](#to_char-4)
 
- [TO_CHAR-5 Function](#to_char-5)
 
- [TRUNCATE Function](#truncate)
 
- [SPRINTF Function](#sprintf)
 
- [STRING_TO_TABLE Function](#string_to_table)
 
- [STRING_TO_TABLE-1 Function](#string_to_table-1)
 
- [LISTUNAGG Function](#listunagg)
 
- [LISTUNAGG-1 Function](#listunagg-1)
 
- [REVERSE Function](#reverse)
 
- [ORDINAL Function](#ordinal)
 
- [MULTI_REPLACE Function](#multi_replace)
 
- [CONVERT_EOL Function](#convert_eol)





## Constants<a name="constants"></a>

Name | Code | Description
--- | --- | ---
gc_default_delimiter | <pre>gc_default_delimiter constant varchar2(1) := ',';</pre> | Default delimiter for delimited strings
gc_cr | <pre>gc_cr constant varchar2(1) := chr(13);</pre> | Carriage Return
gc_lf | <pre>gc_lf constant varchar2(1) := chr(10);</pre> | Line Feed
gc_crlf | <pre>gc_crlf constant varchar2(2) := gc_cr || gc_lf;</pre> | Use for new lines.
gc_eol_unix | <pre>gc_eol_unix constant varchar2(1) := gc_lf;</pre> | EOL for Unix
gc_eol_windows | <pre>gc_eol_windows constant varchar2(2) := gc_cr || gc_lf;</pre> | EOL for Windows






 
## TO_CHAR Function<a name="to_char"></a>


<p>
<p>Converts parameter to varchar2</p><p>Notes:</p><ul>
<li>Code copied from Logger: <a href="https://github.com/OraOpenSource/Logger">https://github.com/OraOpenSource/Logger</a></li>
</ul>

</p>

### Syntax
```plsql
function to_char(
  p_val in number)
  return varchar2
  deterministic
```

### Parameters
Name | Description
--- | ---
`p_val` | Number
*return* | string value for p_val
 
 


### Example
```plsql

select oos_util_string.to_char(123)
from dual;

OOS_UTIL_STRING.TO_CHAR(123)---
123
```



 
## TO_CHAR-1 Function<a name="to_char-1"></a>


<p>
<p>See first <code>to_char</code></p>
</p>

### Syntax
```plsql
function to_char(
  p_val in date)
  return varchar2
  deterministic
```

### Parameters
Name | Description
--- | ---
`p_val` | Date
*return* | string value for p_val
 
 


### Example
```plsql
select oos_util_string.to_char(sysdate)
from dual;

OOS_UTIL_STRING.TO_CHAR(SYSDATE)---
26-APR-2016 13:57:51
```



 
## TO_CHAR-2 Function<a name="to_char-2"></a>


<p>
<p>See first <code>to_char</code></p>
</p>

### Syntax
```plsql
function to_char(
  p_val in timestamp)
  return varchar2
  deterministic
```

### Parameters
Name | Description
--- | ---
`p_val` | Timestamp
*return* | string value for p_val
 
 


### Example
```plsql
select oos_util_string.to_char(systimestamp)
from dual;

OOS_UTIL_STRING.TO_CHAR(SYSTIMESTAMP)---
26-APR-2016 13:58:24:851908000 -06:00
```



 
## TO_CHAR-3 Function<a name="to_char-3"></a>


<p>
<p>See first <code>to_char</code></p>
</p>

### Syntax
```plsql
function to_char(
  p_val in timestamp with time zone)
  return varchar2
  deterministic
```

### Parameters
Name | Description
--- | ---
`p_val` | Timestamp with TZ
*return* | string value for p_val
 
 


### Example
```plsql
TODO
```



 
## TO_CHAR-4 Function<a name="to_char-4"></a>


<p>
<p>See first <code>to_char</code></p>
</p>

### Syntax
```plsql
function to_char(
  p_val in timestamp with local time zone)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_val` | Timestamp with local TZ
*return* | string value for p_val
 
 


### Example
```plsql
TODO
```



 
## TO_CHAR-5 Function<a name="to_char-5"></a>


<p>
<p>See first <code>to_char</code></p>
</p>

### Syntax
```plsql
function to_char(
  p_val in boolean)
  return varchar2
  deterministic
```

### Parameters
Name | Description
--- | ---
`p_val` | Boolean
*return* | string value for p_val
 
 


### Example
```plsql
begin
  dbms_output.put_line(oos_util_string.to_char(true));
  dbms_output.put_line(oos_util_string.to_char(false));
end;
/

TRUE
FALSE
```



 
## TRUNCATE Function<a name="truncate"></a>


<p>
<p>Truncates a string to ensure that it is not longer than <code>p_length</code><br />If length of <code>p_str</code> is greater than <code>p_length</code> then an ellipsis (<code>...</code>) will be appended to string</p><p>Supports following modes:</p><ul>
<li>By length (default): Will perform a hard parse at <code>p_length</code></li>
<li>By word: Will truncate at logical word break</li>
</ul>

</p>

### Syntax
```plsql
function truncate(
  p_str in varchar2,
  p_length in pls_integer,
  p_by_word in varchar2 default 'N',
  p_ellipsis in varchar2 default '...')
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
 
 


### Example
```plsql
select
  oos_util_string.truncate(
    p_str => comments,
    p_length => 20,
    p_by_word => 'N'
  ) by_word_n,
  oos_util_string.truncate(
    p_str => comments,
    p_length => 20,
    p_by_word => 'Y'
  ) by_word_y
from apex_dictionary
where 1=1
  and rownum <= 5
;

BY_WORD_N            BY_WORD_Y
-------------------- --------------------
List of APEX buil... List of APEX...
Identifies the th... Identifies the...
Identifies the na... Identifies the...
Identifies the th... Identifies the...
Identifies a work... Identifies a...
```



 
## SPRINTF Function<a name="sprintf"></a>


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



 
## STRING_TO_TABLE Function<a name="string_to_table"></a>


<p>
<p>Converts delimited string to array</p><p>Notes:</p><ul>
<li>Similar to <code>apex_util.string_to_table</code> but handles clobs</li>
</ul>

</p>

### Syntax
```plsql
function string_to_table(
  p_str in clob,
  p_delim in varchar2 default gc_default_delimiter)
  return oos_util.tab_vc2_arr
```

### Parameters
Name | Description
--- | ---
`p_str` | String containing delimited text
`p_delim` | Delimiter
*return* | Array of string
 
 


### Example
```plsql
declare
  l_str clob := 'abc,def,ghi';
  l_arr oos_util.tab_vc2_arr;
begin
  l_arr := oos_util_string.string_to_table(p_str => l_str);

  for i in 1..l_arr.count loop
    dbms_output.put_line('i: ' || i || ' ' || l_arr(i));
  end loop;
end;
/

i: 1 abc
i: 2 def
i: 3 ghi
```



 
## STRING_TO_TABLE-1 Function<a name="string_to_table-1"></a>


<p>
<p>See <code>string_to_table (p_str clob)</code> for notes</p>
</p>

### Syntax
```plsql
function string_to_table(
  p_str in varchar2,
  p_delim in varchar2 default gc_default_delimiter)
  return oos_util.tab_vc2_arr
```

### Parameters
Name | Description
--- | ---
`p_str` | String containing delimited text
`p_delim` | Delimiter
*return* | Array of string
 
 


### Example
```plsql
-- See previous example
```



 
## LISTUNAGG Function<a name="listunagg"></a>


<p>
<p>Converts delimited string to queriable table</p><p>Notes:</p><ul>
<li>Text between delimiters must be <code>&lt;= 4000</code> characters</li>
</ul>

</p>

### Syntax
```plsql
function listunagg(
  p_str in varchar2,
  p_delim in varchar2 default gc_default_delimiter)
  return oos_util.tab_vc2 pipelined
```

### Parameters
Name | Description
--- | ---
`p_str` | String containing delimited text
`p_delim` | Delimiter
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



 
## LISTUNAGG-1 Function<a name="listunagg-1"></a>


<p>
<p>Converts delimited string to queriable table</p>
</p>

### Syntax
```plsql
function listunagg(
  p_str in clob,
  p_delim in varchar2 default gc_default_delimiter)
  return oos_util.tab_vc2 pipelined
```

### Parameters
Name | Description
--- | ---
`p_str` | String (clob) containing delimited text
`p_delim` | Delimiter
*return* | pipelined table
 
 


### Example
```plsql
See previous example
```



 
## REVERSE Function<a name="reverse"></a>


<p>
<p>Returns the input string in its reverse order</p>
</p>

### Syntax
```plsql
function reverse(
  p_str in varchar2)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_str` | String
*return* | String
 
 


### Example
```plsql
begin
  dbms_output.put_line(oos_util_string.reverse('OraOpenSource'));
end;
/

ecruoSnepOarO
```



 
## ORDINAL Function<a name="ordinal"></a>


<p>
<p>Returns the input number with the ordinal attached, in english.<br />e.g. 1st, 2nd, 3rd, 4th, etc</p><p>Notes:</p><ul>
<li>Logic taken from: <a href="http://stackoverflow.com/a/13627586/3476713">http://stackoverflow.com/a/13627586/3476713</a></li>
</ul>

</p>

### Syntax
```plsql
function ordinal(
  p_num in number)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_num` | Number
*return* | String
 
 


### Example
```plsql
select oos_util_string.ordinal(level)
from dual
connect by level <= 10;
```



 
## MULTI_REPLACE Function<a name="multi_replace"></a>


<p>
<p>Allow for multi-word replace via strings</p>
</p>

### Syntax
```plsql
function multi_replace(
  p_str in varchar2,
  p_replace_str in varchar2,
  p_delim in varchar2 default ',')
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_str` | String
`p_replace_str` | String should be in the format (find1,replace1,find2,replace2,...) If an odd number of strings are passed the last one is ignored ano no replacement is defined for it.
`p_delim` | Delimiter default &quot;,&quot;
*return* | String
 
 


### Example
```plsql
select oos_util_string.multi_replace(
  'Hello {name} your number is {num}',
  '{name},Martin,{num},6') demo
from dual;

DEMO
------------------------------
Hello Martin your number is 6
```



 
## CONVERT_EOL Function<a name="convert_eol"></a>


<p>
<p>EOL conversion (clob)</p><p>Changes EOL to desired format (regardless of current state)</p>
</p>

### Syntax
```plsql
function convert_eol(
  p_str in clob,
  p_eol in varchar2)
return clob
```

### Parameters
Name | Description
--- | ---
`p_str` | clob
`p_eol` | Use <code>oos_util_string.gc_eol_unix</code> or <code>oos_util_string.gc_eol_windows</code>
*return* | clob with converted EOL
 
 


### Example
```plsql

-- See above
```



 
