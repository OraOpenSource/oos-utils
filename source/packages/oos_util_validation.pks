create or replace package oos_util_validation
as

  function is_number(p_str in varchar2)
    return boolean
    deterministic;

  function is_date(
    p_str in varchar2,
    p_date_format in varchar2)
    return boolean
    deterministic;

  function is_equal(
    p_vala in varchar2,
    p_valb in varchar2)
    return boolean;
  
  function is_equal(
    p_vala in number,
    p_valb in number)
    return boolean;
  
  function is_equal(
    p_vala in date,
    p_valb in date)
    return boolean;

  function is_equal(
    p_vala in timestamp,
    p_valb in timestamp)
    return boolean;

  function is_equal(
    p_vala in timestamp with time zone,
    p_valb in timestamp with time zone)
    return boolean;

  function is_equal(
    p_vala in timestamp with local time zone,
    p_valb in timestamp with local time zone)
    return boolean;

  function is_equal(
    p_vala in boolean,
    p_valb in boolean)
    return boolean;

end oos_util_validation;
/
