create or replace package oos_util_date
as

  function date2epoch(
    p_date in date)
    return number;

  function epoch2date(
    p_epoch in number)
    return date;

  function timestamp2epoch(
    p_timestamp in timestamp)
    return pls_integer;

end oos_util_date;
/
