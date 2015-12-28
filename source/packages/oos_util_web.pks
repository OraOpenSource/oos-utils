create or replace package oos_util_web
as

  function get_mime_type(
    p_filename in varchar2)
    return oos_util_vals.value%type;
    
end oos_util_web;
/
