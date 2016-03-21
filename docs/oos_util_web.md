# OOS_UTIL_WEB

- [GET_MIME_TYPE Function](#get_mime_type)
- [DOWNLOAD_FILE Procedure](#download_file)
- [DOWNLOAD_FILE Procedure](#download_file)








 
## <a name="get_mime_type"></a>GET_MIME_TYPE Function


<p>
<p>Returns the mime-type for a filename</p><p>Notes:<br /> -</p><p>Related Tickets:</p><ul>
<li>#27</li>
</ul>

</p>
Author: Martin Giffy D&#x27;Souza

### Syntax
```plsql
function get_mime_type(
  p_filename in varchar2)
  return oos_util_values.value%type
```

 


### Parameters
Name | Description
--- | ---
p_filename | Filename
*return* | mime-type
 
 





 
## <a name="download_file"></a>DOWNLOAD_FILE Procedure


<p>
<p>Download file</p><p>Notes:<br /> -</p><p>Related Tickets:</p><ul>
<li>#2</li>
<li>#47: cache support</li>
</ul>

</p>
Author: Martin Giffy D&#x27;Souza

### Syntax
```plsql
procedure download_file(
  p_filename in varchar2,
  p_mime_type in varchar2 default null,
  p_content_disposition in varchar2 default oos_util_apex.gc_content_disposition_attach,
  p_cache_control in varchar2 default null,
  p_blob in blob
  )
```

 


### Parameters
Name | Description
--- | ---
p_filename | Filename
p_mime_type | mime-type of file. If null will be resolved via p_filename
p_content_disposition | inline or attachment
p_cache_control | options to pass to the Cache-Control attribute. Examples include max-age=3600, no-cache, etc. See <a href="https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching?hl=en">https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching?hl=en</a> for examples
p_blob | File to be downloaded
 
 


### Example
```plsql
 ```plsql
   select todo from dual
   where 1=1
   from dual
 ```
```



 
## <a name="download_file"></a>DOWNLOAD_FILE Procedure


<p>
<p>Download clob file</p><p>Notes:</p><ul>
<li>See download_file (blob) for full documentation</li>
</ul>
<p>Related Tickets:</p><ul>
<li>#2</li>
</ul>

</p>
Author: Martin Giffy D&#x27;Souza

### Syntax
```plsql
procedure download_file(
  p_filename in varchar2,
  p_mime_type in varchar2 default null,
  p_content_disposition in varchar2 default oos_util_apex.gc_content_disposition_attach,
  p_cache_control in varchar2 default null,
  p_clob in clob)
```

 


### Parameters
Name | Description
--- | ---
p_filename | 
p_mime_type | 
p_content_disposition | 
p_cache_control | See download_file (blob) for documentation
p_clob | 
 
 





 
