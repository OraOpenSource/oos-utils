# OOS_UTIL_VALIDATION

- [IS_NUMBER Function](#is_number)
- [IS_DATE Function](#is_date)








 
## IS_NUMBER Function<a name="is_number"></a>


<p>
<p>Checks if string is numeric</p>
</p>

### Syntax
```plsql
function is_number(p_str in varchar2)
  return boolean
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



 
