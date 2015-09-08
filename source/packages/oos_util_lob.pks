create or replace package oos_util_lob
as

  function clob2blob(
    p_clob in clob)
    return blob;

  function blob2clob(
    p_blob in blob)
    return clob;
end oos_util_lob;
/
