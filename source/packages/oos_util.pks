create or replace package oos_util
as

  -- TODO mdsouza: Think about better way to do this so can do coniditional comp
  gc_version constant varchar2(10) := '1.0.0';


  function tochar(
    p_val in number)
    return varchar2;

  function tochar(
    p_val in date)
    return varchar2;

  function tochar(
    p_val in timestamp)
    return varchar2;

  function tochar(
    p_val in timestamp with time zone)
    return varchar2;

  function tochar(
    p_val in timestamp with local time zone)
    return varchar2;

  function tochar(
    p_val in boolean)
    return varchar2;

  function is_number(p_str in varchar2)
    return boolean;

end oos_util;
/
