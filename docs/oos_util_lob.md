# OOS_UTIL_LOB

- [CLOB2BLOB Function](#clob2blob)
- [BLOB2CLOB Function](#blob2clob)
- [GET_FILE_SIZE Function](#get_file_size)
- [GET_LOB_SIZE Function](#get_lob_size)
- [GET_LOB_SIZE Function](#get_lob_size)
- [REPLACE_CLOB Function](#replace_clob)








 
## <a name="clob2blob"></a>CLOB2BLOB Function


<p>
<p>Convers clob to blob</p><p>Notes:<br /> -</p><p>Related Tickets:</p><ul>
<li>#12</li>
</ul>

</p>
Author: Moritz Klein (https://github.com/commi235)

### Syntax
```plsql
function clob2blob(
  p_clob in clob)
  return blob
```

 


### Parameters
Name | Description
--- | ---
p_clob | Clob to conver to blob
*return* | blob
 
 





 
## <a name="blob2clob"></a>BLOB2CLOB Function


<p>
<p>Converts blob to clob</p><p>Notes:</p><ul>
<li>Copied from <a href="http://stackoverflow.com/questions/12849025/convert-blob-to-clob">http://stackoverflow.com/questions/12849025/convert-blob-to-clob</a></li>
</ul>
<p>Related Tickets:</p><ul>
<li>#1</li>
</ul>

</p>
Author: Martin D&#x27;Souza

### Syntax
```plsql
function blob2clob(
  p_blob in blob)
  return clob
```

 


### Parameters
Name | Description
--- | ---
p_blob | blob to be converted to clob
*return* | clob
 
 





 
## <a name="get_file_size"></a>GET_FILE_SIZE Function


<p>
<p>Returns human readable file size</p><p>Notes:<br /> -</p><p>Related Tickets:</p><ul>
<li>#6</li>
</ul>

</p>
Author: Martin D&#x27;Souza

### Syntax
```plsql
function get_file_size(
  p_file_size in number,
  p_units in varchar2 default null)
  return varchar2
```

 


### Parameters
Name | Description
--- | ---
p_file_size | size of file in bytes
p_units | See gc<em>size</em>... variables for options. If not provided, most significant one automatically chosen.
*return* | Human readable file size
 
 





 
## <a name="get_lob_size"></a>GET_LOB_SIZE Function


<p>
<p>See get_file_size</p><p>Notes:<br /> -</p><p>Related Tickets:<br /> -</p>
</p>
Author: Martin D&#x27;Souza

### Syntax
```plsql
function get_lob_size(
  p_lob in clob,
  p_units in varchar2 default null)
  return varchar2
```

 


### Parameters
Name | Description
--- | ---
p_lob | 
p_units | 
 
 





 
## <a name="get_lob_size"></a>GET_LOB_SIZE Function


<p>
<p>See get_file_size</p><p>Notes:<br /> -</p><p>Related Tickets:<br /> -</p>
</p>
Author: Martin D&#x27;Souza

### Syntax
```plsql
function get_lob_size(
  p_lob in blob,
  p_units in varchar2 default null)
  return varchar2
```

 


### Parameters
Name | Description
--- | ---
p_lob | 
p_units | 
 
 





 
## <a name="replace_clob"></a>REPLACE_CLOB Function


<p>
<p>Replaces p_search with p_replace</p><p>Oracle&#39;s replace function does handle clobs but runs into 32k issues</p><p>Notes:</p><ul>
<li>Source: <a href="http://dbaora.com/ora-22828-input-pattern-or-replacement-parameters-exceed-32k-size-limit/">http://dbaora.com/ora-22828-input-pattern-or-replacement-parameters-exceed-32k-size-limit/</a></li>
</ul>
<p>Related Tickets:</p><ul>
<li>#29</li>
</ul>

</p>
Author: Martin Giffy D&#x27;Souza

### Syntax
```plsql
function replace_clob(
  p_str in clob,
  p_search in varchar2,
  p_replace in clob)
  return clob
```

 


### Parameters
Name | Description
--- | ---
p_str | 
p_search | 
p_replace | 
*return* | Replaced string
 
 





 
