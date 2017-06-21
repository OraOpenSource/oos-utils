create or replace package body oos_util_date
as
  /*!
   * For epoch dates use http://www.epochconverter.com/ to test
   */


  /**
   * Coverts date to Unix Epoch time
   *
   * @example
   *
   * select oos_util_date.date2epoch(sysdate)
   * from dual;
   *
   * OOS_UTIL_DATE.DATE2EPOCH(SYSDATE)
   * ---------------------------------
   *                        1461663997
   *
   * @issue #18
   *
   * @author Martin Giffy D'Souza
   * @created 30-Dec-2015
   * @param p_date Date to convert to Epoch format
   * @return Unix Epoch time
   */
  function date2epoch(
    p_date timestamp,
    p_date_in_tzr in varchar2 default sessiontimezone)
    return number
  as
    $if dbms_db_version.version >= 12 $then
      pragma udf;
    $end

    l_tswtz timestamp with time zone;
    l_start timestamp with time zone := to_timestamp_tz('19700101 utc', 'yyyymmdd tzr');
  begin
    l_tswtz := from_tz(p_date, p_date_in_tzr) at time zone 'utc';
    
    return round((extract (day from l_tswtz - l_start) * 86400000)
      + (extract (hour from l_tswtz - l_start) * 3600000)
      + (extract (minute from l_tswtz - l_start) * 60000)
      + (extract (second from l_tswtz - l_start) * 1000));
  end date2epoch;


  /**
   * Converts Unix linux time to Oracle date
   *
   * @issue 18
   *
   * @example
   *
   * select oos_util_date.epoch2date(1461663982)
   * from dual;
   *
   * OOS_UTIL_DATE.EPOCH2DATE(1461663982)
   * ------------------------------------
   * 26-APR-2016 12:46:22
   *
   * @author Martin Giffy D'Souza
   * @created 31-Dec-2015
   * @param p_epoch Epoch Unix date (number)
   * @return date
   */
  function epoch2date(
    p_epoch in number,
    p_date_out_tzr in varchar2 default sessiontimezone)
    return timestamp with time zone
  as
    l_tswtz timestamp with time zone;
  begin
    l_tswtz := to_timestamp_tz('19700101 utc', 'yyyymmdd tzr') + numtodsinterval(p_epoch/86400000, 'day');
    return l_tswtz at time zone (p_date_out_tzr);
  end epoch2date;


end oos_util_date;
/
