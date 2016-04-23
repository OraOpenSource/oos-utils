# OOS_UTIL_BIT

- [BITAND Function](#bitand)
- [BITOR Function](#bitor)
- [BITXOR Function](#bitxor)
- [BITNOT Function](#bitnot)








 
## BITAND Function<a name="bitand"></a>


<p>
<p><a href="https://en.wikipedia.org/wiki/Bitwise_operation#AND">bitwise AND</a></p><p>The function signature is similar to <a href="https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612"><code>bitand</code></a></p><p>The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an<br />argument is out of this range, the result is undefined.</p>
</p>

### Syntax
```plsql
function bitand(
  p_x in binary_integer,
  p_y in binary_integer)
  return binary_integer
```

### Parameters
Name | Description
--- | ---
`p_x` | binary_integer
`p_y` | binary_integer
*return* | binary_integer
 
 


### Example
```plsql

select oos_util_bit.bitand(1,3)
from dual;

OOS_UTIL_BIT.BITAND(1,3)
------------------------
                      1
```



 
## BITOR Function<a name="bitor"></a>


<p>
<p><a href="https://en.wikipedia.org/wiki/Bitwise_operation#OR">bitwise OR</a></p><p>Copied from <a href="http://www.orafaq.com/wiki/Bit">http://www.orafaq.com/wiki/Bit</a></p><p>The function signature is similar to <a href="https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612"><code>bitand</code></a></p><p>The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an<br />argument is out of this range, the result is undefined.</p>
</p>

### Syntax
```plsql
function bitor(
  p_x in binary_integer,
  p_y in binary_integer)
  return binary_integer
```

### Parameters
Name | Description
--- | ---
`p_x` | binary_integer
`p_y` | binary_integer
*return* | binary_integer
 
 


### Example
```plsql

select oos_util_bit.bitor(1,3)
from dual;

OOS_UTIL_BIT.BITOR(1,3)
-----------------------
                      3
```



 
## BITXOR Function<a name="bitxor"></a>


<p>
<p><a href="https://en.wikipedia.org/wiki/Bitwise_operation#XOR">bitwise XOR</a></p><p>Copied from <a href="http://www.orafaq.com/wiki/Bit">http://www.orafaq.com/wiki/Bit</a></p><p>The function signature is similar to <a href="https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612"><code>bitand</code></a></p><p>The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an<br />argument is out of this range, the result is undefined.</p>
</p>

### Syntax
```plsql
function bitxor(
  p_x in binary_integer,
  p_y in binary_integer)
  return binary_integer
```

### Parameters
Name | Description
--- | ---
`p_x` | binary_integer
`p_y` | binary_integer
*return* | binary_integer
 
 


### Example
```plsql

select oos_util_bit.bitxor(1,3)
from dual;

OOS_UTIL_BIT.BITXOR(1,3)
------------------------
                       2
```



 
## BITNOT Function<a name="bitnot"></a>


<p>
<p><a href="https://en.wikipedia.org/wiki/Bitwise_operation#NOT">bitwise NOT</a></p><p>Copied from <a href="http://www.orafaq.com/wiki/Bit">http://www.orafaq.com/wiki/Bit</a></p><p>The function signature is similar to <a href="https://docs.oracle.com/cd/E11882_01/server.112/e41084/functions021.htm#SQLRF00612"><code>bitand</code></a></p><p>The arguments must be in the range -(2^(32-1)) .. ((2^(32-1))-1). If an<br />argument is out of this range, the result is undefined.</p>
</p>

### Syntax
```plsql
function bitnot(
  p_x in binary_integer)
  return binary_integer
```

### Parameters
Name | Description
--- | ---
`p_x` | binary_integer
*return* | binary_integer
 
 


### Example
```plsql

select oos_util_bit.bitnot(7)
from dual;

OOS_UTIL_BIT.BITNOT(7)
----------------------
                    -8
```



 
