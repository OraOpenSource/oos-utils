# OOS_UTIL_STRING

- [Data Types](#types)
- [Constants](#constants)
- [TO_CHAR Function](#to_char)
- [TO_CHAR Function](#to_char)
- [TO_CHAR Function](#to_char)
- [TO_CHAR Function](#to_char)
- [TO_CHAR Function](#to_char)
- [TO_CHAR Function](#to_char)
- [TRUNCATE Function](#truncate)
- [SPRINTF Function](#sprintf)
- [STRING_TO_TABLE Function](#string_to_table)
- [STRING_TO_TABLE Function](#string_to_table)
- [LISTUNAGG Function](#listunagg)
- [LISTUNAGG Function](#listunagg)
- [REVERSE Function](#reverse)


## Constants<a name="constants"></a>

Name | Code | Description
--- | --- | ---
gc_default_delimiter | `gc_default_delimiter constant varchar2(1) := ',';` | Default delimiter for delimited strings


## Types<a name="types"></a>

Name | Code | Description
--- | --- | ---
tab_vc2 | <pre>type tab_vc2 is table of varchar2(32767);</pre> | VC2 Nested table
tab_vc2_arr | <pre>type tab_vc2_arr is table of varchar2(32767) index by pls_integer;</pre> | VC2 associated array


 
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



 
## TO_CHAR Function<a name="to_char"></a>


<p>
<p>See first <code>to_char</code></p>
</p>

### Syntax
```plsql
function to_char(
  p_val in date)
  return varchar2
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



 
## TO_CHAR Function<a name="to_char"></a>


<p>
<p>See first <code>to_char</code></p>
</p>

### Syntax
```plsql
function to_char(
  p_val in timestamp)
  return varchar2
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



 
## TO_CHAR Function<a name="to_char"></a>


<p>
<p>See first <code>to_char</code></p>
</p>

### Syntax
```plsql
function to_char(
  p_val in timestamp with time zone)
  return varchar2
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



 
## TO_CHAR Function<a name="to_char"></a>


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



 
## TO_CHAR Function<a name="to_char"></a>


<p>
<p>See first <code>to_char</code></p>
</p>

### Syntax
```plsql
function to_char(
  p_val in boolean)
  return varchar2
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
 
 


### Example
```plsql
declare
  l_str clob := 'abc,def,ghi';
  l_arr oos_util_string.tab_vc2_arr;
begin
  l_arr := oos_util_string.string_to_table(p_string => l_str);

  for i in 1..l_arr.count loop
    dbms_output.put_line('i: ' || i || ' ' || l_arr(i));
  end loop;
end;
/

i: 1 abc
i: 2 def
i: 3 ghi
```



 
## STRING_TO_TABLE Function<a name="string_to_table"></a>


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



 
## LISTUNAGG Function<a name="listunagg"></a>


<p>
<p>Converts delimited string to queriable table</p>
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
  p_string in varchar2)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_string` | String
*return* | String
 
 


### Example
```plsql
begin
  dbms_output.put_line(oos_util_string.reverse('OraOpenSource'));
end;
/

ecruoSnepOarO
```



 
