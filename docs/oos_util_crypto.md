# OOS_UTIL_CRYPTO


- [Constants](#constants)



- [HASH Function](#hash)
- [HASH_STR Function](#hash_str)
- [MAC Function](#mac)
- [MAC_STR Function](#mac_str)





## Constants<a name="constants"></a>

Name | Code | Description
--- | --- | ---
gc_hash_md4 | <pre>gc_hash_md4 constant pls_integer := 1;</pre> | 
gc_hash_md5 | <pre>gc_hash_md5 constant pls_integer := 2;</pre> | 
gc_hash_sh1 | <pre>gc_hash_sh1 constant pls_integer := 3;</pre> | 
gc_hash_sh224 | <pre>gc_hash_sh224 constant pls_integer := 11;</pre> | 
gc_hash_sh256 | <pre>gc_hash_sh256 constant pls_integer := 4;</pre> | 
gc_hash_sh384 | <pre>gc_hash_sh384 constant pls_integer := 5;</pre> | 
gc_hash_sh512 | <pre>gc_hash_sh512 constant pls_integer := 6;</pre> | 
gc_hash_ripemd160 | <pre>gc_hash_ripemd160 constant pls_integer := 15;</pre> | 
gc_hmac_md4 | <pre>gc_hmac_md4 constant pls_integer := 0;</pre> | 
gc_hmac_md5 | <pre>gc_hmac_md5 constant pls_integer := 1;</pre> | 
gc_hmac_sh1 | <pre>gc_hmac_sh1 constant pls_integer := 2;</pre> | 
gc_hmac_sh224 | <pre>gc_hmac_sh224 constant pls_integer := 10;</pre> | 
gc_hmac_sh256 | <pre>gc_hmac_sh256 constant pls_integer := 3;</pre> | 
gc_hmac_sh384 | <pre>gc_hmac_sh384 constant pls_integer := 4;</pre> | 
gc_hmac_sh512 | <pre>gc_hmac_sh512 constant pls_integer := 5;</pre> | 
gc_hmac_ripemd160 | <pre>gc_hmac_ripemd160 constant pls_integer := 14;</pre> | 
gc_encrypt_des | <pre>gc_encrypt_des constant pls_integer := 1;</pre> | 






 
## HASH Function<a name="hash"></a>


<p>
<p>Generates hash with raw values<br />See <code>oos_util_crypto.hash_str</code> to handle wrapping</p>
</p>

### Syntax
```plsql
function hash(
  p_src raw,
  p_typ pls_integer)
return raw
```

### Parameters
Name | Description
--- | ---
`p_src` | 
`p_typ` | see <code>oos_util_crypto.gc_hash*</code> variables
 
 


### Example
```plsql
select
  rawtohex(
    oos_util_crypto.hash(
      p_src => sys.utl_raw.cast_to_raw('hello'),
      p_typ => 4 -- oos_util_crypto.gc_hash_sh256
    )
  ) example
from dual
;

EXAMPLE
2CF24DBA5FB0A30E26E83B2AC5B9E29E1B161E5C1FA7425E73043362938B9824
```


### Properties
Name | Description
--- | ---
Author | Aton Scheffer
Created | 4-Oct-2016


 
## HASH_STR Function<a name="hash_str"></a>


<p>
<p>Generates hash</p>
</p>

### Syntax
```plsql
function hash_str(
  p_src varchar2,
  p_typ pls_integer)
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_src` | 
`p_typ` | see <code>oos_util_crypto.gc_hash*</code> variables
*return* | Hex hashed value as a string
 
 


### Example
```plsql
select
  oos_util_crypto.hash_str(
    p_src => 'hello',
    p_typ => 4 -- oos_util_crypto.gc_hash_md5
  ) example
from dual
;

EXAMPLE
2CF24DBA5FB0A30E26E83B2AC5B9E29E1B161E5C1FA7425E73043362938B9824
```


### Properties
Name | Description
--- | ---
Author | Martin D'Souza
Created | 19-Jun-2017


 
## MAC Function<a name="mac"></a>


<p>
<p>Generates mac<br />Note: see mac_str for string inputs</p>
</p>

### Syntax
```plsql
function mac(
  p_src raw,
  p_typ pls_integer,
  p_key raw )
return raw
```

### Parameters
Name | Description
--- | ---
`p_src` | 
`p_typ` | see <code>oos_util_crypto.gc_hmac*</code> variables
`p_key` | secret key
 
 


### Example
```plsql
select
  rawtohex(
    oos_util_crypto.mac(
      p_src => utl_raw.cast_to_raw('hello'),
      p_typ => 3, -- oos_util_crypto.gc_hmac_sh256
      p_key => utl_raw.cast_to_raw('abc')
    )
  ) example
from dual
;

EXAMPLE
F3166A3A404599D2046ED2AAE479B37D54B51D2E85259C9E314042753BE7D813
```


### Properties
Name | Description
--- | ---
Author | Aton Scheffer
Created | 4-Oct-2016


 
## MAC_STR Function<a name="mac_str"></a>


<p>
<p>Generates mac with string input / output</p>
</p>

### Syntax
```plsql
function mac_str(
  p_src varchar2,
  p_typ pls_integer,
  p_key varchar2 )
  return varchar2
```

### Parameters
Name | Description
--- | ---
`p_src` | 
`p_typ` | see <code>oos_util_crypto.gc_hmac*</code> variables
`p_key` | secret key
*return* | mac hex value as varchar2
 
 


### Example
```plsql
select
  oos_util_crypto.mac_str(
    p_src => 'hello'',
    p_typ => 3, -- oos_util_crypto.gc_hmac_sh256
    p_key => 'abc'
  ) example
from dual
;

EXAMPLE
F3166A3A404599D2046ED2AAE479B37D54B51D2E85259C9E314042753BE7D813
```


### Properties
Name | Description
--- | ---
Author | Martin D'Souza
Created | 19-Jun-2017


 
