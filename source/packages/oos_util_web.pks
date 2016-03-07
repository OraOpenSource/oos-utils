create or replace package oos_util_web
as

  function get_mime_type(
    p_filename in varchar2)
    return oos_util_values.value%type;

  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_apex.gc_content_disposition_attach,
    p_cache_control in varchar2 default null,
    p_blob in blob);

  procedure download_file(
    p_filename in varchar2,
    p_mime_type in varchar2 default null,
    p_content_disposition in varchar2 default oos_util_apex.gc_content_disposition_attach,
    p_cache_control in varchar2 default null,
    p_clob in clob);


end oos_util_web;
/
