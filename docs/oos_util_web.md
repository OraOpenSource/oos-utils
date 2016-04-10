# OOS_UTIL_WEB

- [Constants](#constants)
- [GET_MIME_TYPE Function](#get_mime_type)
- [DOWNLOAD_FILE Procedure](#download_file)
- [DOWNLOAD_FILE Procedure](#download_file)


## Constants<a name="constants"></a>

Name | Code | Description
--- | --- | ---
gc_content_disposition_inline | `gc_content_disposition_inline constant varchar2(20) := 'inline';` | For downloading file and viewing inline
gc_content_disposition_attach | `gc_content_disposition_attach constant varchar2(20) := 'attachment';` | For downloading file as attachment





 
## GET_MIME_TYPE Function<a name="get_mime_type"></a>


<p>
<p>Returns the mime-type for a filename</p>
</p>

### Syntax
```plsql
function get_mime_type(
  p_filename in varchar2)
  return oos_util_values.value%type
```

### Parameters
Name | Description
--- | ---
`p_filename` | Filename
*return* | mime-type
 
 





 
## DOWNLOAD_FILE Procedure<a name="download_file"></a>


<p>
<p>Download file</p>
</p>

### Syntax
```plsql
procedure download_file(
  p_filename in varchar2,
  p_mime_type in varchar2 default null,
  p_content_disposition in varchar2 default oos_util_web.gc_content_disposition_attach,
  p_cache_control in varchar2 default null,
  p_blob in blob
  )
```

### Parameters
Name | Description
--- | ---
`p_filename` | Filename
`p_mime_type` | mime-type of file. If null will be resolved via p_filename
`p_content_disposition` | inline or attachment
`p_cache_control` | options to pass to the Cache-Control attribute. Examples include max-age=3600, no-cache, etc. See <a href="https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching?hl=en">https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching?hl=en</a> for examples
`p_blob` | File to be downloaded
 
 


### Example
```plsql
 ```plsql
   select todo from dual
   where 1=1
   from dual
 ```
```



 
## DOWNLOAD_FILE Procedure<a name="download_file"></a>


<p>
<p>Download clob file</p><p>Notes:</p><ul>
<li>See download_file (blob) for full documentation</li>
</ul>

</p>

### Syntax
```plsql
procedure download_file(
  p_filename in varchar2,
  p_mime_type in varchar2 default null,
  p_content_disposition in varchar2 default oos_util_web.gc_content_disposition_attach,
  p_cache_control in varchar2 default null,
  p_clob in clob)
```

### Parameters
Name | Description
--- | ---
`p_filename` | 
`p_mime_type` | 
`p_content_disposition` | 
`p_cache_control` | See download_file (blob) for documentation
`p_clob` | 
 
 





 
