create or replace package oos_util_date
as
  function date2epoch(
    p_date timestamp,
    p_date_in_tzr in varchar2 default sessiontimezone)
    return number;

  function epoch2date(
    p_epoch in number,
    p_date_out_tzr in varchar2 default sessiontimezone)
    return timestamp with time zone;

end oos_util_date;
/
