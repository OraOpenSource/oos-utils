# OOS_UTIL_TOTP


- [Constants](#constants)



- [GENERATE_SECRET Function](#generate_secret)
- [FORMAT_KEY_URI Function](#format_key_uri)
- [GENERATE_OTP Function](#generate_otp)
- [VALIDATE_OTP Function](#validate_otp)





## Constants<a name="constants"></a>

Name | Code | Description
--- | --- | ---
gc_base32 | <pre>gc_base32 constant varchar2(32) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';</pre> | 
gc_step | <pre>gc_step constant number := 30;</pre> | 






 
## GENERATE_SECRET Function<a name="generate_secret"></a>


<p>
<p>Generates a sixteen-character alphanumeric, Base32-encoded [1] string.</p><p>[1] - <a href="https://en.wikipedia.org/wiki/Base32">https://en.wikipedia.org/wiki/Base32</a></p>
</p>

### Syntax
```plsql
function generate_secret (p_length number default 16) return varchar2
```

### Parameters
Name | Description
--- | ---
`p_length` | number
*return* | sixteen-character alphanumeric string
 
 


### Example
```plsql
select generate_secret
from dual;
```


### Properties
Name | Description
--- | ---
Author | 
Created | 


 
## FORMAT_KEY_URI Function<a name="format_key_uri"></a>


<p>
<p>Returns a URI that can be used to create a QR Code for setting up a entry<br />in Google Authenticator by scanning [1]. After obtaining the URI, create<br />a QR Code to make it easier to create an entry in Google Authenticator.</p><p>[1] - <a href="https://github.com/google/google-authenticator/wiki/Key-Uri-Format">https://github.com/google/google-authenticator/wiki/Key-Uri-Format</a></p>
</p>

### Syntax
```plsql
function format_key_uri(
  p_type number default null
  , p_label_accountname varchar2
  , p_label_issuer varchar2
  , p_secret varchar2
  , p_issuer varchar2 default null
  , p_algorithm varchar2 default null
  , p_digits number default null
  , p_counter number default null
  , p_period number default null
) return varchar2
```

### Parameters
Name | Description
--- | ---
`p_type` | number (currently not supported)
`p_label_accountname` | varchar2
`p_label_issuer` | varchar2
`p_secret` | varchar2
`p_issuer` | varchar2
`p_algorithm` | varchar2 (currently not supported)
`p_digits` | number (currently not supported)
`p_counter` | number (currently not supported)
`p_period` | number (currently not supported)
*return* | URI string
 
 


### Example
```plsql
select
  oos_util_totp.format_key_uri(
    p_label_accountname => 'adrian.png@wonderland.com'
    , p_label_issuer => 'Superworld'
    , p_secret => 'JBSWY3DPEHPK3PXP'
    , p_issuer => 'Superworld'
  )
from dual;
```


### Properties
Name | Description
--- | ---
Author | 
Created | 


 
## GENERATE_OTP Function<a name="generate_otp"></a>


<p>
<p>Generates a six-digit number</p>
</p>

### Syntax
```plsql
function generate_otp(p_secret varchar2, p_offset number default 0) return varchar2
```

### Parameters
Name | Description
--- | ---
`p_secret` | varchar2
`p_offset` | number
*return* | six-digit number as a string
 
 


### Example
```plsql
select generate_otp(p_secret => 'JBSWY3DPEHPK3PXP')
from dual;

select generate_otp(p_secret => 'JBSWY3DPEHPK3PXP', p_offset => -30)
from dual;
```


### Properties
Name | Description
--- | ---
Author | 
Created | 


 
## VALIDATE_OTP Function<a name="validate_otp"></a>


<p>
<p>Validate an OTP. The skew parameter allows for a customizable degree of<br />tolerance for clocks that are not in sync.</p>
</p>

### Syntax
```plsql
function validate_otp(
  p_secret varchar2
  , p_otp number
  , p_skew number default 30
) return number
```

### Parameters
Name | Description
--- | ---
`p_secret` | varchar2
`p_otp` | number
`p_skew` | number
*return* | number
 
 


### Example
```plsql
begin
  if oos_util_totp.validate_otp(
    p_secret => 'JBSWY3DPEHPK3PXP'
    , p_otp => 123456
    , p_skew => 30
  ) = 1 then
    dbms_output.put_line('Valid');
  else
    dbms_output.put_line('Failed');
  end if;
end;
```


### Properties
Name | Description
--- | ---
Author | 
Created | 


 
