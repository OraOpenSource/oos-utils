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

  function is_date(
    p_str in varchar2,
    p_date_format in varchar2)
    return boolean;

  procedure assert(
    p_condition in boolean,
    p_msg in varchar2);

  function truncate_string(
    p_str in varchar2,
    p_length in pls_integer,
    p_by_word in varchar2 default 'N')
    return varchar2;

end oos_util;
/
